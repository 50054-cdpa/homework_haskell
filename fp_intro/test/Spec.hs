-- {-# OPTIONS_GHC -F -pgmF hspec-discover #-}
-- the above does not work with haskell language server unless hspec-discover is in the path
-- doing it manually 

import Test.Hspec
import qualified MyLib (foo)

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
    describe "Spec" $ do 
        it "MyLib.foo 1 1 should be 2" $
            let result = MyLib.foo 1 1
                expected = 2
            in result `shouldBe` expected

-- to run test
-- 1) cabal test; or
-- 2) stack test

-- to run a specific spec
-- cabal test --test-options="-m Lang.Simp.Syntax.LexerSpec" 