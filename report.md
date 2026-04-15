# Project Report: Mini C-Compiler (Toy-C)

**Name:** Prince Goyal, Shikhar Shashank  
**Institution:** Indian Institute of Information Technology (IIIT), Guwahati  
**Course:** Compiler Design Lab

---

## 1. How We Built the Architecture

For this project, we built a multi-pass mini compiler that takes a basic subset of C code and translates it all the way down to MIPS32 assembly. We went with a **Syntax-Directed Translation** approach. Basically, as the parser figures out the grammar rules, it instantly spits out the intermediate code.

The whole pipeline is broken down into these **6 phases**:

1. **Lexical Analysis**: We used Lex (`lexer.l`) to chop the raw C code into tokens. It ignores spaces and comments, and we tied in `yylineno` so it tracks line numbers for error reporting.

2. **Syntax Analysis**: We used Yacc (`parser.y`) to check the grammar.

3. **Semantic Analysis**: We wrote a custom Symbol Table (`semantic.c`) that tracks variables, their data types, and their scope.

4. **Intermediate Code Gen**: As Yacc reads the math and logic, it dumps Three-Address Code (TAC) into a big array.

5. **Basic Optimization**: Before generating the final assembly, we wrote a custom script that loops through the TAC array and optimizes it to save instructions.

6. **Target Code Gen**: Finally, the compiler loops through the optimized TAC and maps every instruction to actual MIPS assembly (`codegen.c`).

---

## 2. The Parser We Used

For the parsing phase, we used **Yacc**, which automatically builds an **LALR(1)** (Look-Ahead Left-to-Right) bottom-up parser.

Because it's a **bottom-up parser**, it basically pushes tokens onto a stack until it recognizes a valid grammar rule, and then it "reduces" them. The "(1)" in LALR means it looks exactly **one token ahead** to figure out what to do. This is actually why if you forget a semicolon on line 4, the compiler will throw a syntax error on line 5—it only realizes the semicolon is missing when it reads the first word of the next line!

To handle math rules (like making sure multiplication happens before addition), we just used Yacc's built-in `%left` and `%right` precedence rules instead of writing crazy nested grammar rules.

---

## 3. The Core Grammar

Here is the core grammar our compiler understands, written out in BNF. It basically covers variable declarations, math expressions, assignments, conditionals, and loops:

```bnf
<programme>    ::= <headers> <main_func>
<main_func>    ::= INT VAR '(' ')' '{' <statements> '}'

<statements>   ::= <statements> <statement> | ε
<statement>    ::= <declaration>
                 | <assign_expr> ';'
                 | IF '(' <condition> ')' <statement> [ ELSE <statement> ]
                 | WHILE '(' <condition> ')' <statement>
                 | FOR '(' <for_init> ';' <condition> ';' <for_update> ')' <statement>
                 | RETURN <expr> ';'
                 | '{' <statements> '}'

<declaration>  ::= INT <var_list> ';'
<assign_expr>  ::= VAR '=' <expr> | VAR PLUSEQ <expr> | VAR INC | VAR DEC

<condition>    ::= <expr> EQ <expr> | <expr> GT <expr> | <expr> LT <expr> | VAR
<expr>         ::= VAR | NUM | FLOAT_NUM
                 | '-' <expr>
                 | <expr> ADD <expr> | <expr> MUL <expr>
```

---

## 4. MIPS Instructions & Registers Used

For the final code generation, we targeted a small subset of the **MIPS32 RISC** architecture.

### Registers We Used:

| Register | Purpose |
|----------|---------|
| `$t0`, `$t1` | Our main temporary registers. We load our arguments into these before doing any math. |
| `$t2` | Where we store the answer before writing it back to memory. |
| `$a0` | The standard argument register (we just use it to hold the final return value so the system can print it). |
| `$v0` | Used for system calls (printing and exiting). |
| `$zero` | Hardwired to 0. We used this a lot for branching by comparing boolean results against it. |

### Instructions We Implemented:

- **Memory**: `lw` (Load Word), `sw` (Store Word), `li` (Load Immediate for raw numbers)
- **Math**: `add`, `sub`, `mul`, `div`, and `mflo` (since MIPS division puts the quotient in a weird LO register, we had to use this to grab it)
- **Logic**: `seq` (set equal), `sne` (set not equal), `sgt` (set greater than), `slt` (set less than)
- **Branching**: `beq` (branch on equal—used for our ifFalse logic) and `j` (unconditional jump for loops)
- **System**: `syscall`

---

## 5. What Runs and What Doesn't (Features Implemented)

### ✅ What Works Perfectly:

- **Math & Precedence**: Standard BODMAS math works totally fine, including unary minus (like `x = -5`).

- **Nested Scope & Shadowing**: We are pretty proud of this one. You can declare `int a = 100` globally, and then do `int a = 5` inside an if block, and the compiler knows exactly which one to use without messing up the memory.

- **Control Flow**: Nested for loops, while loops, and if-else blocks all compile and jump to the correct labels.

- **Aggressive Optimizations**: The phase 5 optimizer actually works really well. It does:
  - **Constant Folding** (it calculates stuff like `10 + 20` at compile time so the assembly doesn't have to)
  - **Common Sub-Expression Elimination**
  - **Dead Code Elimination** (it completely deletes temporary variables that are calculated but never used)

### ❌ What Doesn't Run (Not Implemented):

- **Loop Unrolling / Jamming**: We originally wanted to add loop unrolling, but doing that safely at the flat TAC array level without building a full Abstract Syntax Tree was getting way too complicated and buggy, so we left it out.

- **Arrays & Pointers**: The grammar only supports standard `int` and `float` variables. Things like `int arr[]` or `*ptr` are not supported and won't compile.

- **Custom Functions**: The compiler only supports the `main()` function right now. Handling custom function calls and building stack frames in MIPS was a bit out of scope.

- **String Printing**: The lexer can tokenize strings, but since we aren't linking standard libraries like `<stdio.h>`, you can't use `printf()`. The only way to see output is through the final integer return statement.

---