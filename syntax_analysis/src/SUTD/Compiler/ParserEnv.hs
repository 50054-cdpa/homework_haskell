{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
module SUTD.Compiler.ParserEnv where 

-- The requirements of a parser environment.



class ParserEnv env tok | env -> tok
    where
        getTokens :: env -> [tok]
        getLine :: env -> Int
        getCol :: env -> Int
        setTokens :: [tok] -> env -> env
        setLine :: Int -> env -> env
        setCol :: Int -> env -> env
        isNextTokNewLine :: env -> Bool

