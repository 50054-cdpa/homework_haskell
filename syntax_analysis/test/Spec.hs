import Test.Hspec
import qualified SUTD.Compiler.RegExpSpec (spec)
import qualified SUTD.Compiler.LexerSpec (spec)
import qualified SUTD.Compiler.ParserSpec (spec)

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
    describe "SUTD.Compiler.RegExpSpec" SUTD.Compiler.RegExpSpec.spec
    describe "SUTD.Compiler.LexerSpec"  SUTD.Compiler.LexerSpec.spec
    describe "SUTD.Compiler.ParserSpec"  SUTD.Compiler.ParserSpec.spec

-- to run test
-- 1) cabal test; or
-- 2) stack test

-- to run a specific spec
-- cabal test --test-options="-m Ex1Spec" 