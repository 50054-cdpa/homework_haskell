module SUTD.Compiler.AlgorithmWSpec  where 

import Test.Hspec
import qualified Data.Map as DM
import Control.Monad.State
import SUTD.Compiler.LambdaCalculus
import SUTD.Compiler.Util (StateInfo(..), Result(..))
import SUTD.Compiler.AlgorithmW


st :: StateInfo
st = StateInfo 0


spec :: Spec
spec = do 
    describe "SUTD.Compiler.AlgorithmWSpec" $ do
        it "test mgu: int and int can be unified" $ 
            let ty1 = IntTy
                ty2 = IntTy 
                result = runStateT (mgu ty1 ty2) st
                expected = Ok (Empty, StateInfo 0)
            in result `shouldBe` expected

        it "test mgu: int and bool cannot be unified" $ 
            let ty1 = IntTy
                ty2 = BoolTy 
                result = runStateT (mgu ty1 ty2) st
                expected = Error "unification failed. Can't unify IntTy with BoolTy."
            in result `shouldBe` expected

        it "test mgu: int and alpha can be unified" $ 
            let ty1 = IntTy
                ty2 = VarTy "a" 
                result = runStateT (mgu ty1 ty2) st
                expected = Ok (Single "a" IntTy, StateInfo 0)
            in result `shouldBe` expected

        it "test mgu: int -> alpha and alpha -> int can be unified" $ 
            let ty1 = FunTy IntTy (VarTy "a")
                ty2 = FunTy (VarTy "a") IntTy 
                result = runStateT (mgu ty1 ty2) st
                expected = Ok (Single "a" IntTy, StateInfo 0)
            in result `shouldBe` expected

        it "test algo W: 1 has type int" $ 
            let t = ConstTerm (IntConst 1)
                g = DM.empty 
                result = runStateT (typeInf g t) st
                expected = Ok ((IntTy, Empty), StateInfo 0)
            in result `shouldBe` expected


        it "test algo W: \\x.x has type alpha -> alpha" $ 
            let t = LambdaTerm (Var "x") (VarTerm (Var "x"))
                g = DM.empty 
                result = runStateT (typeInf g t) st
                expected = Ok ((FunTy (VarTy "_x_$0") (VarTy "_x_$0"), Empty), StateInfo 1)
            in result `shouldBe` expected


        it "test algo W: fix \\f.\\x. if x == 0 then 1 else x * (f (x-1)) has type int -> int" $ 
            let three    = ConstTerm (IntConst 3)
                zero     = ConstTerm (IntConst 0) 
                one      = ConstTerm (IntConst 1)
                varx     = Var "x" 
                varf     = Var "f" 
                cond     = OpTerm (VarTerm varx) DEqual zero -- x == 0
                ifelse   = IfTerm cond one (OpTerm (VarTerm varx) Mult (AppTerm (VarTerm varf) (OpTerm (VarTerm varx) Minus one))) -- if x == 0 then 1 else x * (f (x - 1))
                fac      = FixTerm (LambdaTerm varf (LambdaTerm varx ifelse)) -- fix \f. \x. if == 0 then 1 else x * (f (x - 1))
                g        = DM.empty 
                result   = runStateT (typeInf g fac) st
                psi      = Compo (Compo (Single "_x_$4" (FunTy IntTy IntTy)) (Single "_x_$0" (FunTy IntTy IntTy))) (Compo (Compo (Single "_x_$3" IntTy) (Single "_x_$1" (FunTy IntTy (VarTy "_x_$3")))) (Single "_x_$2" IntTy))
                expected = Ok ((FunTy IntTy IntTy, psi), StateInfo 5)
            in result `shouldBe` expected

        it "test algo W: let f=\\x.x in (let g=\\x.\\y.x in g (f 1) (f true)) has type int" $ 
            let one      = IntConst 1
                tt       = BoolConst True
                varx     = Var "x"
                vary     = Var "y"
                varf     = Var "f"
                varg     = Var "g"
                id       = LambdaTerm varx (VarTerm varx) -- \x.x 
                fst      = LambdaTerm varx (LambdaTerm vary (VarTerm varx))
                t        = LetTerm varf id $
                                LetTerm varg fst $ 
                                    AppTerm (AppTerm (VarTerm varg) 
                                                (AppTerm (VarTerm varf) (ConstTerm one))) 
                                            (AppTerm (VarTerm varf) (ConstTerm tt))
                g        = DM.empty
                result   = runStateT (typeInf g t) st
                psi      = Compo (Compo (Single "_x_$10" IntTy) (Single "_x_$3" BoolTy)) (Compo (Compo (Single "_x_$9" BoolTy) (Single "_x_$8" BoolTy)) (Compo (Compo (Single "_x_$7" (FunTy (VarTy "_x_$3") IntTy)) (Single "_x_$4" IntTy)) (Compo (Single "_x_$6" IntTy) (Single "_x_$5" IntTy))))
                expected = Ok ((IntTy, psi), StateInfo 11)
            in result `shouldBe` expected