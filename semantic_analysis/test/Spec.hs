import Test.Hspec
import qualified SUTD.Compiler.BigStepEvalSpec (spec)
import qualified SUTD.Compiler.SmallStepEvalSpec (spec)
import qualified SUTD.Compiler.AlgorithmWSpec (spec)

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
    describe "SUTD.Compiler.BigStepEvalSpec" SUTD.Compiler.BigStepEvalSpec.spec
    describe "SUTD.Compiler.SmallStepEvalSpec" SUTD.Compiler.SmallStepEvalSpec.spec
    describe "SUTD.Compiler.AlgorithmWSpec" SUTD.Compiler.AlgorithmWSpec.spec


-- to run test
-- 1) cabal test; or
-- 2) stack test

-- to run a specific spec
-- cabal test --test-options="-m Ex1Spec" 