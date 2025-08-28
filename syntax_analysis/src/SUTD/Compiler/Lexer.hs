{-# LANGUAGE MultiParamTypeClasses #-}
module SUTD.Compiler.Lexer where

import SUTD.Compiler.ParserEnv
import SUTD.Compiler.Parsec
import Prelude hiding (getLine)
{-
 regex external syntax
 R ::= [C-C] || [CC] || [] || C || R|R || R* || R? || RR || (R) 
 C ::= a || ... || z || 1 || ... || 0
-}

whitespaces = ['\t', '\r', '\n', ' ', '\f']

data LEnv = LEnv {
    toks :: [Char],
    ln :: Int,
    cl :: Int
} deriving (Show, Eq)


instance ParserEnv LEnv Char where
    setTokens ts lenv     = lenv{toks= ts}
    setLine l lenv        = lenv{ln=l}
    setCol c lenv         = lenv{cl=c}
    isNextTokNewLine lenv = case toks lenv of
        ('\n':_) -> True
        _ -> False
    getTokens             = toks
    getCol                = cl
    getLine               = ln


-- | source location: line and column
data SrcLoc = SrcLoc Int Int deriving (Eq, Show)


-- | lexer output tokens 
data LToken = LBracket SrcLoc -- ^ [ 
    | RBracket SrcLoc         -- ^ ] 
    | Hyphen SrcLoc           -- ^ - 
    | VertBar SrcLoc          -- ^ | 
    | Asterix SrcLoc          -- ^ *
    | Question SrcLoc         -- ^ ? 
    | LParen SrcLoc           -- ^ (
    | RParen SrcLoc           -- ^ )
    | AlphaNum SrcLoc Char    -- ^ a,b,c, ..., A, B, C, ... 0, ... 9
    | WhiteSpace SrcLoc Char
    deriving (Eq, Show)

srcLoc :: LToken -> SrcLoc
srcLoc (LBracket src)       = src
srcLoc (RBracket src)       = src
srcLoc (Hyphen src)         = src
srcLoc (VertBar src)        = src
srcLoc (Asterix src)        = src
srcLoc (Question src)       = src
srcLoc (LParen src)         = src
srcLoc (RParen src)         = src
srcLoc (AlphaNum src _)     = src
srcLoc (WhiteSpace src _)   = src


lSymLBrack :: Parser LEnv LToken
lSymLBrack = do
    _ <- sat ( == '[') "lexer failed: expecting a [."
    l <- get getLine
    c <- get getCol
    return (LBracket (SrcLoc l c))


lSymRBrack :: Parser LEnv LToken
lSymRBrack = do
    _ <- sat ( == ']') "lexer failed: expecting a ]."
    l <- get getLine
    c <- get getCol
    return (RBracket (SrcLoc l c))



lSymHyphen :: Parser LEnv LToken
lSymHyphen = do
    _ <- sat ( == '-') "lexer failed: expecting a -."
    l <- get getLine
    c <- get getCol
    return (Hyphen (SrcLoc l c))


lSymVertBar :: Parser LEnv LToken
lSymVertBar = do
    _ <- sat ( == '|') "lexer failed: expecting a |."
    l <- get getLine
    c <- get getCol
    return (VertBar (SrcLoc l c))

lSymAsterix :: Parser LEnv LToken
lSymAsterix = do
    _ <- sat ( == '*') "lexer failed: expecting an *."
    l <- get getLine
    c <- get getCol
    return (Asterix (SrcLoc l c))



lSymQuestion :: Parser LEnv LToken
lSymQuestion = do
    _ <- sat ( == '?') "lexer failed: expecting a ?."
    l <- get getLine
    c <- get getCol
    return (Question (SrcLoc l c))


lSymLParen :: Parser LEnv LToken
lSymLParen = do
    _ <- sat ( == '(') "lexer failed: expecting a (."
    l <- get getLine
    c <- get getCol
    return (LParen (SrcLoc l c))



lSymRParen :: Parser LEnv LToken
lSymRParen = do
    _ <- sat ( == ')') "lexer failed: expecting a )."
    l <- get getLine
    c <- get getCol
    return (RParen (SrcLoc l c))


lSymAlphaNum :: Parser LEnv LToken
lSymAlphaNum = do
    a <- sat ( `elem` (['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'])  ) "lexer failed: expecting an alpha numeric character."
    l <- get getLine
    c <- get getCol
    return (AlphaNum (SrcLoc l c) a)


lSymWhiteSpace :: Parser LEnv LToken
lSymWhiteSpace = do
    a <- sat ( `elem` whitespaces ) "lexer failed: expecting a white space character."
    l <- get getLine
    c <- get getCol
    return (WhiteSpace (SrcLoc l c) a)


lexOne :: Parser LEnv LToken 
lexOne = choices [lSymLBrack, lSymRBrack, lSymHyphen, lSymVertBar, lSymAsterix, lSymQuestion, lSymLParen, lSymRParen, lSymAlphaNum] lSymWhiteSpace

lex :: Parser LEnv [LToken]
lex = many lexOne