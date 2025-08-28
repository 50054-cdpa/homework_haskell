module SUTD.Compiler.LexerSpec where

import Test.Hspec
import Prelude hiding (lex)
import SUTD.Compiler.Parsec
import SUTD.Compiler.Lexer

spec :: Spec
spec = do
    describe "SUTD.Compiler.LexerSpec" $ do 
        it "test: lex [a-z] is working" $            
            let s = "[a-z]"
                lenv = LEnv s 0 0
                result = run lex lenv 
                expected = Consumed (Ok ([LBracket (SrcLoc 0 1), AlphaNum (SrcLoc 0 2) 'a', Hyphen (SrcLoc 0 3), AlphaNum (SrcLoc 0 4) 'z', RBracket (SrcLoc 0 5)], LEnv [] 0 5)) 
            in result `shouldBe` expected

        it "test: lex [a-z]* is working" $            
            let s = "[a-z]*"
                lenv = LEnv s 0 0
                result = run lex lenv 
                expected = Consumed (Ok ([LBracket (SrcLoc 0 1), AlphaNum (SrcLoc 0 2) 'a', Hyphen (SrcLoc 0 3), AlphaNum (SrcLoc 0 4) 'z', RBracket (SrcLoc 0 5), Asterix (SrcLoc 0 6)], LEnv [] 0 6)) 
            in result `shouldBe` expected

        it "test: lex [ab][AC]* is working" $            
            let s = "[ab][AC]*"
                lenv = LEnv s 0 0
                result = run lex lenv 
                expected = Consumed (Ok ([LBracket (SrcLoc 0 1), AlphaNum (SrcLoc 0 2) 'a', AlphaNum (SrcLoc 0 3) 'b', 
                                            RBracket (SrcLoc 0 4), LBracket (SrcLoc 0 5), AlphaNum (SrcLoc 0 6) 'A', 
                                            AlphaNum (SrcLoc 0 7) 'C', RBracket (SrcLoc 0 8), Asterix (SrcLoc 0 9)], LEnv [] 0 9)) 
            in result `shouldBe` expected   

        it "test: lex ((ab)|(a))((baa)|a)((ac)|c) is working" $            
            let s = "((ab)|(a))((baa)|a)((ac)|c)"
                lenv = LEnv s 0 0
                result = run lex lenv 
                expected = Consumed (Ok ([LParen (SrcLoc 0 1), LParen (SrcLoc 0 2), AlphaNum (SrcLoc 0 3) 'a', AlphaNum (SrcLoc 0 4) 'b', RParen (SrcLoc 0 5), VertBar (SrcLoc 0 6), 
                                            LParen (SrcLoc 0 7), AlphaNum (SrcLoc 0 8) 'a', RParen (SrcLoc 0 9), RParen (SrcLoc 0 10), LParen (SrcLoc 0 11), LParen (SrcLoc 0 12), 
                                            AlphaNum (SrcLoc 0 13) 'b', AlphaNum (SrcLoc 0 14) 'a', AlphaNum (SrcLoc 0 15) 'a', RParen (SrcLoc 0 16), VertBar (SrcLoc 0 17), AlphaNum (SrcLoc 0 18) 'a', 
                                            RParen (SrcLoc 0 19), LParen (SrcLoc 0 20), LParen (SrcLoc 0 21), AlphaNum (SrcLoc 0 22) 'a', AlphaNum (SrcLoc 0 23) 'c', RParen (SrcLoc 0 24), 
                                            VertBar(SrcLoc 0 25), AlphaNum (SrcLoc 0 26) 'c', RParen (SrcLoc 0 27)], LEnv [] 0 27)) 
            in result `shouldBe` expected 