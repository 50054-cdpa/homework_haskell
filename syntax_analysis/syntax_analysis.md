% syntax analysis

# Parsing Regular expression 
In this homework, you are tasked to develop a lexer and a parser for a regular expression. 

Besides the Haskell code for Task 3, you should submit a report which should include detail steps of solving Task 1 and Task 2.

## Task 0

Copy the `RegExp.hs` solution source code from your last assignment and overwrite the one in `src/SUTD/Compiler/`. 


# Regular Expression Parsing

The Regular Expression Syntax is defined as follows 

```
  (Regular Expression) R ::= [C-C] || [CC] || [] || C || R|R || R* || R? || RR || (R) 
  (Character) C ::= a || ... || z || 1 || ... || 0
```

Since `|` is part of the syntax, we use `||` to represent the alternative in EBNF

The set of characters should includes upper case characters, however to avoid confusing with the non-terminal, we drop them for now.

## Task 1

Eliminate the Left recursion from the above language, if there is any.

**No submission is required** for this task, the answer is given in Task 2.

## Task 2

Given the grammar with left-recursion eliminated, `<<grammar 1>>`

```
R ::= (R)S || [C-C]S || [CC]S || []S || CS 
S ::= |RS || *S || ?S || RS || eps 
C ::= a || ... || z ||  1 || ... || 0
```

Apply Left factorization to the above grammar.

**No submission is required** for this task, the answer is given in Task 3

## Task 3 

```
R ::= (R)S || CS || [T 
T :: = CU || ]S 
U ::= -C]S || C]S
S ::= |RS || *S || ?S || RS || eps 
C ::= a || ... || z || 1 || ... || 0 
```

Given the grammar after applying left factorization, `<<grammar 2>>`

Show that the resulting grammar `<<grammar 2>>` is `LL(1)`.

Explain your answer in the `task3_answer.md`. 

For simplicity, you may treat `C` has only one alternative i.e. `C ::= a`

## Task 4

Complete the code in `Parser.hs` to implement the top-down parser using Monadic Parser Combinator.  You must use the on-demand backtracking parsec library `Parsec.hs`.
The lexer `Lexer.hs` included in the project stub code is a good reference, which you don't need to modify. Since the resulting grammar is in `LL(1)` there is no need to use `attempt`.

After completing this task your code should be able to compile and pass the test cases in `ParserSpec.hs`
