{-# LANGUAGE MultiParamTypeClasses #-}
module SUTD.Compiler.Parser where

import SUTD.Compiler.ParserEnv
import SUTD.Compiler.Parsec
import SUTD.Compiler.Lexer hiding (LEnv(..))
import SUTD.Compiler.RegExp 

{-
 regex external syntax
 R ::= [C-C] || [CC] || [] || C || R|R || R* || R? || RR || (R) 
 C ::= a || ... || z || 1 || ... || 0

 left recursion elimination

 step 1. remove left recursion in R 
 R ::= R|R || R* || R? || RR || (R) || [C-C] || [CC] || [] || C 
 alpha1 == |R 
 alpha2 == * 
 alpha3 == ? 
 alpha4 == R 
 beta1 == (R)
 beta2 == [C-C] 
 beta3 == [CC] 
 beta4 == [] 
 thus we have 
 R ::= (R)S || [C-C]S || [CC]S || []S || CS 
 S ::= |RS || *S || ?S || RS || eps 
 C ::= a || ... || z ||  1 || ... || 0

 step 2. left factorization

 R ::= (R)S || CS || [T 
 T :: = CU || ]S 
 U ::= -C]S || C]S
 S ::= |RS || *S || ?S || RS || eps 
 C ::= a || ... || z || 1 || ... || 0 
-}



data PEnv = PEnv { toks:: [LToken]} deriving (Show, Eq)

instance ParserEnv PEnv LToken where
    getCol penv           = case getTokens penv of
        [] -> -1
        (t:_) -> case srcLoc t of
            SrcLoc _ c -> c
    getLine penv          = case getTokens penv of
        [] -> -1
        (t:_) -> case srcLoc t of
            SrcLoc l _ -> l
    setTokens ts penv     = penv{toks= ts}
    setLine _ penv        = penv -- ^ not in used.
    setCol _ penv         = penv -- ^ not in used. 
    isNextTokNewLine penv = case getTokens penv of
        (WhiteSpace _ '\n':_) -> True
        _ -> False
    getTokens             = toks


data R = ParenR R S
    | Chara Char S
    | CClassCommon T
    deriving (Show, Eq)


data T = CClass Char U
    | EClass S
    deriving (Show, Eq)


data U = CClassRange Char S
    | CClassChoice [Char] S
    deriving (Show, Eq)


data S = BarS R S
    | StarS S
    | QuestionS S
    | RS R S
    | NIL
    deriving (Show, Eq)

pR :: Parser PEnv R
pR = choice pParenR (choice pChara pCClassCommon)

-- R 
pParenR :: Parser PEnv R
pParenR = do
    _ <- pLParen
    r <- pR
    _ <- pRParen
    s <- pS
    return (ParenR r s)

pChara :: Parser PEnv R
pChara = do
    c <- pAlphaNum
    s <- pS
    return (Chara c s)

pCClassCommon :: Parser PEnv R
pCClassCommon = do
    _ <- pLBracket
    t <- pT
    return (CClassCommon t)

-- T 
pT :: Parser PEnv T
pT = choice pCClass pEClass

pCClass :: Parser PEnv T
pCClass = do
    a1 <- pAlphaNum
    u  <- pU
    return (CClass a1 u)

pEClass :: Parser PEnv T
pEClass = do
    _ <- pRBracket
    s <- pS
    return (EClass s)

pU :: Parser PEnv U
pU = choice pCClassRange pCClassChoice

pCClassRange :: Parser PEnv U
pCClassRange = do
    _  <- pHyphen
    a2 <- pAlphaNum
    _  <- pRBracket
    s  <- pS
    return (CClassRange a2 s)

-- Task 4 TODO 
pCClassChoice :: Parser PEnv U
pCClassChoice = undefined -- fixme


-- S 
-- Task 4 TODO 
pS :: Parser PEnv S
pS = undefined -- fixme 

