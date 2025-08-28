% Parametric Polymorphism and Adhoc Polymorphism


# Compiling Regular expression 
In this homework, you are tasked to compile a regular expression into a state machine.


## Syntax (Recap)
Recall from the last homework, we consider the grammar that describes the valid syntax of a regular expression.

```math
\begin{array}{rccl} 
{\tt (RegularExpression)} & r & ::= & r+r \mid r.r \mid r^* \mid \epsilon \mid l \mid \phi \\ 
{\tt (Letter)} & l & ::= & a \mid b \mid ... \\ 
{\tt (Word)} & w & ::= & lw \mid \epsilon
\end{array}
```

where 

* $r_1+r_2$ denotes a choice of $r_1$ and $r_2$.
* $r_1.r_2$ denotes a sequence of $r_1$ followed by $r_2$.
* $r^*$ denotes a kleene's star, in which $r$ can be repeated 0 or more times.
* $\epsilon$ denotes an empty word, (i.e. empty string)
* $l$ denotes a letter symbol
* $\phi$ denotes an empty regular expression, which matches nothing (not even the empty string).

A word $w$ is a sequence of letter symbols. We write $\epsilon$ to denote an empty word. Note that for all word $w$, we have $w \epsilon = w = \epsilon w$

The syntatic rules of regular expression language can be easily modeled using Algebraic datatype. You may find the given codes in the project stub.

## Derivative (Recap)
And recall that in the last homework, we implemented a simple word matcher for regular expression using the derivative operation.

The derivative a regular expression $r$ with respect to a letter $l$ is a regular expression defined as follows

```math
\begin{array}{rcl}
deriv(\phi, l) & = & \phi \\ \\
deriv(\epsilon, l) & = & \phi \\ \\
deriv(l_1, l_2) & = & \left \{
    \begin{array}{ll}
    \epsilon & {if\ l_1 = l_2} \\ 
    \phi & {otherwise}
    \end{array}
    \right . \\ \\
deriv(r_1+r_2, l) & = & deriv(r_1, l) + deriv(r_2, l) \\ \\
deriv(r_1.r_2, l) & = & \left \{
    \begin{array}{ll}
    deriv(r_1,l).r_2 + deriv(r_2,l) & {if\ eps(r_1)} \\
    deriv(r_1,l).r_2 & {otherwise}
    \end{array} \right . \\ \\ 
deriv(r^*, l) & = & deriv(r,l).r^*
\end{array}
```

Where $eps(r)$ tests whether $r$ possesses the empty word $\epsilon$.

```math
\begin{array}{rcl}
eps(r_1+r_2) & = & eps(r_1)\ \vee eps(r_2) \\
eps(r_1.r_2) & = & eps(r_1)\ \wedge eps(r_2) \\ 
eps(r^*) & = & true \\ 
eps(\epsilon) & = & true \\ 
eps(l) & = & false \\ 
eps(\phi) & = & false 
\end{array}
```

We can define $match(w,r)$ in terms of $deriv(\_,\_)$. 

```math
match(w,r) = \left \{
    \begin{array}{ll}
    eps(r) & {if\ w = \epsilon} \\ 
    match(w', deriv(r,l)) & {if\ w = lw'}
    \end{array} 
    \right .
```



## Correspondence to State Machine

Recall from one of our freshmore module DDW, that a state machine consists a set of states and a set of transitions. 

We could use the following Haskell algebraic data type to describe a state machine.

```hs
data StateMachine s l = StateMachine {
    start     :: s,  
    step      :: s -> l -> Maybe (StateMachine s l), 
    isFinal   :: s -> Bool 
}
```
The datatype `StateMachine` has two type arguments, `s` denotes the state type, and `l` denote the symbol type (e.g. `Char`). 
There are three three members of the data type. `start` defines the start state, `isFinal` checks whether the given state is a final state.
the function `step` defines the transition from one state to another via a symbol. 
Rightfully, `step` should have type `s -> l -> Maybe s`. In the context of pure functional language like Haskell, 
we would like to return a new state machine datatype so that we can acess the `step` and `isFinal` methods in the returned result.

