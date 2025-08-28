module SUTD.Compiler.RegExpSpec where

import SUTD.Compiler.RegExp
import SUTD.Compiler.Automata
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


        it "test: runStateMachine (mkSimpleSM b*) bbb is True" $ 
            -- r = b*
            let r = Star (Letter 'b')
                w = "bbb"
                result = runStateMachine (mkSimpleSM r) w 
                expected = True 
            in result `shouldBe` expected

        it "test: runStateMachine (mkSimpleSM (aa)*) aaa is False" $ 
            -- r = (aa)*
            let r = Star (Seq (Letter 'a') (Letter 'a'))
                w = "aaa"
                result = runStateMachine (mkSimpleSM r) w 
                expected = False 
            in result `shouldBe` expected


        it "test: runStateMachine (mkSimpleSM (aa)*) aaaa is True" $ 
            -- r = (aa)*
            let r = Star (Seq (Letter 'a') (Letter 'a'))
                w = "aaaa"
                result = runStateMachine (mkSimpleSM r) w 
                expected = True 
            in result `shouldBe` expected


        it "test: runStateMachine (mkSimpleSM (a+b)*) aaab is True" $ 
            -- r = (a+b)*
            let r = Star (Choice (Letter 'a') (Letter 'b'))
                w = "aaab" 
                result = runStateMachine (mkSimpleSM r) w 
                expected = True 
            in result `shouldBe` expected

        it "test: runStateMachine (mkSimpleSM ((a.a)+b)*.c) abaac is False" $ 
            -- r = ((a.a)+b)*.c 
            let r = Seq (Star (Choice (Seq (Letter 'a') (Letter 'a')) (Letter 'b')))  (Letter 'c')
                w = "abaac"
                result = runStateMachine (mkSimpleSM r) w 
                expected = False 
            in result `shouldBe` expected


        it "test: isEps (Star (Seq (Letter 'a') (Letter 'a'))) is False" $ 
            -- r = (aa)*
            let r = Star (Seq (Letter 'a') (Letter 'a'))
                result = isEps r
                expected = False
            in result `shouldBe` expected 

        it "test: isEps (Star (Seq (Letter 'a') (Letter 'a'))) is True" $ 
            -- r = (eps.(eps+eps))*
            let r = Star (Seq Epsilon (Choice Epsilon Epsilon))
                result = isEps r
                expected = True
            in result `shouldBe` expected 

        it "test: isPhi (Star (Seq (Letter 'a') (Letter 'a'))) is False" $ 
            -- r = (eps.(eps+eps))*
            let r = Star (Seq Epsilon (Choice Epsilon Epsilon))
                result = isPhi r
                expected = False
            in result `shouldBe` expected 


        it "test: isPhi (Seq Epsilon (Choice Phi Phi)) is True" $ 
            -- r = eps.(phi+phi)
            let r = Seq Epsilon (Choice Phi Phi)
                result = isPhi r
                expected = True
            in result `shouldBe` expected 


        it "test: compare b* a* is GT" $ 
            -- r1 = b*
            -- r2 = a* 
            let r1 = Star (Letter 'b')
                r2 = Star (Letter 'a')
                result = compare r1 r2
                expected = GT
            in result `shouldBe` expected 


        it "test: compare (b+a)* (a.b)* is LT" $ 
            -- r1 = (b+a)*
            -- r2 = (a.b)*
            let r1 = Star (Choice (Letter 'b') (Letter 'a'))
                r2 = Star (Seq (Letter 'a') (Letter 'b'))
                result = compare r1 r2
                expected = LT
            in result `shouldBe` expected 


        it "test: norm (((a.b).c) + a*) + (a.(b.c)) is (a.(b.c))+a*" $ 
            -- r = (((a.b).c) + a*) + (a.(b.c))
            let r = Choice (Choice (Seq (Seq (Letter 'a') (Letter 'b'))  (Letter 'c')) (Star (Letter 'a'))) (Seq (Letter 'a') (Seq (Letter 'b')  (Letter 'c')))
                result = norm r
                expected = Choice (Seq (Letter 'a') (Seq (Letter 'b') (Letter 'c'))) (Star(Letter 'a'))
            in result `shouldBe` expected             

        
        it "test: simp (deriv (deriv (deriv b* b) b) b) is b*" $ 
            -- r = b*
            let r = Star (Letter 'b') 
                -- deriv(deriv(deriv(r,b),b),b)
                drbbb = deriv (deriv (deriv r 'b') 'b') 'b'
                result = simp drbbb
                expected = Star (Letter 'b')
            in result `shouldBe` expected

        it "test: simp (deriv (bb)* b) is b(bb)*" $ 
            -- r = (bb)* 
            let r = Star (Seq (Letter 'b') (Letter 'b')) 
                -- deriv(r,b))
                drb = deriv r 'b'
                result = simp drb
                expected = Seq (Letter 'b') (Star (Seq (Letter 'b') (Letter 'b')))
            in result `shouldBe` expected





        it "test: runStateMachine (mkEfficientSM b*) bbb is True" $ 
            -- r = b*
            let r = Star (Letter 'b')
                w = "bbb"
                result = runStateMachine (mkEfficientSM r) w 
                expected = True 
            in result `shouldBe` expected

        it "test: runStateMachine (mkEfficientSM (aa)*) aaa is False" $ 
            -- r = (aa)*
            let r = Star (Seq (Letter 'a') (Letter 'a'))
                w = "aaa"
                result = runStateMachine (mkEfficientSM r) w 
                expected = False 
            in result `shouldBe` expected


        it "test: runStateMachine (mkEfficientSM (aa)*) aaaa is True" $ 
            -- r = (aa)*
            let r = Star (Seq (Letter 'a') (Letter 'a'))
                w = "aaaa"
                result = runStateMachine (mkEfficientSM r) w 
                expected = True 
            in result `shouldBe` expected


        it "test: runStateMachine (mkEfficientSM (a+b)*) aaab is True" $ 
            -- r = (a+b)*
            let r = Star (Choice (Letter 'a') (Letter 'b'))
                w = "aaab" 
                result = runStateMachine (mkEfficientSM r) w 
                expected = True 
            in result `shouldBe` expected

        it "test: runStateMachine (mkEfficientSM ((a.a)+b)*.c) abaac is False" $ 
            -- r = ((a.a)+b)*.c 
            let r = Seq (Star (Choice (Seq (Letter 'a') (Letter 'a')) (Letter 'b')))  (Letter 'c')
                w = "abaac"
                result = runStateMachine (mkEfficientSM r) w 
                expected = False 
            in result `shouldBe` expected