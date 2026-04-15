%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "semantic.h"
#include "tac.h"

void yyerror(const char* str);
int yylex();
%}

%union {
    char* str;
    int num;
    float fnum;
    struct {
        int dtype;
        char place[20];
    } expr_val;
    struct {                /* NEW: Added for boolean backpatching */
        IntList truelist;
        IntList falselist;
    } cond;
    IntList intlist;        /* NEW: Added for jump tracking */
    int instr;              /* NEW: Added for line indexing */
}

%type <str> if_prefix
%type <expr_val> expr
%type <cond> condition
%type <instr> M
%type <intlist> N

%token <num> NUM
%token <fnum> FLOAT_NUM /* Added: Token for floating-point numbers */
%token <str> VAR
%token <str> STRING_LITERAL

%token INT IF ELSE FOR WHILE INCLUDE_STMT RETURN
%token AND OR INC DEC PLUSEQ MINUSEQ
%token EQ EGT ELT NE ADD SUB MUL DIV GT LT NOT

/* Precedence and Associativity Rules */
%left OR
%left AND
%left EQ NE
%left GT LT EGT ELT
%left ADD SUB
%left MUL DIV
%right NOT
%right UMINUS /* Added: Unary minus precedence (highest math precedence) */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

programme:
    headers main_func { }
    ;

headers:
    headers INCLUDE_STMT { }
    |
    ;

main_func:
    INT VAR '(' ')' '{' { enter_scope(); } statements '}' {
        exit_scope();
        if(strcmp($2,"main")!=0){
            exit(1);
        }
    }
    ;

statements:
    statements statement
    |
    ;

assign_expr:
    INT VAR '=' expr { 
        add_symbol($2,1); 
        emit("=", $4.place, "", $2);
    }
    | VAR '=' expr { 
        check_undeclared($1);
        if(get_symbol_type($1) != $3.dtype){ exit(1); }
        emit("=", $3.place, "", $1);
    }
    | VAR PLUSEQ expr { 
        check_undeclared($1); 
        if(get_symbol_type($1) != $3.dtype){ exit(1); }
        char* t = new_temp();
        emit("+", $1, $3.place, t);
        emit("=", t, "", $1);
    }
    | VAR MINUSEQ expr { 
        check_undeclared($1); 
        if(get_symbol_type($1) != $3.dtype){ exit(1); }
        char* t = new_temp();
        emit("-", $1, $3.place, t);
        emit("=", t, "", $1);
    }
    | VAR INC {
        check_undeclared($1);
        if(get_symbol_type($1)!=1){ exit(1); }
        char* t = new_temp();
        emit("+", $1, "1", t);
        emit("=", t, "", $1);
    }
    | VAR DEC { 
        check_undeclared($1);
        if(get_symbol_type($1)!=1){ exit(1); }
        char* t = new_temp();
        emit("-", $1, "1", t);
        emit("=", t, "", $1);
    }
    ;

declaration: 
    INT var_list ';' { }
    ;

var_list: 
    VAR { add_symbol($1,1); }
    | var_list ',' VAR { add_symbol($3,1); }
    ;

for_init:
    assign_expr
    | 
    ;

for_update:
    assign_expr
    | 
    ;

if_prefix:
    IF '(' condition ')' { 
        $$ = new_label(); 
        emit("ifFalse", $3.place, "", $$); 
    }
    ;

M: /* empty */ { $$ = tac_count; } ;
N: /* empty */ { $$ = makelist(tac_count); emit("goto", "", "", "-1"); } ;


statement:
    declaration
    | assign_expr ';'
    | IF '(' condition ')' M statement %prec LOWER_THAN_ELSE { 
        backpatch($3.truelist, $5);
        backpatch($3.falselist, tac_count); 
    }
    | IF '(' condition ')' M statement ELSE N M statement { 
        backpatch($3.truelist, $5);
        backpatch($3.falselist, $9);
        backpatch($8, tac_count); 
    }
    | WHILE M '(' condition ')' M statement { 
        backpatch($4.truelist, $6);
        char buf[20]; sprintf(buf, "%d", $2);
        emit("goto", "", "", buf); 
        backpatch($4.falselist, tac_count); 
    }
    | FOR '(' for_init ';' M condition ';' M for_update N ')' M statement { 
        backpatch($6.truelist, $12);
        backpatch($10, $5);
        char buf[20]; sprintf(buf, "%d", $8);
        emit("goto", "", "", buf);
        backpatch($6.falselist, tac_count); 
    }
    | RETURN expr ';' { 
        emit("return", $2.place, "", ""); 
    }
    | '{' { enter_scope(); } statements '}' { exit_scope(); }
    | ';'
    ;

