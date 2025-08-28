% Semantic Analysis

# Lambda Calculus 

In the cohort problems, we implemented the big step operational semantics for lambda calculus and the type checking algorithm for simply typed lambda calculus. 

In this home work, you are tasked to implement the small step operational semantics for lambda calculus and algorithm W. (If you have time in the future to implement a parser, you will have an interpretor for lambda calculus implemented!)

## Syntax and Meta Syntax

```math
\begin{array}{rccl}
 {\tt (Lambda\ Terms)} & t & ::= & x \mid \lambda x.t \mid t\ t \mid let\ x =\ t\ in\ t \mid  if\ t\ then\ t\ else\ t \mid t\ op\ t \mid c \mid fix\ t \\
 {\tt (Builtin\ Operators)} & op & ::= & + \mid - \mid * \mid / \mid\ == \\
 {\tt (Builtin\ Constants)} & c & ::= & 0 \mid 1 \mid ... \mid true \mid false \\
 {\tt (Types)} & T & ::= & int \mid bool \mid T \rightarrow T \mid \alpha \\ 
 {\tt (Type Scheme)} & \sigma & ::= & \forall \alpha. T \mid T \\ 
 {\tt (Type\ Environments)} & \Gamma & \subseteq & (x \times \sigma ) \\
 {\tt (Type\ Substitution)} & \Psi & ::= & [T/\alpha] \mid [] \mid \Psi \circ \Psi 
\end{array}
```

## Task 1 - Small Step Operational Semantics

Recall the Small Step Operational Semantics for Lambda Calculus are defined as follows,

```math
\begin{array}{rc}
{\tt (NOR)} & \begin{array}{c}
                t_1 \longrightarrow t_1' \\ \hline
                t_1\ t_2 \longrightarrow t_1'\ t_2
                \end{array}  \\ \\
{\tt (\beta\ reduction)} & (\lambda x.t_1)\ t_2 \longrightarrow [t_2/x] t_1
\\ \\
{\tt (ifI)} & 
  \begin{array}{c} 
    t_1 \longrightarrow t_1'  \\ \hline
    if\ t_1\ then\ t_2\ else\ t_3 \longrightarrow if\ t_1'\ then\ t_2\ else\ t_3 
  \end{array} \\  \\
{\tt (ifT)} &  if\ true\ then\ t_2\ else\ t_3 \longrightarrow t_2 \\ \\
{\tt (ifF)} &  if\ false\ then\ t_2\ else\ t_3 \longrightarrow t_3  \\ \\
{\tt (OpI1)} & \begin{array}{c} 
                t_1 \longrightarrow t_1' \\ \hline 
                t_1\ op\ t_2\  \longrightarrow t_1'\ op\ t_2 
                \end{array} \\ \\
{\tt (OpI2)} & \begin{array}{c} 
                t_2 \longrightarrow t_2' \\ \hline 
                c_1\ op\ t_2\  \longrightarrow c_1\ op\ t_2' 
                \end{array} \\ \\
{\tt (OpC)} &  \begin{array}{c} 
                invoke\ low\ level\ call\  op(c_1, c_2) = c_3 \\ \hline  
                c_1\ op\ c_2\  \longrightarrow c_3 
                \end{array} \\ \\
{\tt (Let)} & let\ x=t_1\ in\ t_2 \longrightarrow [t_1/x]t_2 \\ \\
{\tt (Fix1)} & \begin{array}{c}
               t \longrightarrow t' \\ \hline
               fix\ t \longrightarrow fix\ t'
               \end{array}  \\ \\ 
{\tt (Fix2)} &  fix\ \lambda f.t \longrightarrow \lbrack (fix\ \lambda f.t)/f \rbrack t
\end{array}
```

Rule ${\tt (Fix1)}$ evaluates the argument of $fix$ operator by a step, until it becomes a lambda abstraction.
Rule ${\tt (Fix2)}$ "unfold" the fixed point function $\lambda f.t$, by subsituting occurences of $f$ in $t$ by $fix\ \lambda f.t$.

and free variable extraction function

```math
\begin{array}{rcl}
fv(x) & = & \{x\}\\
fv(\lambda x.t) & = & fv(t) - \{x\} \\ 
fv(t_1\ t_2) & = & fv(t_1) \cup fv(t_2)  \\ 
fv(let\ x=t_1\ in\ t_2) & = & (fv(t_1) - \{x\}) \cup fv(t_2) \\
fv(if\ t_1\ then\ t_2\ else\ t_3) & = & fv(t_1) \cup fv(t_2) \cup fv(t_3) \\
fv(c) & = & \{\} \\ 
fv(t_1\ op\ t_2) & = & fv(t_1) \cup fv(t_2) \\ 
fv(fix\ t) & = & fv(t)
\end{array}
```

and substitution operation

