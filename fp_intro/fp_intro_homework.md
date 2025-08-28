# Homework


## Install the following softwares

1. Visual Studio Code
1. Install ghcup >= 0.1.30.0 `https://www.haskell.org/ghcup/`
1. Install ghc >= 9.6.6 (via the `ghcup tui` command)
1. Install cabal >= 3.10.3.0 (via the `ghcup tui` command)
1. (Optional) install hls >= 2.7.0.0 (via the `ghcup tui` command)
1. Install stack >= 2.15.5 (via the `ghcup tui` command)


## Install the following Extensions for Visual Studio Code

1. Haskell - Haskell language support powered by the Haskell


## Build the Haskell project using VSCode

1. It should compile automatically. If not, try to press Ctrl-shift-p (for mac Cmd-Shift-p) to restart the haskell language server. 

## Build the project using command line cabal 

1. Start a terminal. 
1. In the `fp_intro` project root folder, run `cabal build`.
1. To run the test cases, execute `cabal test` in the terminal. We should see
```
1 of 1 test suites (1 of 1 test cases) passed.
```
4. To run the main function, execute `cabal run`. We should see.
```
Hello, Haskell!
1 + 2 = 3
```
5. To start the repl for debugging run `cabal repl`.


## (Optional) Build the project using command line stack 

1. Start a terminal. 
1. In the `fp_intro` project root folder, run `stack build`.
1. To run the test cases, execute `stack test` in the terminal.  We should see 
```
Progress 1/2: fp-intro
Spec
  MyLib.foo 1 1 should be 2 [✔]

Finished in 0.0002 seconds
1 example, 0 failures
```
4. To run the main function, execute  `stack run`. You should see.
```
Hello, Haskell!
1 + 2 = 3
```
5. To start the repl for debugging run `stack repl`.