pNIL :: Parser PEnv S
pNIL = empty NIL

-- lower level parser which parser a Lexer Token and return the lexer Token or character


pLParen :: Parser PEnv LToken
pLParen = sat (\t -> case t of
    LParen _ -> True
    _        -> False) "parser failed: expecting a (."

pRParen :: Parser PEnv LToken
pRParen = sat (\t -> case t of
    RParen _ -> True
    _        -> False) "parser failed: expecting a )."


pLBracket :: Parser PEnv LToken
pLBracket = sat (\t -> case t of
    LBracket _ -> True
    _          -> False) "parser failed: expecting a {."

pRBracket :: Parser PEnv LToken
pRBracket = sat (\t -> case t of
    RBracket _ -> True
    _          -> False) "parser failed: expecting a }."

pHyphen :: Parser PEnv LToken
pHyphen = sat (\t -> case t of
    Hyphen _ -> True
    _        -> False) "parser failed: expecting a -."


pAlphaNum :: Parser PEnv Char
pAlphaNum = do
    t <- sat (\t -> case t of
        AlphaNum _ _ -> True
        _            -> False) "parser failed: expecting an alpha numeric character."
    justOrFail t (\lt -> case lt of
        AlphaNum _ ch -> Just ch
        _             -> Nothing) "pAlphaNum failed with a token parsed but the token is not alpha numeric."

pVertBar :: Parser PEnv LToken
pVertBar = sat (\t -> case t of
    VertBar _ -> True
    _         -> False) "parser failed: expecting a |."


pAsterix :: Parser PEnv LToken
pAsterix = sat (\t -> case t of
    Asterix _ -> True
    _         -> False) "parser failed: expecting an *."

pQuestion :: Parser PEnv LToken
pQuestion = sat (\t -> case t of
    Question _ -> True
    _          -> False) "parser failed: expecting a ?."

pSkipWhiteSpaces :: Parser PEnv [LToken]
pSkipWhiteSpaces = everythingUntil (\t -> case t of
    WhiteSpace _ _ -> False
    _              -> True )


-- converting R to RE 

rtoRE :: R -> RE
rtoRE (ParenR r s) = 
    let re   = rtoRE r 
        cont = stoCont s 
    in cont re 
rtoRE (Chara c s) = 
    let re   = Letter c 
        cont = stoCont s 
    in cont re 
rtoRE (CClassCommon (CClass cb u)) = 
    let cont = utoCont u
    in cont cb
rtoRE (CClassCommon (EClass s)) = 
    let re   = Epsilon 
        cont = stoCont s
    in cont re 

utoCont :: U -> Char -> RE 
utoCont (CClassRange ce s) cb = 
    let cs = [cb .. ce]
        re = case cs of
            []   -> Epsilon 
            x:xs -> mkChoice (map Letter cs)
        cont = stoCont s 
    in cont re
utoCont (CClassChoice cs s) cb = 
    let re = mkChoice (map Letter (cb:cs))
        cont = stoCont s 
    in cont re

stoCont :: S -> RE -> RE 
stoCont (BarS r s) = 
    let rre  = rtoRE r 
        cont = stoCont s
    in \lre -> cont (Choice lre rre)
stoCont (StarS s) = 
    let cont = stoCont s 
    in \re -> cont (Star re) 
stoCont (QuestionS s) = 
    let cont = stoCont s 
    in \re -> cont (Choice re Epsilon)
stoCont (RS r s) = 
    let re2  = rtoRE r 
        cont = stoCont s
    in \re1 -> cont (Seq re1 re2)
stoCont NIL = id 

parseRegex :: [LToken] -> Either String RE 
parseRegex ts = case run pR (PEnv ts) of 
    Consumed (Ok (r, _))  -> Right (rtoRE r) 
    Consumed (Failed msg) -> Left msg
    Empty (Ok (_, _))     -> Left "parser consumed nothing."
    Empty (Failed msg)    -> Left msg