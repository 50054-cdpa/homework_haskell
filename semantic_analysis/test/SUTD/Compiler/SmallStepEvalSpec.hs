module SUTD.Compiler.SmallStepEvalSpec  where 

import Test.Hspec
import Control.Monad.State
import SUTD.Compiler.LambdaCalculus
import SUTD.Compiler.Util (StateInfo(..), Result(..))
import SUTD.Compiler.SmallStepEval (eval)


st :: StateInfo
st = StateInfo 0


spec :: Spec
spec = do 
    describe "SUTD.Compiler.SmallStepEval" $ do
        it "const should be evaluated to const" $ 
            let input = ConstTerm (IntConst 1)
                result = runStateT (eval input) st
                expected = Ok (ConstValue (IntConst 1), StateInfo 0)
            in result `shouldBe` expected

        it "identity function should be returning the same value" $ 
            let idf = LambdaTerm (Var "x") (VarTerm (Var "x")) -- \x.x 
                one = ConstTerm (IntConst 1)
                input = AppTerm idf one
                result = runStateT (eval input) st
                expected = Ok (ConstValue (IntConst 1), StateInfo 0)
            in result `shouldBe` expected

        it "factorial 3 should be 6" $ 
            let three = ConstTerm (IntConst 3)
                zero  = ConstTerm (IntConst 0) 
                one   = ConstTerm (IntConst 1)
                varx  = Var "x" 
                varf  = Var "f" 
                cond  = OpTerm (VarTerm varx) DEqual zero -- x == 0
                ifelse = IfTerm cond one (OpTerm (VarTerm varx) Mult (AppTerm (VarTerm varf) (OpTerm (VarTerm varx) Minus one))) -- if x == 0 then 1 else x * (f (x - 1))
                fac   = FixTerm (LambdaTerm varf (LambdaTerm varx ifelse)) -- fix \f. \x. if == 0 then 1 else x * (f (x - 1))
                input = AppTerm fac three
                result = runStateT (eval input) st
                expected = Ok (ConstValue (IntConst 6), StateInfo 4)
            in result `shouldBe` expected