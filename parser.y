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
    float fnum; /* Added: Support for floating-point numbers */
    struct {
        int dtype;
        char place[20];
    } expr_val;
    char** lbls;
}

%type <expr_val> expr condition
%type <str> if_prefix

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

statement:
    declaration
    | assign_expr ';'
    | if_prefix statement %prec LOWER_THAN_ELSE { 
        emit("label", "", "", $1); 
    }
    | if_prefix statement ELSE { 
        $<str>$ = new_label(); 
        emit("goto", "", "", $<str>$); 
        emit("label", "", "", $1); 
    } statement { 
        emit("label", "", "", $<str>4); 
    }
    | WHILE { 
        $<str>$ = new_label(); 
        emit("label", "", "", $<str>$); 
    } '(' condition ')' { 
        $<str>$ = new_label(); 
        emit("ifFalse", $4.place, "", $<str>$); 
    } statement { 
        emit("goto", "", "", $<str>2); 
        emit("label", "", "", $<str>6); 
    }
    | FOR '(' for_init ';' { 
        $<str>$ = new_label(); 
        emit("label", "", "", $<str>$); 
    } condition ';' { 
        char** arr = malloc(3 * sizeof(char*));
        arr[0] = new_label(); 
        arr[1] = new_label(); 
        arr[2] = new_label(); 
        emit("ifFalse", $6.place, "", arr[0]); 
        emit("goto", "", "", arr[1]); 
        emit("label", "", "", arr[2]); 
        $<lbls>$ = arr;
    } for_update ')' { 
        char** arr = $<lbls>8;
        emit("goto", "", "", $<str>5); 
        emit("label", "", "", arr[1]); 
        $<lbls>$ = arr;
    } statement { 
        char** arr = $<lbls>11;
        emit("goto", "", "", arr[2]); 
        emit("label", "", "", arr[0]); 
        free(arr);
    }
    | RETURN expr ';' { 
        emit("return", $2.place, "", ""); 
    }
    | '{' { enter_scope(); } statements '}' { exit_scope(); }  /* <--- UPDATE THIS LINE */
    | ';'
    ;

condition:
    expr EQ expr { 
        strcpy($$.place, new_temp()); 
        emit("==", $1.place, $3.place, $$.place); 
    }
    | expr EGT expr { 
        strcpy($$.place, new_temp()); 
        emit(">=", $1.place, $3.place, $$.place); 
    }
    | expr ELT expr { 
        strcpy($$.place, new_temp()); 
        emit("<=", $1.place, $3.place, $$.place); 
    }
    | expr GT expr { 
        strcpy($$.place, new_temp()); 
        emit(">", $1.place, $3.place, $$.place); 
    }
    | expr LT expr { 
        strcpy($$.place, new_temp()); 
        emit("<", $1.place, $3.place, $$.place); 
    }
    | expr NE expr { 
        strcpy($$.place, new_temp()); 
        emit("!=", $1.place, $3.place, $$.place); 
    }
    | VAR { 
        check_undeclared($1); 
        strcpy($$.place, $1); 
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

void yyerror(const char* s){
    printf("Parsing error %s\n",s);
}

int main(){
    if(yyparse() == 0){
        print_tac();
        optimize_tac();
        generate_assembly();
    } else {
        printf("\nCompilation Error\n");
    }
    return 0;
}