```math
\begin{array}{rcll}
 \lbrack t_1 / x \rbrack c & = & c \\ 
 \lbrack t_1 / x \rbrack x & = & t_1 \\
 \lbrack t_1 / x \rbrack y & = & y & {\tt if}\  x \neq y \\
 \lbrack t_1 / x \rbrack (t_2\ t_3) & = & \lbrack t_1 / x \rbrack t_2\ 
 \lbrack t_1 / x \rbrack t_3 & \\
 \lbrack t_1 / x \rbrack \lambda y.t_2 & = & \lambda y. \lbrack t_1 / x
 \rbrack t_2 & {\tt if}\  y\neq x\  {\tt and}\  y \not \in fv(t_1) \\ 
 \lbrack t_1 / x \rbrack let\ y = t_2\ in\ t_3 & = & let\ y = \lbrack t_1 / x \rbrack t_2\ in\ \lbrack t_1 / x \rbrack t_3 & {\tt if}\  y\neq x\  {\tt and}\  y \not \in fv(t_1) \\ 
  \lbrack t_1 / x \rbrack if\ t_2\ then\ t_3\ else\ t_4 & = & if\ \lbrack t_1 / x \rbrack t_2\ then\ \lbrack t_1 / x \rbrack t_3\ else\ \lbrack t_1 / x \rbrack t_4 \\ 
  \lbrack t_1 / x \rbrack t_2\ op\ t_3 & = & (\lbrack t_1 / x \rbrack t_2)\ op\ (\lbrack t_1 / x \rbrack t_3) \\ 
  \lbrack t_1 / x \rbrack (fix\ t_2) & = & fix\ \lbrack t_1 / x \rbrack t_2 &  
\end{array}
```

Some of the operations (such as substitution),  which we have implemented in Big Step Evaluation operational semantics,  can be reused in this task. We moved them into a separate package `Util.hs`.

Small Step operational semantics are implemented in `SmallStepEval.hs`. Your task is to complete the missing cases in 
`evalOneStep`.

When you are done, you should be able to pass all the test cases in `SmallStepEvalSpec.hs`


## Task 2 - Unification

Recall the type inference algorithm for Lambda Calculus *Algorithm W* requires the following helper functions.

The type variable function $ftv()$ can be defined similar to the $fv()$ function we introduced for lambda caculus. 

```math
\begin{array}{rcl}
ftv(\alpha) & = & \{\alpha \} \\ 
ftv(int) & = & \{ \} \\
ftv(bool) & = & \{ \} \\
ftv(T_1 \rightarrow T_2) & = & ftv(T_1) \cup ftv(T_2) \\
ftv(\forall \alpha.\sigma) & = & ftv(\sigma) - \{ \alpha \} 
\end{array}
```

$ftv$ is also overloaded to extra free type variables from a type environment.

```math
\begin{array}{rcl}
ftv(\Gamma) & = & \{ \alpha \mid (x,\sigma) \in \Gamma \wedge \alpha \in ftv(\sigma) \}
\end{array}
```


The application of a type substitution can be defined as 

```math
\begin{array}{rcll}
[] \sigma & = & \sigma \\ 
[T/\alpha] int & = & int \\
[T/\alpha] bool & = & bool \\ 
[T/\alpha] \alpha & = & T \\
[T/\alpha] \beta & = & \beta & \beta \neq \alpha \\ 
[T/\alpha] T_1 \rightarrow T_2 & = & ([T/\alpha] T_1) \rightarrow ([T/\alpha] T_2) \\ 
[T/\alpha] \forall \beta. \sigma & = & \forall \beta. ([T/\alpha]\sigma) & \beta \neq \alpha \wedge \beta \not \in ftv(T) \\ 
(\Psi_1 \circ \Psi_2)\sigma & = & \Psi_1 (\Psi_2 (\sigma))
\Psi(\Gamma)  &= & \{ (x,\Psi(\sigma)) \mid (x,\sigma) \in \Gamma \}
\end{array}
```

Type Scheme Instantiation

```math
\begin{array}{rcl}
inst(T) & = & T \\
inst(\forall \alpha.\sigma) & = & \lbrack\beta_1/\alpha\rbrack(inst(\sigma))\ where\ \beta_1=newvar \\
\end{array}
```

Type generalization operation

```math
\begin{array}{rcl}
gen(\Gamma, T) & = & \forall \overline{\alpha}.T\ \ where\ \overline{\alpha} = ftv(T) - ftv(\Gamma)
\end{array}
```

Type Unification

```math
\begin{array}{rcl}
mgu(\alpha, T) & = & [T/\alpha] \\ 
mgu(T, \alpha) & = & [T/\alpha] \\ 
mgu(int, int) & = & [] \\ 
mgu(bool, bool) & = & [] \\ 
mgu(T_1 \rightarrow T_2 , T_3\rightarrow T_4) & = & let\ \Psi_1 = mgu(T_1, T_3)\ \\ 
&  & in\ \ let\ \Psi_2 = mgu(\Psi_1(T_2), \Psi_1(T_4)) \\
&  & \ \ \ \ \ in\ \Psi_2 \circ \Psi_1
\end{array}
```

Most of these helper functions have been implemented and given, except for $mgu$. Your task is to complete the `mgu` function implementation in `AlgorithmW.hs`.

