module SUTD.Compiler.SmallStepEval where 


import Control.Monad.Except
import SUTD.Compiler.Util
import SUTD.Compiler.LambdaCalculus hiding ((-))

-- | task 1
-- | implementing small step operational semantics for lambda calculus
evalOneStep :: Term -> StateResult StateInfo Term
evalOneStep (AppTerm (LambdaTerm x t1) t2) = do 
    t3 <- appSubst (x, t2) t1 
    return t3
evalOneStep (AppTerm t1 t2) = do 
    t3 <- evalOneStep t1 
    return (AppTerm t3 t2)
evalOneStep (ConstTerm c) = return (ConstTerm c)
evalOneStep t = undefined -- fixme 


eval :: Term -> StateResult StateInfo Value
eval t = do 
    t' <- evalOneStep t 
    case t' of 
        ConstTerm c   -> return (ConstValue c)
        _ | t' == t   -> throwError "evaluation is stuck." 
          | otherwise -> eval t'  
