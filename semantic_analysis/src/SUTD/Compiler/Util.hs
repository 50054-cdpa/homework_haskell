{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE InstanceSigs #-}
module SUTD.Compiler.Util where

import Data.Set 
import Control.Monad.State
import Control.Monad.Except
import SUTD.Compiler.LambdaCalculus


data StateInfo = StateInfo {nextNum::Int} deriving (Show, Eq)

data Result a = Error String
    | Ok a
    deriving (Show, Eq)



instance Functor Result where
    fmap f (Error msg) = Error msg
    fmap f (Ok a) = Ok (f a)


instance Applicative Result where
    pure a = Ok a
    (Error msg) <*> _ = Error msg
    _ <*> (Error msg) = Error msg
    (Ok f) <*> (Ok a) = Ok (f a)

instance Monad Result where
    (Error msg) >>= _ = Error msg
    (Ok a) >>= f = f a

type Err = String


instance MonadError Err Result where
    throwError msg = Error msg
    catchError (Error msg) handler = handler msg
    catchError (Ok a) _ = Ok a

type StateResult s = StateT s Result

newName :: StateResult StateInfo String
newName = do
    stInfo <- get
    _      <- put stInfo{nextNum=(nextNum stInfo) + 1}
    return ("_x_$" ++ show (nextNum stInfo))




type Subst = (Var, Term)


appSubst :: Subst -> Term -> StateResult StateInfo Term
appSubst s (ConstTerm c) = return (ConstTerm c)
appSubst (x, u) (VarTerm y)
    | y == x    = return u
    | otherwise = return (VarTerm y)
appSubst s (AppTerm t1 t2) = do
    t3 <- appSubst s t1
    t4 <- appSubst s t2
    return (AppTerm t3 t4)
appSubst s (IfTerm t1 t2 t3) = do
    t4 <- appSubst s t1
    t5 <- appSubst s t2
    t6 <- appSubst s t3
    return (IfTerm t4 t5 t6)
appSubst (x, u) (LetTerm y t2 t3)
    | (y /= x) && not (y `member` fv u) = do
        t4 <- appSubst (x, u) t2
        t5 <- appSubst (x, u) t3
        return (LetTerm y t4 t5)
    | otherwise = do
        {- Substitution Application would fail because let bound variable is clashing with the substitution domain. 
           or substitution domain is captured in the RHS of let binding. 
           instead of failing, we apply alpha renaming to y and t3 immediately
        -}
        n <- newName
        let z = Var n
            s2 = (y, VarTerm z) -- [z/y]
        t3' <- appSubst s2 t3 -- alpha renaming
        t4  <- appSubst (x, u) t2  -- subst after alpha renaming 
        t5  <- appSubst (x, u) t3' -- subst after alpha renaming 
        return (LetTerm z t4 t5)
appSubst (x, u) (LambdaTerm y  t2)
    | (y /= x) && not (y `member` fv u) = do
        t3 <- appSubst (x, u) t2
        return (LambdaTerm y t3)
    | otherwise = do
        {- Substitution Application would fail because lambda bound variable is clashing with the substitution domain. 
           or substitution domain is captured in the body of lambda abstraction. 
           instead of failing, we apply alpha renaming to y and t2 immediately 
        -}
        n <- newName
        let z = Var n
            s2 = (y, VarTerm z) -- [z/y]
        t2' <- appSubst s2 t2   -- alpha renaming 
        t3  <- appSubst (x,u ) t2'   -- subst after alpha renaming 
        return (LambdaTerm z t3)
appSubst (x, u) (FixTerm t) = do
    t' <- appSubst (x, u) t
    return (FixTerm t')
appSubst (x, u) (OpTerm t1 op t2) = do
    t1' <- appSubst (x, u) t1
    t2' <- appSubst (x, u) t2
    return (OpTerm t1' op t2')