We can define the following function to run a state machine over a list of symbols.

```hs
runStateMachine :: StateMachine s l -> [l] -> Bool 
runStateMachine (StateMachine curr _ isFinal) []  = isFinal curr
runStateMachine (StateMachine curr step _) (l:ls) =
    case step curr l of 
        Nothing   -> False 
        Just stm' -> runStateMachine stm' ls 
```

It is well known that the set of strings (language) described by a regular expression can be accepted by a state machine. 
There are many existing algorithms that convert a regular expression into an equivalent state machine.

There several reasons why we would need such a conversion. 
1. To estabalish the correspondence between the regular expression and the equivalant  state machine. 
2. To optimize the matching operation, for instance, the `match` function defined using the derivative operation is not too efficient because for each input symbol, we need to use it to navigate through the syntax tree structure of the regular expression (derivative) to compute the next regular expression (derivative). These navigation can be pre-computed and cached in a lookup table.


## Task 0
Copy the your solutions of `eps`, `deriv` and `wordMatch` from the last homework to this homework. 

## Task 1 

In this task, you need to define a function to show that there exists a correspondence between regular expression and the state machine. 
Complete the function `mkSimpleSM` by defining the helper function `stepImpl`. 


### Hint: 
Out of the three functions defined for regular expression derivative matching in the last homework, which two can be used to implement `step` and `isFinal`?

### Test cases
Your code should pass the test items with "test: runStateMachine..."


## Task 2 


In this task and the next task, we are going to implement a conversion algorithm which produces a more efficient state machine.

As we mentioned earlier, the idea is to pre-compute (compile) all the possible transitions of the given regular expression before the actual execution (with the input words). In order to do that, we have to ensure that there finitely many transitions. Assuming the set of symbols is finite, having a set of finite states implies that the set of transitions is also finite. 

From the previous tasks, we know that the symbols of the state machine must be the same the letters in the regular expression, the regular expression (derivatives) are mostly likely the states in the state machine we are looking for. The question is "is the set of regular expression derivatives finite?"

Let's consider the following example. 

```math
\begin{array}{ll}
deriv(a^*.a^*, a) & = \\
deriv(a^*,a).a^* + deriv(a^*,a) & = \\ 
deriv(a,a).a^*.a^* + deriv(a, a).a^* & = \\ 
\epsilon.a^*.a^* + \epsilon.a^*  
\end{array}
```

And if we apply derivative operation to the above result

```math
\begin{array}{ll}
deriv(\epsilon.a^*.a^* + \epsilon.a^*, a) & = \\
deriv(\epsilon.a^*.a^*, a) + deriv(\epsilon.a^*, a) & = \\
deriv(\epsilon, a).a^*.a^* + deriv(a^*.a^*, a) + deriv(\epsilon, a).a^* + deriv(a^*, a) & =  \\ \phi.a^*.a^* + \epsilon.a^*.a^* + \epsilon.a^*  +  + \phi.a^* + \epsilon.a^*
\end{array}
```

As we can observe that the structure of the regular expression increases as we apply derivative operation. 
If we were to continue to repeat the process, we will encounter infinitely many regular expression derivatives.

As pointed out by Brzozoswki, the set of derivative descendants of a regular expression can be finite if we apply some simplification.

We note that the following equations among regular expressions hold.

```math
\begin{array}{rcl}
\epsilon.r & = & r \\
\phi.r & = & \phi \\
r + r & = & r \\ 
(r_1 + r_2) + r_3 & = & r_1 + (r_2 + r_3) \\ 
(r_1 . r_2) . r_3 & = & r_1. (r_2. r_3) \\  
r_1 + r_2 & = & r_2 + r_1 
\end{array}
```

For simplification purpose, we can apply the first three equiations in the direction of left to right to shrink the size of regular expressions. (We could have included more, e.g. $r.\epsilon = r$. However as noted by some earlier work, these three rules are sufficient. )

For the last three equations, we can't apply them directly to reduce the size of the regular expressions. However, we make use of them to "normalize" the regular expression nested structure so that, it is easier for us to apply the first three simplification rules.


