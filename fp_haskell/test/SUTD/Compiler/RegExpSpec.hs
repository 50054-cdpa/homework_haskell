module SUTD.Compiler.RegExpSpec where

import SUTD.Compiler.RegExp
import Test.Hspec

spec :: Spec
spec = do
  describe "SUTD.Compiler.RegexSpec" $ do
    it "test: eps (a.b*) is False" $
      -- r = (a.b*)
      let r = Seq (Letter 'a') (Star (Letter 'b'))
          result = eps r
          expected = False
       in result `shouldBe` expected

    it "test: eps (a*.(b*+c)) is True" $
      -- r = (a*.(b*+c))
      let r = Seq (Star (Letter 'a')) (Choice (Star (Letter 'b')) (Letter 'c'))
          result = eps r
          expected = True
       in result `shouldBe` expected

    it "test: deriv (a.b*) a is eps.b* " $
      -- r = (a.b*)
      let r = Seq (Letter 'a') (Star (Letter 'b'))
          result = deriv r 'a'
          expected = Seq Epsilon (Star (Letter 'b'))
       in result `shouldBe` expected

    it "test: deriv (a*.(b*+c)) b is ((phi.a*).(b*+c))+(epsilon.b* + phi)" $
      -- r = (a*.(b*+c))
      let r = Seq (Star (Letter 'a')) (Choice (Star (Letter 'b')) (Letter 'c'))
          result = deriv r 'b'
          expected = Choice (Seq (Seq Phi (Star (Letter 'a'))) (Choice (Star (Letter 'b')) (Letter 'c'))) (Choice (Seq Epsilon (Star (Letter 'b'))) Phi)
       in result `shouldBe` expected

    it "test: match aaab (a+b)* is True" $
      -- r = (a+b)*
      let r = Star (Choice (Letter 'a') (Letter 'b'))
          w = "aaab"
          result = wordMatch w r
          expected = True
       in result `shouldBe` expected


    it "test: match aaab ((a.a)+b)*.c  is False" $
      -- r = ((a.a)+b)*.c 
      let r = Seq (Star (Choice (Seq (Letter 'a') (Letter 'a')) (Letter 'b')))  (Letter 'c')
          w = "abaac"
          result = wordMatch w r
          expected = False
       in result `shouldBe` expected