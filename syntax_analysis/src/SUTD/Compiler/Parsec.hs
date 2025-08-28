{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE FlexibleInstances #-}

module SUTD.Compiler.Parsec where


import Data.Functor
import Control.Applicative hiding (many)
import Control.Monad
import Control.Monad.Except
import Prelude hiding (getLine)
import Debug.Trace (trace)
import SUTD.Compiler.ParserEnv  

data Progress a = Consumed a
    | Empty a
    deriving (Show,Eq)

type Error = String

data Result a = Ok a
    | Failed String
    deriving (Show,Eq)


newtype Parser env a =
    Parser { run :: env -> Progress (Result (a, env)) }

instance Functor (Parser env) where
    fmap f (Parser ea) = Parser ( \env -> case ea env of
    { Empty (Failed err) -> Empty (Failed err)
    ; Empty (Ok (a, env1)) -> Empty (Ok (f a, env1))
    ; Consumed (Failed err) -> Consumed (Failed err)
    ; Consumed (Ok (a, env1)) -> Consumed (Ok (f a, env1))
    })



instance Applicative (Parser env) where
    pure a = Parser (\env -> Empty (Ok (a, env)))
    (Parser eab) <*> (Parser ea) = Parser (\env -> case eab env of
        { Consumed v ->
            let cont = case v of
                { Failed msg -> Failed msg
                ; Ok (f, env1) -> case ea env1 of
                    { Consumed (Failed msg) -> Failed msg
                    ; Consumed (Ok (a, env2)) -> Ok (f a, env2)
                    ; Empty (Failed msg) -> Failed msg
                    ; Empty (Ok (a, env2)) -> Ok (f a, env2)
                    }
                }
            in Consumed cont
        ; Empty (Failed msg) -> Empty (Failed msg)
        ; Empty (Ok (f, env1)) -> case ea env1  of
            { Consumed (Failed msg) -> Consumed (Failed msg)
            ; Consumed (Ok (a, env2)) -> Consumed (Ok (f a, env2))
            ; Empty (Failed msg) -> Empty (Failed msg)
            ; Empty (Ok (a, env2)) -> Empty (Ok (f a, env2))
            }
        })


instance Monad (Parser env) where
    (Parser ea) >>= f = Parser (\env -> case ea env of
            { Consumed v ->
                let cont = case v of
                    { Failed msg -> Failed msg
                    ; Ok (a, env1)  -> case f a of
                        { Parser eb -> case eb env1 of
                            { Consumed x -> x
                            ; Empty x    -> x
                            }
                        }
                    }
                in Consumed cont
            ; Empty v -> case v of
                { Failed err   -> Empty (Failed err)
                ; Ok (a, env1) -> case f a of
                    { Parser eb -> eb env1 }
                }
            })

instance MonadError Error (Parser env) where
    throwError msg = Parser (\env -> Empty (Failed msg))
    catchError (Parser ea) handle = Parser (\env -> case ea env of
        { Consumed v -> Consumed v -- we don't backtrack when something is already consumed.
        ; Empty (Failed msg) -> case handle msg of
            { Parser ea2 -> ea2 env
            }
        ; Empty (Ok v) -> -- LL(1) parser will also attempt to look at f if fa does not consume anything 
            case handle "faked error" of
                {  Parser ea2 -> case ea2 env of
                    { Empty _ -> Empty (Ok v) -- if handle also fails, we report the same error.
                    ; consumed -> consumed
                    }
                }
        })


-- some combinators

-- | The `choice` combinator tries p first then if p fails, it tries q. However if something has been consumed by p, no backtracking 
choice :: Parser env a -> Parser env a -> Parser env a
choice p q = catchError p (\e -> q)


-- | The `get` combinator retrieves a property from the environment using the getter `op`. 
get :: (env -> a) -> Parser env a
get op = Parser ( \env -> Empty (Ok (op env, env)))

-- | The `tokens` combinator retrieves the remaining tokens in the environment 
tokens :: ParserEnv env tok => env -> [tok]
tokens = getTokens

-- | The `getTokensM` lifts the `getTokens` to the Parser monad level 
getTokensM :: ParserEnv env tok => Parser env [tok]
getTokensM = get getTokens


-- | The `getLineM` lifts the `getLine` to the Parser monad level 
getLineM :: ParserEnv env tok => Parser env Int
getLineM = get getLine

-- | The `getColM` lifts the `getCol` to the Parser monad level 
getColM :: ParserEnv env tok => Parser env Int
getColM = get getCol

-- | The `set` combinator sets a property in the envrionment using the setter `op`. 
set :: (env -> env) -> Parser env ()
set op = Parser ( \env -> Empty (Ok ((), op env)))

-- | The `log` prints the debugging message `msg`. TODO: we should use a writer monad.
log :: String -> Parser env ()
log msg = Parser (\env -> trace msg `seq` Empty (Ok ((), env)))


-- | The `item` combinator unconditionally parse the leading token. 
item :: ParserEnv env tok => Parser env tok
item = Parser (\env ->
    let toks = getTokens env
        ln   = getLine env
        col  = getCol env
    in case toks of
        { [] -> Empty (Failed "item is called with an empty token stream.")
        ; (c : cs) | isNextTokNewLine env ->
            let env1 = setLine (ln+1) env
                env2 = setCol 1 env1
                env3 = setTokens cs env2
            in Consumed (Ok (c, env3))
                   | otherwise ->
            let env1 = setCol (col+1) env
                env2 = setTokens cs env1
            in Consumed (Ok (c, env2))
        })

-- | The `sat` combinator consume the leading token if it satifies the predicate `p`.
sat :: ParserEnv env tok => (tok -> Bool) -> Error -> Parser env tok
sat p dbgMsg = Parser (\env ->
    let toks = getTokens env
        ln   = getLine env
        col  = getCol env
    in case toks of
        { [] -> Empty (Failed ("sat is called with an empty token stream at line " ++ show ln ++ ", col " ++ show col ++ ". " ++ dbgMsg))
        ; (c:cs) | p c && isNextTokNewLine env ->
            let env1 = setLine (ln+1) env
                env2 = setCol 1 env1
                env3 = setTokens cs env2
            in Consumed (Ok (c, env3))
        ; (c:cs) | p c ->
            let env1 = setCol (col+1) env
                env2 = setTokens cs env1
            in Consumed (Ok (c, env2))
        ; (c:cs) -> Empty (Failed ("sat is called with an unsatisfied predicate at line " ++ show ln ++ ", col " ++ show col ++ ". " ++ dbgMsg))
        }
    )

-- | The `attempt` combinator explicitly tries a parser and backtracks if it fails.
attempt :: Parser env a -> Parser env a
attempt (Parser ea) = Parser (\env -> case ea env of
    { Consumed (Failed err) -> Empty (Failed err) -- undo the consumed effect if it fails. 
    ; other -> other
    })


-- | The `many1` combinator repeatedly applies the parser `p` one or more times. 
many1 :: ParserEnv env tok => Parser env a -> Parser env [a]
many1 p = do
    a <- p
    as <- many p
    return (a:as)

-- | The `many` combinator applies the parser `p` zero or more times.
many :: ParserEnv env tok => Parser env a -> Parser env [a]
many p@(Parser ea) = Parser (\env ->
        case run (manyOp p) env of
            { Empty (Ok (x, env1)) -> Empty (Ok (reverse x, env1))
            ; Empty (Failed err)   -> Empty (Failed err)
            ; Consumed (Ok (x, env1)) -> Consumed (Ok (reverse x, env1))
            ; Consumed (Failed err) -> Consumed (Failed err)
            })

-- | The `manyOp` function is a helper function that try to step through the input tokens by applying p until it can't parse further.
manyOp :: ParserEnv env tok => Parser env a -> Parser env [a]
manyOp p =
    let -- walk :: [a] -> env -> Progress (Result (a, env)) -> Result ([a], env)
        walk acc env (Empty (Failed err)) = Ok (acc, env)
        walk acc env (Empty (Ok v)) =
            let ln  = getLine env
                col = getCol env
            in Failed ("manyOp is applied to yield a possible empty value but nothing is consumed at line " ++ show ln ++ " and col " ++ show col ++ ".")
        walk acc env (Consumed (Failed err)) = Failed err
        walk acc env (Consumed (Ok (x, env1))) =  -- walk continues if the last parse is successfuly
            let acc' = (x : acc)
            in walk acc' env1 (run p env1)
    in Parser (\env ->
        case run p env of
            { Empty (Failed err) -> Empty (Ok ([], env))
            ; Empty (Ok v) ->
                let ln  = getLine env
                    col = getCol env
                in Empty (Failed ("manyOp is applied to yield a possible empty value but nothing is consumed at line " ++ show ln ++ " and col " ++ show col ++ "."))
            ; Consumed x -> Consumed (walk [] env (Consumed x))
            }
        )

-- | The `interleave` combinator interleaves parsing using two two parsers 
interleave :: Parser env a -> Parser env b -> Parser env [a]
interleave pa pb =
    let p1 = do
        { a <- pa
        ; b <- pb
        ; as <- interleave pa pb
        ; return (a:as)
        }
        p2 = do
        { a <- pa
        ; return [a]
        }
    in choice (attempt p1) p2


-- | The `either1` combinator attempts to parse the input using parser pa if not, parser pb, it returns a union type.  
either1 :: Parser env a -> Parser env b -> Parser env (Either a b)
either1 pa pb =
    let p1 = Left <$> pa
        p2 = Right <$> pb
    in choice (attempt p1) p2

-- | The `optional` combinator greedily apply parser pa to the input; if it fails, return a Left ()
optional :: Parser env a -> Parser env (Either () a)
optional pa =
    let p1 = Right <$> pa
        p2 = return (Left ())
    in choice (attempt p1) p2


-- | The `everythingUntil` combinator consumes all the tokens until the condition p is met.
everythingUntil :: ParserEnv env tok => (tok -> Bool) -> Parser env [tok]
everythingUntil p =
    let rest t | p t = return []
               | otherwise = do
        { c <- item
        ; cs <- everythingUntil p
        ; return (c:cs)
        }
    in do
        { t <- lookAhead item
        ; rest t
        }


-- | The `lookAhead` combinator runs a parser to the input without consuming the input
lookAhead :: Parser env a -> Parser env a
lookAhead pa = do
    { env <- get id
    ; a   <- pa
    ; set (const env)
    ; return a
    }

-- | The `justOrFail` combinator applies `f` to `a` to extract `b`, if the result is Nothing, signals a failure
justOrFail :: a -> (a -> Maybe b) -> Error -> Parser env b
justOrFail a f err = Parser ( \env -> case f a of
    { Nothing -> Empty (Failed err)
    ; Just b  -> Empty (Ok (b, env))
    })

-- | The `empty` combinator does not consume anything and return the given value as result. 
empty :: a -> Parser env a
empty = return


-- | The `choices` is a multi-way choice operator
choices :: [Parser env a] -> Parser env a -> Parser env a
choices qs default' = foldr choice default' qs