### Task 2.1 - Testing of Epsilon and Phi

To apply the first two simplification rules, we can take advantage of the leading $\epsilon$ and $\phi$. However not all the regular expression would have this pattern trivially. We need some extra rules to identify $\epsilon$ and $\phi$ sub-expressions. 

We consider the following functions $isEps(r)$ tests whether the given $r \equiv \epsilon$, i.e. ${\cal L}(r) = {\cal L}(\epsilon)$, and $isPhi(r)$ test whether the given $r \equiv \phi$. (Note: `isEps` and `eps` are two different functions.)

```math
\begin{array}{rcl}
isEps(\epsilon) & = & true \\ 
isEps(r_1 + r_2) & = & isEps(r_1) \wedge isEps(r_2) \\
isEps(r_1.r_2) & = & isEps(r_1) \wedge isEps(r_2) \\
isEps(r^*) & = & isEps(r) \vee isPhi(r) \\ 
isEps(l) & = & false \\ 
isEps(\phi) & = & false \\ \\ 
isPhi(\epsilon) & = & false \\ 
isPhi(r_1 + r_2) & = & isPhi(r_1) \wedge isPhi(r_2) \\
isPhi(r_1. r_2) & = & isPhi(r_1) \vee  isPhi(r_2) \\
isPhi(r^*) & = & false \\ 
isPhi(l) & = & false \\ 
isPhi(\phi) & = & true 
\end{array}
```


Your task is to implement the $isEps$ and $isPhi$ functions in Haskell.

### Test Cases

Your code should pass the test items with "test: isEps..." 
and "test: isPhi..."



### Task 2.2 - Normalizing Choice

In this task, we would like to exploit the 3rd, the 4th and the last simplifcation equations we mentioned earlier to normalize and simplify choice regular expression. 

Let's reconsider the last simplifcation rule.

```math
r_1 + r_2 = r_2 + r_1
```

we could apply this equation from left to right or right to left. However, to avoid non-termination, we should fix one. To do so, it might better to impose a specific order among regular expression. Let's say on the top level

```math
 \phi < \epsilon < l  < r_1+r_2 < r_3.r_4 < r_5*
```

The ordering between two letters, can be determined by their alphabetic or ascii ordering, e.g. $a < b$.

For choice, sequence and kleene's star, we compare the sub-expressions when two regular expressions are equal at the top level.

```math
\begin{array}{rc}
{\tt (OChoice1)} & 
               \begin{array}{c} 
               r_1 < r_3   \\
               \hline
               r_1 + r_2 < r_3 + r_4   
               \end{array} \\ \\
{\tt (OChoice2)} & 
               \begin{array}{c} 
               r_2 < r_4   \\
               \hline
               r + r_2 < r + r_4   
               \end{array} \\ \\ 
{\tt (OSeq1)} & 
               \begin{array}{c} 
               r_1 < r_3   \\
               \hline
               r_1. r_2 < r_3 . r_4   
               \end{array} \\ \\ 
{\tt (OSeq2)} & 
               \begin{array}{c} 
               r_2 < r_4   \\
               \hline
               r . r_2 < r . r_4   
               \end{array} \\ \\  
{\tt (OStar)} & 
               \begin{array}{c} 
               r_1 < r_2   \\
               \hline
               r_1^* < r_2^*   
               \end{array} 
\end{array}
```

Complete the type class instance definition of `Order RE` given in the project stub. (Recall that `Ord` is a predefined type class in Haskell.)


### Test cases

Your code should pass the test items with "test: compare..." 


## Task 2.3 - Removing duplicate choice alternatives

Given that the order among regular expression is fixed, we can normalize choice regular expression

```hs
norm :: RE -> RE
norm = mkChoice . normChoice

normChoice :: RE -> [RE]
normChoice (Choice r1 r2) =
    let nr2 = normChoice r2
        nr1 = normChoice r1
    in rmdup (sort (nr1 ++ nr2))
normChoice r = [normSeq r]


rmdup :: [RE] -> [RE]
rmdup = undefined -- fix me 

mkChoice :: [RE] -> RE
mkChoice []     = Phi 
mkChoice [r]    = r 
mkChoice (r:rs) = Choice r (mkChoice rs)

normSeq :: RE -> RE 
normSeq (Seq (Seq r11 r12) r2) = normSeq (Seq r11 (Seq r12 r2))
normSeq (Seq r1 r2)            = Seq r1 (normSeq r2) 
normSeq r                      = r 
```