When you are done, your code should be able to pass the following test cases with "test mgu: ..."


## Task 3 - Algorithm W

Recall the Algorthm W is defined as follows,

```math
\begin{array}{rc}
{\tt (wInt)} & \begin{array}{c}
                c\ {\tt is\ an\ integer} 
                \\ \hline 
               \Gamma, c \vDash int, [] 
               \end{array} \\ \\
{\tt (wBool)} & \begin{array}{c}
                c\in \{true,false \} 
                \\ \hline 
               \Gamma, c \vDash bool, [] 
               \end{array} \\ \\ 
{\tt (wVar)} & \begin{array}{c}
                (x,\sigma) \in \Gamma \ \ \ inst(\sigma) = T
                \\ \hline 
               \Gamma, x \vDash T, [] 
               \end{array} \\ \\
{\tt (wFix)} & \begin{array}{c}
                (fix,\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha) \in \Gamma \ \ \ inst(\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha) = T
                \\ \hline 
               \Gamma, fix \vDash T, [] 
               \end{array} \\ \\ 
{\tt (wLam)} & \begin{array}{c}
                \alpha_1 = newvar \ \ \ \Gamma \oplus (x,\alpha_1), t \vDash T, \Psi
                \\ \hline
                \Gamma, \lambda x.t \vDash : \Psi(\alpha_1 \rightarrow T ), \Psi
                \end{array} \\ \\ 
{\tt (wApp)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1\ \ \ \ \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2\ \ \\ \alpha_3 = newvar\ \ \ \Psi_3 = mgu(\Psi_2(T_1), T_2 \rightarrow \alpha_3) 
                \\ \hline
                \Gamma, (t_1\ t_2) \vDash \Psi_3(\alpha_3), \Psi_3 \circ \Psi_2 \circ \Psi_1 
               \end{array} \\ \\ 
{\tt (wLet)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1 \\ \Psi_1(\Gamma) \oplus (x, gen(\Psi_1(\Gamma), T_1)), t_2 \vDash T_2, \Psi_2
                \\ \hline
                \Gamma, let\ x=t_1\ in\ t_2 \vDash T_2, \Psi_2 \circ \Psi_1
             \end{array} \\ \\ 
{\tt (wOp1)} & \begin{array}{c}
                op \in \{+,-,*,/\} \\ 
                \Gamma, t_1 \vDash T_1, \Psi_1 \ \ \ \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2 \\ 
                mgu(\Psi_2(T_1), T_2, int) = \Psi_3   
                \\ \hline 
                \Gamma, t_1\ op\ t_2 \vDash int, \Psi_3 \circ \Psi_2 \circ \Psi_1 
                \end{array} \\ \\ 
{\tt (wOp2)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1 \ \ \ \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2 \\ 
                mgu(\Psi_2(T_1), T_2) = \Psi_3   
                \\ \hline 
                \Gamma, t_1\ ==\ t_2 \vDash bool, \Psi_3 \circ \Psi_2 \circ \Psi_1 
                \end{array} \\ \\ 
{\tt (wIf)} & \begin{array}{c}
                \Gamma, t_1 \vDash T_1, \Psi_1\ \ \
                \Psi_1' = mgu(bool, T_1) \circ \Psi_1 \\
                \Psi_1'(\Gamma),t_2 \vDash T_2, \Psi_2 \ \ \
                \Psi_1'(\Gamma),t_3 \vDash T_3, \Psi_3 \\
                \Psi_4 = mgu(\Psi_3(T_2), \Psi_2(T_3)) 
                \\ \hline
                \Gamma, if\ t_1\ then\ t_2\ else\ t_3 \vDash \Psi_4(\Psi_3(T_2)),  \Psi_4 \circ \Psi_3 \circ \Psi_2 \circ \Psi_1'
              \end{array}
\end{array}
```


Note that in our implementation, $fix\ t$ is parsed as a special term `FixTerm(t)` instead of `AppTerm(fix, t)`. We adopt the above algorithm 
by fusing $(\tt wFix)$ and $(\tt wApp)$ rules into the following single rule, and removing  the $(\tt wFix)$ rule from our implementation.

```math
\begin{array}{rcl}
{\tt (wFixApp)} & \begin{array}{c}
                (fix,\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha) \in \Gamma \\ 
                inst(\forall \alpha. (\alpha\rightarrow \alpha)\rightarrow \alpha) = T_1 \ \ \ \ \Psi_1 = []
                \\ 
                \Psi_1(\Gamma), t_2 \vDash T_2, \Psi_2\ \ \\ \alpha_3 = newvar\ \ \ \Psi_3 = mgu(\Psi_2(T_1), T_2 \rightarrow \alpha_3) 
                \\ \hline
                \Gamma, (fix\ t_2) \vDash \Psi_3(\alpha_3), \Psi_3 \circ \Psi_2 \circ \Psi_1 
               \end{array} 
\end{array}
```

Your task is to complete the implementation of `typeInf` in `AlgorithmW.hs`.

When you are done, your code should pass the remaining test cases in `AlgorithmWSpec.hs`

