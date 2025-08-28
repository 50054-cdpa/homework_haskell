{-# LANGUAGE FunctionalDependencies #-}

module SUTD.Compiler.Automata where

data StateMachine s l = StateMachine {
    start     :: s,  
    step      :: s -> l -> Maybe (StateMachine s l), 
    isFinal   :: s -> Bool 
}

runStateMachine :: StateMachine s l -> [l] -> Bool 
runStateMachine (StateMachine curr _ isFinal) []  = isFinal curr
runStateMachine (StateMachine curr step _) (l:ls) =
    case step curr l of 
        Nothing   -> False 
        Just stm' -> runStateMachine stm' ls 