condition:
    condition AND M condition {
        backpatch($1.truelist, $3);
        $$.truelist = $4.truelist;
        $$.falselist = merge($1.falselist, $4.falselist);
    }
    | condition OR M condition {
        backpatch($1.falselist, $3);
        $$.truelist = merge($1.truelist, $4.truelist);
        $$.falselist = $4.falselist;
    }
    | NOT condition {
        $$.truelist = $2.falselist;
        $$.falselist = $2.truelist;
    }
    | '(' condition ')' { $$ = $2; }
    | expr EQ expr { 
        char* t = new_temp();
        emit("==", $1.place, $3.place, t);
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1"); 
    }
    | expr NE expr { 
        char* t = new_temp();
        emit("!=", $1.place, $3.place, t);
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1"); 
    }
    | expr GT expr { 
        char* t = new_temp();
        emit(">", $1.place, $3.place, t);
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1"); 
    }
    | expr LT expr { 
        char* t = new_temp();
        emit("<", $1.place, $3.place, t);
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1"); 
    }
    | expr EGT expr { 
        char* t = new_temp();
        emit(">=", $1.place, $3.place, t);
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1"); 
    }
    | expr ELT expr { 
        char* t = new_temp();
        emit("<=", $1.place, $3.place, t);
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1"); 
    }
    | VAR { 
        check_undeclared($1);
        char* t = new_temp();
        emit("!=", $1, "0", t); 
        $$.falselist = makelist(tac_count);
        emit("ifFalse", t, "", "-1");
        $$.truelist = makelist(tac_count);
        emit("goto", "", "", "-1");
    }
    ;

expr:
    VAR { 
        check_undeclared($1); 
        $$.dtype = get_symbol_type($1);
        strcpy($$.place, $1);
    }
    | NUM { 
        $$.dtype = 1; /* 1 signifies an Integer */
        sprintf($$.place, "%d", $1);
    }
    | FLOAT_NUM { /* Added: Rule to handle floating-point numbers */
        $$.dtype = 2; /* 2 signifies a Float */
        sprintf($$.place, "%f", $1);
    }
    | SUB expr %prec UMINUS { /* Added: Rule for Unary Minus (e.g. -5) */
        $$.dtype = $2.dtype;
        strcpy($$.place, new_temp());
        emit("-", "0", $2.place, $$.place); /* Translates -5 into 0 - 5 */
    }
    | expr ADD expr { 
        if($1.dtype != $3.dtype){ exit(1); }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("+", $1.place, $3.place, $$.place);
    }
    | expr SUB expr { 
        if($1.dtype != $3.dtype){ exit(1); }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("-", $1.place, $3.place, $$.place);
    }
    | expr MUL expr { 
        if($1.dtype != $3.dtype){ exit(1); }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("*", $1.place, $3.place, $$.place);
    }
    | expr DIV expr { 
        if($1.dtype != $3.dtype){ exit(1); }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("/", $1.place, $3.place, $$.place);
    }
    ;

%%

extern int yylineno; 

void yyerror(const char* s){
    printf("Syntax Error on line %d: %s\n", yylineno, s);
}

int main(){
    if(yyparse() == 0){
        finish_backpatching();  /* <-- CALL THE BRIDGE BEFORE PRINTING */
        
        printf("Parsing completed successfully.\n");
        print_symbol_table();
        print_tac();
        optimize_tac();
        generate_assembly();
        printf("\nCompilation Process Finished Successfully!\n");
    } else {
        printf("\nCompilation Error\n");
    }
    return 0;
}