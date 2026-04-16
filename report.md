#  Mini C-Compiler (Toy-C) – Detailed Project Report

**Course:** Compiler Design Lab  
**Project Title:** Compiler for Toy-C  
**Submission Date:** April 16, 2026  
**Group Members:**
* Prince Goyal - 2301158
* Shikhar Shashank - 2301199

---

## 1. Compiler Architecture Overview

In this project, we designed and implemented simplified subset of the C language (Toy-C). 
We structured our compiler into **three major layers**:

### Front-End
* Lexical Analysis (Tokenization)
* Syntax Analysis (Parsing)

### Middle-End
* Semantic Analysis
* Intermediate Code Generation (TAC)
* Optimization

### Back-End
* Target Code Generation (MIPS Assembly)

We followed a **Syntax Directed Translation (SDT)** approach, meaning:

> We generate intermediate code during parsing itself rather than as a separate step.

---

## 2. Overall Flow

```
Source Code
   ↓
Lexical Analysis -> Tokens
   ↓
Syntax Analysis -> Parse Tree
   ↓
Semantic Analysis -> Checked AST + Symbol Table
   ↓
Intermediate Code (TAC)
   ↓
Optimized TAC
   ↓
MIPS Assembly Code
```

---

## 3. Language Features Supported 

We intentionally restricted the language to keep implementation manageable but meaningful:

###  Data Types
* `int`
* `float`

###  Expressions
* Arithmetic: `+ - * / ++ --`
* Relational: `< > == != <= >=`

###  Statements
* Assignment (`a = b + c`)
* Conditional (`if-else`)
* Loop (`while` / `for` equivalent logic)

---

## 4.  Phase 1: Lexical Analysis

###  Goal
Convert raw source code into **tokens**.

###  Implementation
* Implemented using **Lex (.l file)**

###  What we detect
* Keywords -> `int`, `if`, `else`, `while`, `for`
* Identifiers -> variable names
* Operators -> `+ - * / == != < > >= <=`
* Numbers -> integers

###  Important behavior
* Ignores whitespace and comments
* Tracks line numbers using `yylineno`

###  Error Handling
* Invalid characters -> immediate error with line number

---

## 5.  Phase 2: Syntax Analysis

###  Goal
Check whether token sequence follows grammar rules.

###  Implementation
* Built using **Yacc (.y file)**
* Uses **LALR(1) parsing**


## Core Grammar

We define the syntax of our Toy-C language using CFG 
The grammar below closely follows our Yacc-based implementation.

---
```

### 1. Program Structure

programme -> headers main_func

headers -> headers INCLUDE_STMT
        | ε

main_func -> INT VAR ( ) { statements }

---

### 2. Statements

statements -> statements statement
           | ε

statement -> declaration
          | assign_expr ;
          | expr ;
          | if_stmt
          | while_stmt
          | for_stmt
          | return_stmt
          | block
          | ;

block -> { statements }

---

### 3. Declarations

declaration -> INT int_var_list ;
            | FLOAT float_var_list ;

int_var_list -> int_var_decl
             | int_var_list , int_var_decl

int_var_decl -> VAR
             | VAR = expr

float_var_list -> float_var_decl
               | float_var_list , float_var_decl

float_var_decl -> VAR
               | VAR = expr

---

### 4. Assignment Expressions

assign_expr -> VAR = expr
            | VAR += expr
            | VAR -= expr

---

### 5. Conditional Statements

if_stmt -> IF ( condition ) statement
        | IF ( condition ) statement ELSE statement

---

### 6. Loop Statements

while_stmt -> WHILE ( condition ) statement

for_stmt -> FOR ( for_init ; condition ; for_update ) statement

for_init -> assign_expr
         | expr
         | INT int_var_list
         | FLOAT float_var_list
         | ε

for_update -> assign_expr
           | expr
           | ε

---

### 7. Conditions (Boolean Expressions)

condition -> condition AND condition
          | condition OR condition
          | NOT condition
          | ( condition )
          | expr

---

### 8. Expressions

expr -> VAR
     | NUM
     | FLOAT_NUM
     | - expr
     | expr + expr
     | expr - expr
     | expr * expr
     | expr / expr
     | ( expr )

---

### 9. Increment / Decrement Operations

expr -> VAR++
     | VAR--
     | ++VAR
     | --VAR

---

### 10. Relational Expressions

expr -> expr == expr
     | expr != expr
     | expr > expr
     | expr < expr
     | expr >= expr
     | expr <= expr

---

### 11. Return Statement

return_stmt -> RETURN expr ;

---

### 12. Terminals (Tokens)

Identifiers:
VAR -> variable names

Constants:
NUM -> integer constant  
FLOAT_NUM -> floating point constant  

Keywords:
INT, FLOAT, IF, ELSE, WHILE, FOR, RETURN

Operators:
+, -, *, /, ==, !=, >, <, >=, <=, =, +=, -=, ++, --

Logical Operators:
AND, OR, NOT

Symbols:
; , ( ) { }

```