The `norm` function normalizes a regular expression `r` by applying `normChoice`. 
`normChoice` sorts alternatives from a choice regular expression and put them in a list. e.g. 

```hs 
normChoice (Choice(Letter 'c') (Choice (Letter 'a') (Letter 'c')))
``` 

yields 

```hs 
[Letter 'a', Letter 'c', Letter 'c']
``` 

`mkChoice` turns list of regular expression alternatives back to a 
choice regular expression, e.g. 

```hs 
mkChoice [Letter 'a', Letter 'c', Letter 'c']
``` 
yields

```hs 
Choice (Letter 'a')  (Choice (Letter 'c') (Letter 'c'))
``` 

`normSeq` normalizes a sequence regular expression according to the 5th simplification equation. 

Note that `rmdup` function is left unfinished, which is supposed to take a list of sorted regular expression alternatives, and to remove the duplication, e.g. 

```hs 
rmdup [Letter 'a', Letter 'c', Letter 'c']
``` 

should produce

```hs 
[Letter 'a', Letter 'c']
```

Your task is the complete the `rmdup` function. 

### Test cases

Your code should pass the test case "test: norm..."


## Task 2.4 - Simplification

With all the helper functions in place, we are going to implement the simplification function.

```hs
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
        else simp r'```
```

Function `simp1` apply simplification rules (the 6 equations) by making use of `isPhi`, `isEps`, `norm` functions. Function `simp` keeps applying `simp1` to the given regular expression until there is no more simplification rules applicable. 

Your task is to complete the unfinished `simp1` function.

### Test cases

Your code should pass the test cases with "test: simp ..."

### Task 2.5 - compiling 


With the simplication function, we next look at the regular-expression-to-state-machine compilation. 

Firstly we need to define a `sigma` function which extracts all the letters from the given regular expression.

```hs
sigma :: RE -> DS.Set Char
sigma (Choice r1 r2) = sigma r1 `DS.union` sigma r2
sigma (Seq r1 r2)    = sigma r1 `DS.union` sigma r2
sigma (Star r)       = sigma r 
sigma (Letter l)     = DS.singleton l 
sigma Epsilon        = DS.empty
sigma Phi            = DS.empty 
```

Secondly, we define a `build` function which applies derivative and simplication to extract all the possible transitions.

```hs
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
```


Finally, we define a `compile` function which leverages the `sigma` and the `build` functions to compile a regular expression into a state machine, where states are collected from all the derivatives and mapped to unique integers. Transitions are stored in a `Map (Int, Char) Int` look-up table, whose key is `(Int, Char)`, namely, the source state and symbol,  and the value is `Int`, i.e. the target stae. A `Map k v` object in Haskell is similar to a python dictionary, where `k` is the key type. and `v` is the value type. Given `Map key val` object `m` and a key `k`, `lookup k m` returns an `Maybe val` result. When the key is present, `Just v` will be returned, otherwise `Nothing`.
> Fore more details in how to use Map data type in Haskell, please refer to <https://hackage.haskell.org/package/containers-0.4.0.0/docs/Data-Map.html>

```hs
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
```

Complete the missing parts in the above `compile` function. 

Finally, the `mkEfficientSM` function makes use of the `compile` function to build an efficient state machine. 

```hs
mkEfficientSM :: RE -> StateMachine Int Char
mkEfficientSM r = 
    case compile r of 
        (delta, final) -> 
            let isFin i = i `DS.member` final
                stepImpl i l = case DM.lookup (i,l) delta of 
                    Nothing -> Nothing 
                    Just j  -> Just (StateMachine j stepImpl isFin) 
            in StateMachine 0 stepImpl isFin
```


### Test cases

Your code should pass all the test cases with "test: runStateMachine (mkEfficientSM  ... )"
