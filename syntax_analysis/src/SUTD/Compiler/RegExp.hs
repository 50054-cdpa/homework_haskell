{-# LANGUAGE MultiParamTypeClasses #-}


module SUTD.Compiler.RegExp where

import Data.List (sort)
import qualified Data.Map as DM
import qualified Data.Set as DS
import SUTD.Compiler.Automata

data RE = Choice RE RE
    | Seq RE RE
    | Star RE
    | Epsilon
    | Letter Char
    | Phi
    deriving (Show, Eq)

-- task 0
eps :: RE -> Bool
eps = undefined -- fixme 

-- task 0
deriv :: RE -> Char -> RE
deriv = undefined -- fixme 

-- task 0
wordMatch :: [Char] -> RE -> Bool
wordMatch = undefined -- fixme

-- task 1
mkSimpleSM :: RE -> StateMachine RE Char 
mkSimpleSM r = StateMachine r stepImpl eps  
    where
        stepImpl = undefined -- fixme


-- task 2.1
isPhi :: RE -> Bool
isPhi = undefined -- fixme 


isEps :: RE -> Bool
isEps = undefined -- fixme 


-- task 2.2
-- implementing the order among RE with Phi < Eps < Letter < Choice < Seq < Star
instance Ord RE where
    compare Phi Phi                       = EQ
    compare Phi _                         = LT
    compare Epsilon Phi                   = GT
    compare Epsilon Epsilon               = EQ
    compare Epsilon _                     = LT
    compare (Letter _) Phi                = GT
    compare (Letter _) Epsilon            = GT
    compare (Letter l1) (Letter l2)       = compare l1 l2
    compare (Letter _) _                  = LT
    compare (Choice _ _) Phi              = GT
    compare (Choice _ _) Epsilon          = GT
    compare (Choice _ _) (Letter _)       = GT
    compare (Choice r1 r2) (Choice r3 r4) =
        case compare r1 r3 of
            EQ -> compare r2 r4
            o  -> o
    compare (Choice _ _) _                = LT
    compare _ _ = undefined  -- TODO: complete the missing cases


-- given
norm :: RE -> RE
norm = mkChoice . normChoice

-- given
normChoice :: RE -> [RE]
normChoice (Choice r1 r2) =
    let nr2 = normChoice r2
        nr1 = normChoice r1
    in rmdup (sort (nr1 ++ nr2))
normChoice r = [normSeq r]


-- task 2.3 
rmdup :: [RE] -> [RE]
rmdup = undefined -- fix me 


-- given 
mkChoice :: [RE] -> RE
mkChoice []     = Phi 
mkChoice [r]    = r 
mkChoice (r:rs) = Choice r (mkChoice rs)

-- given
normSeq :: RE -> RE 
normSeq (Seq (Seq r11 r12) r2) = normSeq (Seq r11 (Seq r12 r2))
normSeq (Seq r1 r2)            = Seq r1 (normSeq r2) 
normSeq r                      = r 

-- task 2.4 
simp1 :: RE -> RE 
simp1 (Choice r1 r2) 
    | isPhi r1 && isPhi r2 = Phi
    | isPhi r1             = simp1 r2
    | isPhi r2             = simp1 r1
    | otherwise            = norm (Choice (simp1 r1) (simp1 r2))
simp1 (Seq r1 r2)          = undefined -- fix me
simp1 (Star r)             = undefined -- fix me
simp1 r                    = r

simp :: RE -> RE 
simp r = 
    let r' = simp1 r
    in  if r' == r
        then r'
        else simp r'

sigma :: RE -> DS.Set Char
sigma (Choice r1 r2) = sigma r1 `DS.union` sigma r2
sigma (Seq r1 r2)    = sigma r1 `DS.union` sigma r2
sigma (Star r)       = sigma r 
sigma (Letter l)     = DS.singleton l 
sigma Epsilon        = DS.empty
sigma Phi            = DS.empty 

build :: RE -> DS.Set Char -> DS.Set (RE, Char, RE)
build r sig = go (DS.singleton r) DS.empty DS.empty
    where 
        go newDs seenDs delta 
            | DS.null newDs = delta
            | otherwise     = 
                let newDelta = DS.unions 
                        (DS.map (\r -> 
                            DS.map (\l -> (r, l, simp (deriv r l))) sig) newDs)
                    nextNewDs = (DS.map (\(r,l,d) -> d) newDelta) `DS.difference` seenDs
                    nextSeenDs = seenDs `DS.union` newDs
                in go nextNewDs nextSeenDs (delta `DS.union` newDelta)





compile :: RE -> (DM.Map (Int, Char) Int, DS.Set Int)
compile r = 
    let allSymbs   = sigma r 
        delta      = build r allSymbs
        allDests = undefined -- fixme, extract all destination from the delta 
        allDestsExceptR = DS.delete r allDests
        -- mapping re to int ids
        table      = DM.fromList (zip (r:(DS.toList allDestsExceptR)) [0..])
        delta_num  = undefined -- fixme, conver the states found in delta into integerss
        final_num  = DS.fromList (map snd (DM.toList (DM.filterWithKey (\t i -> eps t) table))) 
    in (delta_num, final_num)

mkEfficientSM :: RE -> StateMachine Int Char
mkEfficientSM r = 
    case compile r of 
        (delta, final) -> 
            let isFin i = i `DS.member` final
                stepImpl i l = case DM.lookup (i,l) delta of 
                    Nothing -> Nothing 
                    Just j  -> Just (StateMachine j stepImpl isFin) 
            in StateMachine 0 stepImpl isFin