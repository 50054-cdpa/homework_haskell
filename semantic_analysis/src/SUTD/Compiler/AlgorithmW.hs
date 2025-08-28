{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}

module SUTD.Compiler.AlgorithmW where

import Prelude hiding ((-))
import qualified Data.Map as DM
import qualified Data.Set as DS
import Control.Monad.Except
import SUTD.Compiler.LambdaCalculus
import SUTD.Compiler.Util

type TVarName = String

-- | the data type definition of types of Lambda Calculus 
data Type = IntTy       -- ^ int 
    | BoolTy            -- ^ bool
    | FunTy Type Type   -- ^ t1 -> t2 
    | VarTy TVarName    -- ^ alpha 
    deriving (Show, Eq)

-- | the data type of type schemes
data TypeScheme = Simple Type       -- ^ T
    | Forall TVarName TypeScheme    -- ^ forall alpha . sig
    deriving (Show, Eq)


-- | type environment 
type Gamma = DM.Map Var TypeScheme


-- | Type Substitution Psi 

data TypeSubst = Empty      -- ^ []
    | Single TVarName Type  -- ^ [t/alpha]
    | Compo                 -- ^ psi2 o psi1
        TypeSubst           -- psi2
        TypeSubst           -- psi1
    deriving (Show, Eq)

-- | compo with simplification
compo :: TypeSubst -> TypeSubst -> TypeSubst
compo Empty psi1 = psi1
compo psi2 Empty = psi2
compo psi2 psi1  = Compo psi2 psi1


-- | the free type var operation interface 
class FTV a where
    ftv :: a -> DS.Set TVarName

-- | free type var for type schemes
-- | ftv(forall alpha.sigma) = ftv(sigma) - {alpha}
instance FTV TypeScheme where
    ftv (Simple ty) = ftv ty
    ftv (Forall alpha sig) = ftv sig - alpha

-- | free type var for type
-- | ftv(alpha) = {alpha} 
-- | ftv(int) = {}
-- | ftv(bool) = {}
-- | ftv(T1 -> T2) = ftv(T1) U ftv(T2)
instance FTV Type where
    ftv IntTy  = DS.empty
    ftv BoolTy = DS.empty
    ftv (FunTy t1 t2) = ftv t1 `DS.union` ftv t2
    ftv (VarTy alpha) = DS.singleton alpha


-- | free type var for type environment
-- | ftv(Gamma) = { alpha | (x, sigma) \in Gamma and alpha in ftv(sigma) }
instance FTV Gamma where
    ftv g = foldl (\ acc p -> case p of
        (x, sigma) -> acc `DS.union` ftv sigma) DS.empty (DM.toList g)


-- | Type substitution operation 
-- | appTySubst applies a type substitution tySubst to an `a` of type A
class TypeSubstitutable a where
    appTySubst :: TypeSubst -> a -> StateResult StateInfo a


