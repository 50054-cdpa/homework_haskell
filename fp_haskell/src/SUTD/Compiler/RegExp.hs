module SUTD.Compiler.RegExp where 

data RE = Choice RE RE 
    | Seq RE RE 
    | Star RE 
    | Epsilon 
    | Letter Char
    | Phi
    deriving (Show, Eq)


eps :: RE -> Bool
eps = undefined -- fixme 

deriv :: RE -> Char -> RE 
deriv = undefined -- fixme 

wordMatch :: [Char] -> RE -> Bool 
wordMatch = undefined -- fixme
