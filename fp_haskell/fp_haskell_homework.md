% Introduction to Haskell


# Implementing Regular expression 
In this homework, you are tasked to develop a regular expression matcher using Haskell.

## Syntax
Consider the following EBNF grammar that describes the valid syntax of a regular expression.

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

## Set semantics of Regular expression

Every regular expression $r$ has a meaning, i.e. it denotes a set of strings that it can capture.

Formally speaking, the meaning of a regular expression can be defined as ${\cal L}(r)$

```math
\begin{array}{rcl}
{\cal L}(\phi) & = & \{ \} \\ 
{\cal L}(\epsilon) & = & \{ \epsilon \} \\ 
{\cal L}(l) & = & \{ l \} \\ 
{\cal L}(r_1+r_2) & = & {\cal L}(r_1) \cup {\cal L}(r_2) \\ 
{\cal L}(r_1.r_2) & = & \{ w_1w_2 \mid  w_1 \in {\cal L}(r_1) \wedge w_2 \in {\cal L}(r_2)\} \\ 
{\cal L}(r^*) & = & \{ w_1...w_n \mid w_1 \in {\cal L}(r) \wedge ... \wedge w_n \in {\cal L}(r) \}
\end{array}
```


## Word matching problem

The word matching problem of regular expression is to check whether the given input word $w$ is part of the set of strings defined by the regular expression. 

One way to solve the word match problem is to use Brzozoski's derivative operation.

The derivative of a regular expression $r$ with respect to a letter $l$ is a regular expression defined as follows

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

We can define $match(w,r)$ in terms of $deriv(\cdot,\cdot)$. 

```math
match(w,r) = \left \{
    \begin{array}{ll}
    eps(r) & {if\ w = \epsilon} \\ 
    match(w', deriv(r,l)) & {if\ w = lw'}
    \end{array} 
    \right .
```

Your task is to implement the $match$, $eps$ and $deriv$ in Haskell.

## Test cases

You may find test cases in the given project stub.