-- | Applying Type Substiution to Types 
-- | 
-- | []T = T    (duplicate from the type scheme rule)
-- | (Psi o Psi2)T =  Psi1(Psi2(T))  (duplicate from the type scheme rule)
-- | [T/alpha]int = int
-- | [T/alpha]bool = bool
-- | [T/alpha]alpha = T
-- | [T/alpha]beta = beta     if beta != alpha
-- | [T/alpha]T1 -> T2 = ([T/alpha]T1) -> ([T/alpha]T2)
instance TypeSubstitutable Type where
    appTySubst Empty ty                         = return ty
    appTySubst (Compo psi2 psi1) ty = do
        ty'  <- appTySubst psi1 ty
        ty'' <- appTySubst psi2 ty'
        return ty''
    appTySubst (Single alpha ty') BoolTy        = return BoolTy
    appTySubst (Single alpha ty') IntTy         = return IntTy
    appTySubst (Single alpha ty') (VarTy beta)
        | alpha == beta                         = return ty'
        | otherwise                             = return (VarTy beta)
    appTySubst (Single alpha ty') (FunTy t1 t2) = do
        t1'   <- appTySubst (Single alpha ty') t1
        t2'   <- appTySubst (Single alpha ty') t2
        return (FunTy t1' t2')


-- | Applying Type Substiution to Type schemes 
-- | [] sigma = sigma
-- | [T/alpha] \forall beta.sigma = \forall beta.([T/alpha]sigma)   where beta != alpha and beta not in ftv(T)    
-- | Psi1 o Psi2(sigma) = Psi1(Psi2(sigma))
instance TypeSubstitutable TypeScheme where
    appTySubst Empty sig              = return sig
    appTySubst (Compo psi2 psi1) sig  = do
        sig'  <- appTySubst psi1 sig
        appTySubst psi2 sig'
    appTySubst (Single alpha ty) (Forall beta sig)
        | alpha == beta || beta `DS.member` ftv ty = do -- type var name clashing, we perform alpha renaming on the level of type
            name <- newName
            let s = Single beta (VarTy name)
            sig' <- appTySubst s sig
            appTySubst (Single alpha ty) (Forall name sig')
        | otherwise = do
            sig' <- appTySubst (Single alpha ty) sig
            return (Forall beta sig')
    appTySubst (Single alpha ty') (Simple ty)      = do
        ty'' <- appTySubst (Single alpha ty') ty
        return (Simple ty'')

-- | Applying Type Substiution to Type Environments, Gamma 
-- | Psi(Gamma) = {( (x, Psi(sigma)) | (x, sigma) \in Gamma )}
instance TypeSubstitutable Gamma where
    appTySubst tySubst g = do
        kvs <- mapM (\ (x,ts) -> do
                    ts' <- appTySubst tySubst ts
                    return (x, ts')) (DM.toList g)
        return (DM.fromList kvs)



-- | type inference
-- | task 3 TODO
typeInf :: Gamma -> Term -> StateResult StateInfo (Type, TypeSubst)
-- | Gamma, t1 |= T1, Psi1    Psi1(Gamma), t2 |= T2, Psi2
-- | alpha3 = newVar    Psi3 = mgu(Psi2(T1), T2 -> alpha3 )
-- | ----------------------------------------------------- (wApp)
-- | Gamma, t1 t2 |= Psi3(alpha3), Psi3 o Psi2 o Psi1
typeInf g (AppTerm t1 t2) = undefined -- fix me
-- |  c is an integer
-- | ----------------------------- (wInt)
-- | Gamma, c |= int, []
-- | 
-- | 
-- |  c \in {true, false}
-- | ----------------------------- (wBool)
-- | Gamma, c |= bool, []
typeInf _ (ConstTerm (BoolConst v)) = return (BoolTy, Empty)
typeInf _ (ConstTerm (IntConst v))  = return (IntTy, Empty)
-- | FixTerm in our syntax is FixTerm(t), not AppTerm(Fix, t)
-- | We need to treat it as applying "fix" to "t". hence this should combines wApp rule and wFix rule
-- | The original (wFix) rule
-- | (fix, forall alpha. (alpha -> alpha)-> alpha)  \in Gamma     inst(forall alpha. (alpha -> alpha)-> alpha)) = T
-- | ----------------------------------------------------------------------------------------------------------- (wFix)
-- | Gamma, fix |=  T, []
-- | 
-- | 
-- | Now Combined with wApp 
-- | 
-- | 
-- | fix, forall alpha. (alpha -> alpha)-> alpha)  \in Gamma    inst(forall alpha. (alpha -> alpha)-> alpha)) = T1
-- | Psi1 = []     Psi1(Gamma), t2 |= T2, Psi2    alpha3 = newVar    Psi3 = mgu(Psi2(T1), T2 -> alpha3)
-- | ----------------------------------------------------------------------------------------------------------- (wFixApp)
-- | Gamma, fix t2 |= Psi3(alpha3), Psi3 o Psi2 o Psi1
typeInf g (FixTerm t2) = do
    ty1         <- inst (Forall "alpha" (Simple (FunTy (FunTy (VarTy "alpha") (VarTy "alpha")) (VarTy "alpha"))))
    let psi1    = Empty
    g1          <- appTySubst psi1 g
    (ty2, psi2) <- typeInf g1 t2
    alpha3      <- newName
    ty1'        <- appTySubst psi2 ty1
    psi3        <- mgu ty1' (FunTy ty2 (VarTy alpha3))
    ty3         <- appTySubst psi3 (VarTy alpha3)
    return (ty3, compo psi3 (compo psi2 psi1))
-- | Gamma, t1 |= T1, Psi1      Psi1' = mgu(bool, T1) o Psi1
-- | Psi1'(Gamma), t2 |= T2, Psi2     Psi2'(Gamma), t3 |= T3, Psi3
-- | Psi4 = mgu(Psi3(T2), Psi2(T3))
-- | ------------------------------------------------------------------------- (wIf)
-- | Gamma, if t1 then t2 else t3 |= Ps4(Psi3(T2)), Psi4 o Psi3 o Psi2 o Psi1' 
typeInf g (IfTerm t1 t2 t3) = do
    (ty1, psi1) <- typeInf g t1
    psi1t       <- mgu BoolTy ty1
    let psi1'   = compo psi1t psi1
    g1          <- appTySubst psi1' g
    (ty2, psi2) <- typeInf g1 t2
    (ty3, psi3) <- typeInf g1 t3
    ty2'        <- appTySubst psi3 ty2
    ty3'        <- appTySubst psi2 ty3
    psi4        <- mgu ty2' ty3'
    ty4         <- appTySubst psi4 ty2'
    return (ty4, compo psi4 (compo psi3 (compo psi2 psi1')))
-- | alpha1 = newVar         Gamma oplus (x, alpha1), t |= T, Psi
-- | ------------------------------------------------ (wLam)
-- | Gamma, \x. t |= Psi(alpha1 -> T), Psi
typeInf g (LambdaTerm x body)
    | x `DM.member` g = do
        -- x is already in gamma, need to alpha-rename x first 
        name <- newName
        let z = Var name
            s = (x, VarTerm z)   -- [z/y]
        body' <- appSubst s body -- alpha renaming 
        typeInf g (LambdaTerm z body')
    | otherwise       = do
        name      <- newName
        let alpha1 = VarTy name
            g1     = DM.insert x (Simple alpha1) g
        (ty2,psi) <- typeInf g1 body
        ty        <- appTySubst psi (FunTy alpha1 ty2)
        return (ty, psi)
-- | Gamma, t1 |= T1, Psi1       Psi1(Gamma) oplus (x, gen(Psi1(Gamma), T1)), t2 |= T2, Psi2
-- | ----------------------------------------------------- (wLet)
-- | Gamma, let x = t1 in t2 |= T2, Psi2 o Psi1        
typeInf g (LetTerm x t1 t2)
    | x `DM.member` g = do
        -- x is already in gamma, need to alpha-rename x first 
        name <- newName
        let z = Var name
            s = (x, VarTerm z)  -- [z/y]
        t2'  <- appSubst s t2   -- alpha renaming 
        (ty,psi) <- typeInf g (LetTerm z t1 t2')
        return (ty, psi)
    | otherwise = undefined -- fixme
-- | Gamma, t1 |= T1, Psi1     Psi1(Gamma), t2 |= T2, Psi2
-- | Psi3 = mgu(Psi2(T1), T2)
-- | --------------------------------------------- (wOp2)
-- | Gamma, t1 == t2 |= bool, Psi3 o Psi2 o Psi1
typeInf g (OpTerm t1 DEqual t2) = do
    (ty1, psi1) <- typeInf g t1
    g1          <- appTySubst psi1 g
    (ty2, psi2) <- typeInf g1 t2
    ty1'        <- appTySubst psi2 ty1
    psi3        <- mgu ty1' ty2
    return (BoolTy, compo psi3 (compo psi2 psi1))
-- | op \in {+, -, *, /}
-- | Gamma, t1 |= T1, Psi1     Psi1(Gamma), t2 |= T2, Psi2
-- | Psi3 = mgu(Psi2(T1), T2, int)
-- | --------------------------------------------- (wOp1)
-- | Gamma, t1 op t2 |= int, Psi3 o Psi2 o Psi1
typeInf g (OpTerm t1 op t2) = do
    (ty1, psi1) <- typeInf g t1
    g1          <- appTySubst psi1 g
    (ty2, psi2) <- typeInf g1 t2
    ty1'        <- appTySubst psi2 ty1
    psi3        <- mgu3 ty1' ty2 IntTy
    return (IntTy, compo psi3 (compo psi2 psi1))
-- | (x, sigma) \in Gamma,   inst(sigma) = T
-- | ------------------------------------------------ (wVar)
-- | Gamma, x |= T, []
typeInf g (VarTerm x) = case DM.lookup x g of
    Nothing -> throwError ("type inference failed. " ++ show x  ++ "is undefined.")
    Just ts -> do
        ty <- inst ts
        return (ty, Empty)


-- | Type scheme instantiation
inst :: TypeScheme -> StateResult StateInfo Type
-- | [beta/alpha](inst(sig))  where beta = newVar
inst (Forall alpha sig) = do
    name <- newName
    let beta = VarTy name
        s    = Single alpha beta
    sig' <- appTySubst s sig
    inst sig'
inst (Simple t) = return t


-- | Type generalization
-- | gen(Gamma, T) = forall \bar{alpha}. T    where \bar{alpha} = ftv(T) - ftv(Gamma)
gen :: Gamma -> Type -> TypeScheme
gen g ty =
    let freeVars = DS.toList (ftv ty `DS.difference` ftv g)
    in foldl (flip Forall) (Simple ty) freeVars

-- | most general unifier
-- | mgu(alpha, T) = [T/alpha]
-- | mgu(T, alpha) = [T/alpha]
-- | mgu(int, int) = []
-- | mgu(bool, bool) = []
-- | mgu(T1 -> T2, T3 -> T4) = let Psi1 = mgu(T1, T3)
-- |                               Psi2 = mgu(Psi1(T2), Psi1(T4))
-- |                           in Psi2 o Psi1
mgu :: Type -> Type -> StateResult StateInfo TypeSubst 
-- task 2 todo: 
mgu (VarTy alpha) ty2  = return (Single alpha ty2)
mgu ty1 (VarTy alpha)  = return (Single alpha ty1)
mgu ty1 ty2            = undefined -- fixme 


-- | mgu(T1,T2,T3) = let psi1 = mgu(T1,T2)
-- |                     psi2 = mgu(psi1(T2), psi1(T3))
-- |                 in psi2 o psi1
mgu3 :: Type -> Type -> Type -> StateResult StateInfo TypeSubst 
mgu3 ty1 ty2 ty3 = do 
    psi1 <- mgu ty1 ty2 
    ty2' <- appTySubst psi1 ty2
    ty3' <- appTySubst psi1 ty3 
    psi2 <- mgu ty2' ty3'
    return (compo psi2 psi1)