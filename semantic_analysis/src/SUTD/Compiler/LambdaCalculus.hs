module SUTD.Compiler.LambdaCalculus where 

import Prelude hiding ((-))
import Data.Set 


-- | Lambda Calculus Terms
data Term = ConstTerm Const -- ^ c 
    | VarTerm Var           -- ^ x
    | LambdaTerm Var Term   -- ^ \x.t 
    | AppTerm Term Term     -- ^ t t
    | IfTerm Term Term Term -- ^ if t then t else t
    | OpTerm Term Op Term   -- ^ t 
    | LetTerm Var Term Term -- ^ let x = t in t
    | FixTerm Term          -- ^ fix t
    deriving (Show, Eq)

-- | Variables
data Var = Var String deriving (Show, Eq, Ord) 

-- | Constants
data Const = IntConst Int | BoolConst Bool deriving (Show, Eq)

-- | Binary Operators
data Op = Plus  -- ^ + 
    | Minus     -- ^ -
    | Mult      -- ^ *
    | Div       -- ^ /
    | DEqual    -- ^ == 
    deriving (Show, Eq)

-- | All the possible values
data Value = ConstValue Const   -- ^ c 
    | LambdaValue Term          -- ^ \x.t
    deriving (Show, Eq)

(-) :: (Ord a) => Set a -> a -> Set a 
(-) = flip delete


-- | Compute the set of free variables in term t
fv :: Term -> Set Var 
fv (VarTerm y)         = singleton y
fv (LambdaTerm x body) = (fv body) - x
fv (AppTerm t1 t2)     = fv t1 `union` fv t2
fv (LetTerm x t1 t2)   = ((fv t1) - x) `union` fv t2 
fv (IfTerm t1 t2 t3)   = fv t1 `union` fv t2 `union` fv t3
fv (ConstTerm c)       = empty 
fv (FixTerm t1)        = fv t1 
fv (OpTerm t1 op t2)   = fv t1 `union` fv t2