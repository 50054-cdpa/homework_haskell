module SUTD.Compiler.ParserSpec where

import Test.Hspec
import Prelude hiding (lex)
import SUTD.Compiler.Parsec
import SUTD.Compiler.Lexer
import SUTD.Compiler.RegExp 
import SUTD.Compiler.Parser


spec :: Spec
spec = do
    describe "SUTD.Compiler.ParserSpec" $ do 

        it "test: parseRgex [a-z]* is Right (Star (mkChoice (map Letter ['a'..'z'])))" $            
            let input  = [LBracket (SrcLoc 0 1), AlphaNum (SrcLoc 0 2) 'a', Hyphen (SrcLoc 0 3), AlphaNum (SrcLoc 0 4) 'z', RBracket (SrcLoc 0 5), Asterix (SrcLoc 0 6)]
                result = parseRegex input
                expected = Right (Star (mkChoice (map Letter ['a'..'z'])))
            in result `shouldBe` expected

        it "test: parseRgex [ab][AC]* is Right (Seq (Choice (Letter 'a') (Letter 'b')) (Star (Choice (Letter 'A') (Letter 'C')))) " $            
            let input = [LBracket (SrcLoc 0 1), AlphaNum (SrcLoc 0 2) 'a', AlphaNum (SrcLoc 0 3) 'b', 
                                            RBracket (SrcLoc 0 4), LBracket (SrcLoc 0 5), AlphaNum (SrcLoc 0 6) 'A', 
                                            AlphaNum (SrcLoc 0 7) 'C', RBracket (SrcLoc 0 8), Asterix (SrcLoc 0 9)]
                result = parseRegex input
                expected = Right (Seq (Choice (Letter 'a') (Letter 'b')) (Star (Choice (Letter 'A') (Letter 'C')))) 
            in result `shouldBe` expected   

        it "test: parseRgex ((ab)|(a))((baa)|a)((ac)|c) is Right (Seq (Choice (Seq(Letter 'a') (Letter 'b')) (Letter 'a')) (Seq (Choice (Seq (Letter 'b') (Seq (Letter 'a') (Letter 'a'))) (Letter 'a')) (Choice (Seq (Letter 'a') (Letter 'c')) (Letter 'c')))) " $            
            let input = [LParen (SrcLoc 0 1), LParen (SrcLoc 0 2), AlphaNum (SrcLoc 0 3) 'a', AlphaNum (SrcLoc 0 4) 'b', RParen (SrcLoc 0 5), VertBar (SrcLoc 0 6), 
                                            LParen (SrcLoc 0 7), AlphaNum (SrcLoc 0 8) 'a', RParen (SrcLoc 0 9), RParen (SrcLoc 0 10), LParen (SrcLoc 0 11), LParen (SrcLoc 0 12), 
                                            AlphaNum (SrcLoc 0 13) 'b', AlphaNum (SrcLoc 0 14) 'a', AlphaNum (SrcLoc 0 15) 'a', RParen (SrcLoc 0 16), VertBar (SrcLoc 0 17), AlphaNum (SrcLoc 0 18) 'a', 
                                            RParen (SrcLoc 0 19), LParen (SrcLoc 0 20), LParen (SrcLoc 0 21), AlphaNum (SrcLoc 0 22) 'a', AlphaNum (SrcLoc 0 23) 'c', RParen (SrcLoc 0 24), 
                                            VertBar(SrcLoc 0 25), AlphaNum (SrcLoc 0 26) 'c', RParen (SrcLoc 0 27)]
                result = parseRegex input
                expected = Right (Seq
                                    (Choice (Seq(Letter 'a') (Letter 'b')) (Letter 'a'))
                                    (Seq (Choice (Seq (Letter 'b') (Seq (Letter 'a') (Letter 'a'))) (Letter 'a')) (Choice (Seq (Letter 'a') (Letter 'c')) (Letter 'c')))) 
            in result `shouldBe` expected 