### Notes

1. The grammar is implemented using Yacc (LALR(1) parser).
2. Operator precedence and associativity are handled using Yacc directives.
3. Backpatching is used for control flow (if, while, for).
4. The for loop is fully supported and internally translated into TAC using labels and jumps.
5. Both integer and floating-point types are supported with semantic checking.

###  Key Design Choices
* Used `%left` and `%right` for precedence
* Avoided ambiguity via operator precedence instead of deep grammar




## 6.  Phase 3: Semantic Analysis

###  Goal
Ensure **logical correctness** of program.

###  Symbol Table Design

From your implementation:

* **Stores:**
  * Variable name
  * Type
  * Scope level
  * Active status

###  Key Features we implemented

####  Variable Declaration Check
* Prevent duplicate declaration in same scope

####  Undeclared Variable Detection
* Throws error if variable used before declaration

####  Scope Handling

We implemented:
* `enter_scope()`
* `exit_scope()`

Instead of deleting variables, we:

> Mark them as inactive when leaving scope

###  Example

```c
int a;
if (...) {
   int a;   // allowed (shadowing)
}
```

### Output (Symbol Table)

```
Variable Name | Data Type | Scope Level
--------------------------------------
a             INT         0
a             INT         1
```

---

## 7. Phase 4: Intermediate Code Generation (TAC)

###  Goal
Convert code into **Three Address Code**

###  Format

```
t1 = b + c
a = t1
```

###  Implementation Highlights

From your TAC system:
* `emit()` -> add instruction
* `new_temp()` -> generate temporaries (`t1, t2`)
* `new_label()` -> generate labels (`L1, L2`)

### Backpatching

We implemented full **backpatching system**:
* `makelist()`
* `merge()`
* `backpatch()`

This is used for:
* `if`
* loops

Because:

> Jump targets are not known immediately

### Example

```c
if (a < b)
   a = b;
```

TAC:

```
t1 = a < b
ifFalse t1 goto L1
a = b
L1:
```

---

## 8. Phase 5: Optimization

We implemented **multiple optimization passes**:

###  1. Constant Folding

```
t1 = 10 + 20 -> t1 = 30
```

###  2. Constant Propagation

```
a = 30
b = a + 5 -> b = 30 + 5
```

###  3. Common Subexpression Elimination (CSE)

```
t1 = a + b
t2 = a + b -> replaced with t2 = t1
```

###  4. Dead Code Elimination

If temp not used:

```
t3 = a + b   // never used -> removed
```

###  Implementation Detail

Dead code marked as:

```
DELETED
```

and skipped during printing.

---

## 9.  Phase 6: Target Code Generation 

###  Goal
Convert TAC -> **MIPS Assembly**

###  Strategy

For each TAC instruction:
1. Load operands into registers
2. Perform operation
3. Store result back to memory

###  Memory Handling

We generate `.data` section automatically:

```
a: .word 0
t1: .word 0
```

###  Instruction Mapping

| TAC | MIPS       |
| --- | ---------- |
| +   | add        |
| -   | sub        |
| *   | mul        |
| /   | div + mflo |
| ==  | seq        |
| !=  | sne        |
| >   | sgt        |
| <   | slt        |

###  Example

#### Input

```c
a = b + c;
```

#### TAC

```
t1 = b + c
a = t1
```

#### Assembly

```
lw $t0, b
lw $t1, c
add $t2, $t0, $t1
sw $t2, t1

lw $t0, t1
sw $t0, a
```

---

## 10.  ISA Details (MIPS32 Subset)

We used a **restricted MIPS32 RISC ISA** with limited registers

###  Register Usage
* `$t0, $t1, $t2` -> temporary registers
* `$a0` -> argument (for output)
* `$v0` -> syscall control

###  Instruction Set

#### Arithmetic
* `add, sub, mul, div, mflo`

#### Comparison
* `seq, sne, sgt, slt, sge, sle`

#### Memory
* `lw, sw, li`

#### Control Flow
* `beq`
* `j`

---

We tried to keep the design:

> modular, understandable, and close to real compiler structure
