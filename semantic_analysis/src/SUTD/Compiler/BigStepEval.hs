{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE InstanceSigs #-}
module SUTD.Compiler.BigStepEval where



import Control.Monad.Except
import SUTD.Compiler.LambdaCalculus hiding ((-))
import SUTD.Compiler.Util


-- | implementing big step operational semantics for lambda calculus
eval :: Term -> StateResult StateInfo Value 
eval (ConstTerm c) = return (ConstValue c)
eval (VarTerm v)   = throwError "Unbound variable."
eval (LambdaTerm x t) = return (LambdaValue (LambdaTerm x t))
eval (FixTerm t1) = do 
    v1 <- eval t1
    t1'' <- case v1 of 
        { LambdaValue (LambdaTerm f t1') -> appSubst (f, FixTerm t1) t1'
        ; _ -> throwError "fix is applied to a non-lambda term." 
        }
    eval t1'' 
eval (AppTerm t1 t2) = do 
    v1 <- eval t1
    t3' <- case v1 of 
        { LambdaValue (LambdaTerm x t3) -> appSubst (x, t2) t3
        ; _ -> throwError "the left subterm of a function application does not evaluate to a lambda value."
        }
    eval t3'
eval (IfTerm t1 t2 t3) = do 
    v1 <- eval t1 
    if isTrue v1 
    then eval t2
    else eval t3
eval (LetTerm x t1 t2) = do 
    t' <- appSubst (x,t1) t2
    eval t'
eval (OpTerm t1 op t2) = do 
    v1 <- eval t1 
    v2 <- eval t2 
    case op of 
        DEqual -> equal v1 v2 
        Plus   -> plus v1 v2 
        Minus  -> minus v1 v2 
        Mult   -> mult v1 v2
        Div    -> divide v1 v2


-- | check whether the two input values v1 and v2 are the same type and equal.
equal :: Value -> Value -> StateResult StateInfo Value 
equal (ConstValue (IntConst u1)) (ConstValue (IntConst u2)) = return (ConstValue (BoolConst (u1 == u2)))
equal (ConstValue (BoolConst u1)) (ConstValue (BoolConst u2)) = return (ConstValue (BoolConst (u1 == u2)))
equal _ _ = throwError "type mismatch for equality test."

-- | compute the sum of two input values v1 and v2 if they are of type int.
plus :: Value -> Value -> StateResult StateInfo Value
plus (ConstValue (IntConst u1)) (ConstValue (IntConst u2)) = return (ConstValue (IntConst (u1 + u2)))
plus _ _ = throwError "type mismatch for plus operation."

-- | compute the difference of two input values v1 and v2 if they are of type int.
minus :: Value -> Value -> StateResult StateInfo Value
minus (ConstValue (IntConst u1)) (ConstValue (IntConst u2)) = return (ConstValue (IntConst (u1 - u2)))
minus _ _ = throwError "type mismatch for minus operation."


-- | compute the product of two input values v1 and v2 if they are of type int.
mult :: Value -> Value -> StateResult StateInfo Value
mult (ConstValue (IntConst u1)) (ConstValue (IntConst u2)) = return (ConstValue (IntConst (u1 * u2)))
mult _ _ = throwError "type mismatch for mult operation."


-- | compute the quotient of two input values v1 and v2 if they are of type int.
divide :: Value -> Value -> StateResult StateInfo Value
divide (ConstValue (IntConst u1)) (ConstValue (IntConst u2)) 
    | u2 /= 0 = return (ConstValue (IntConst (u1 `div` u2)))
    | otherwise = throwError "divide by zero error."
divide _ _ = throwError "type mismatch for mult operation."


-- | isTrue returns true if the input value is a boolean value and it is true.
isTrue :: Value -> Bool 
isTrue (ConstValue (BoolConst v)) = v
isTrue _ = False