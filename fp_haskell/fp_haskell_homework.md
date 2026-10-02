% Introduction to Haskell


# Implementing Regular expression 
In this homework, you are tasked to develop a regular expression matcher using Haskell.

## Syntax
Consider the following EBNF grammar that describes the valid syntax of a regular expression.

```math
\begin{array}{rccl} 
{\tt (RegularExpression)} & \rho & ::= & \rho+\rho \mid \rho.\rho \mid \rho{}^* \mid \epsilon \mid \lambda \mid \phi \\ 
{\tt (Letter)} & \lambda & ::= & a \mid b \mid ... \\ 
{\tt (Word)} & \omega & ::= & \lambda\omega \mid \epsilon
\end{array}
```

where 

* $\rho_1+\rho_2$ denotes a choice of $\rho_1$ and $\rho_2$.
* $\rho_1.\rho_2$ denotes a sequence of $\rho_1$ followed by $\rho_2$.
* $\rho^*$ denotes a kleene's star, in which $\rho$ can be repeated 0 or more times.
* $\epsilon$ denotes an empty word, (i.e. empty string)
* $\lambda$ denotes a letter symbol
* $\phi$ denotes an empty regular expression, which matches nothing (not even the empty string).

A word $\omega$ is a sequence of letter symbols. We write $\epsilon$ to denote an empty word. Note that for all word $\omega$, we have $\omega \epsilon = \omega = \epsilon \omega$

The syntatic rules of regular expression language can be easily modeled using Algebraic datatype. You may find the given codes in the project stub.

## Set semantics of Regular expression

Every regular expression $\rho$ has a meaning, i.e. it denotes a set of strings that it can capture.

Formally speaking, the meaning of a regular expression can be defined as ${\cal L}(\rho)$

```math
\begin{array}{rcl}
{\cal L}(\phi) & = & \{ \} \\ 
{\cal L}(\epsilon) & = & \{ \epsilon \} \\ 
{\cal L}(\lambda) & = & \{ \lambda \} \\ 
{\cal L}(\rho_1+\rho_2) & = & {\cal L}(\rho_1) \cup {\cal L}(\rho_2) \\ 
{\cal L}(\rho_1.\rho_2) & = & \{ \omega_1w_2 \mid  \omega_1 \in {\cal L}(\rho_1) \wedge \omega_2 \in {\cal L}(\rho_2)\} \\ 
{\cal L}(\rho^*) & = & \{ \omega_1...w_n \mid \omega_1 \in {\cal L}(\rho) \wedge ... \wedge \omega_n \in {\cal L}(\rho) \}
\end{array}
```


## Word matching problem

The word matching problem of regular expression is to check whether the given input word $\omega$ is part of the set of strings defined by the regular expression. 

One way to solve the word match problem is to use Brzozoski's derivative operation.

The derivative of a regular expression $\rho$ with respect to a letter $\lambda$ is a regular expression defined as follows

```math
\begin{array}{rcl}
deriv(\phi, l) & = & \phi \\ \\
deriv(\epsilon, l) & = & \phi \\ \\
deriv(\lambda_1, \lambda_2) & = & \left \{
    \begin{array}{ll}
    \epsilon & {if\ \lambda_1 = \lambda_2} \\ 
    \phi & {otherwise}
    \end{array}
    \right . \\ \\
deriv(\rho_1+\rho_2, \lambda) & = & deriv(\rho_1, \lambda) + deriv(\rho_2, \lambda) \\ \\
deriv(\rho_1.\rho_2, \lambda) & = & \left \{ 
    \begin{array}{ll}
    deriv(\rho_1,\lambda).\rho_2 + deriv(\rho_2,\lambda) & {if\ eps(\rho_1)} \\
    deriv(\rho_1,\lambda).\rho_2 & {otherwise}
    \end{array} \right . \\ \\
deriv(\rho^*, l) & = & deriv(\rho,\lambda).\rho^*
\end{array}
```

Where $eps(\rho)$ tests whether $\rho$ possesses the empty word $\epsilon$.

```math
\begin{array}{rcl}
eps(\rho_1+\rho_2) & = & eps(\rho_1)\ \vee eps(\rho_2) \\
eps(\rho_1.\rho_2) & = & eps(\rho_1)\ \wedge eps(\rho_2) \\ 
eps(\rho^*) & = & true \\ 
eps(\epsilon) & = & true \\ 
eps(\lambda) & = & false \\ 
eps(\phi) & = & false 
\end{array}
```

We can define $match(\omega,\rho)$ in terms of $deriv(\cdot,\cdot)$. 

```math
match(\omega,r) = \left \{
    \begin{array}{ll}
    eps(\rho) & {if\ \omega = \epsilon} \\ 
    match(\omega', deriv(\rho,\lambda)) & {if\ \omega = \lambda\omega'}
    \end{array} 
    \right .
```

Your task is to implement the $match$, $eps$ and $deriv$ in Haskell.

## Test cases

You may find test cases in the given project stub.

