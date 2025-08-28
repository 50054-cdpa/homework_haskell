module Main where

import qualified MyLib (foo)

main :: IO ()
main = do
  putStrLn "Hello, Haskell!"
  putStrLn $ "1 + 2 = " ++ show (MyLib.foo 1 2)