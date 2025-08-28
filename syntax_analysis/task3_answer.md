## Task 3 answer

```
R ::= (R)S || CS || [T 
T :: = CU || ]S 
U ::= -C]S || C]S
S ::= |RS || *S || ?S || RS || eps 
C ::= a || ... || z || 1 || ... || 0 
```

expanded into 

```
(1) R  ::= (R)S 
(2) R  ::= CS
(3) R  ::= [T 
(4) T  :: = CU 
(5) T  :: = ]S 
(6) U  ::= -C]S
(7) U  ::=  C]S
(8) S  ::= |RS  
(9) S  ::=  *S  
(10) S ::= ?S  
(11) S ::= RS  
(12) S ::= eps 
(13) C ::= a
```

### Nullability


### First


### Follow


### Predictive Parsing Table

