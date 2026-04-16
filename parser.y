%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include"semantic.h"
#include"tac.h"

extern int yylineno;

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
    struct {      
        IntList truelist;
        IntList falselist;
    } cond;
    IntList intlist;
    int instr;
}


%type <expr_val> expr
%type <cond> condition
%type <instr> M
%type <intlist> N

%token <num> NUM
%token <fnum> FLOAT_NUM /* Added: Token for floating-point numbers */
%token <str> VAR
%token <str> STRING_LITERAL

%token INT FLOAT IF ELSE FOR WHILE INCLUDE_STMT RETURN
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


%expect 1  /* <-- ADD THIS LINE HERE */

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
            printf("Semantic Error on line %d: Missing Main function.\n", yylineno); exit(1);
            exit(1);
        }
    }
    ;

statements:
    statements statement
    |
    ;

assign_expr:
    
    VAR '=' expr { 
        check_undeclared($1);
        if(get_symbol_type($1) != $3.dtype){ printf("Semantic Error on line %d: Mismatch found.\n", yylineno); exit(1); }
        emit("=", $3.place, "", $1);
    }
    | VAR PLUSEQ expr { 
        check_undeclared($1); 
        if(get_symbol_type($1) != $3.dtype){ printf("Semantic Error on line %d: Mismatch found.\n", yylineno); exit(1); }
        char* t = new_temp();
        emit("+", $1, $3.place, t);
        emit("=", t, "", $1);
    }
    | VAR MINUSEQ expr { 
        check_undeclared($1); 
        if(get_symbol_type($1) != $3.dtype){ printf("Semantic Error on line %d: Mismatch found.\n", yylineno); exit(1); }
        char* t = new_temp();
        emit("-", $1, $3.place, t);
        emit("=", t, "", $1);
    }
    
    ;

declaration: 
    INT int_var_list ';' { }
    | FLOAT float_var_list ';' { }
    ;

int_var_list: 
    int_var_decl
    | int_var_list ',' int_var_decl
    ;

int_var_decl:
    VAR { 
        add_symbol($1, 1); 
    }
    | VAR '=' expr { 
        add_symbol($1, 1);
        if ($3.dtype != 1) { 
            exit(1); 
        }
        emit("=", $3.place, "", $1);
    }
    ;

float_var_list: 
    float_var_decl
    | float_var_list ',' float_var_decl
    ;

float_var_decl:
    VAR { 
        add_symbol($1, 2); /* 2 signifies Float */
    }
    | VAR '=' expr { 
        add_symbol($1, 2);
        if ($3.dtype != 2) { 
            printf("Semantic Error: Type mismatch in declaration of '%s'\n", $1);
            exit(1); 
        }
        emit("=", $3.place, "", $1);
    }
    ;

for_init:
    assign_expr           /* For existing variables: for(i = 0; ...) */
    | expr                /* For inline math: for(i++; ...) */
    | INT int_var_list    /* NEW: For new int declarations: for(int i = 0; ...) */
    | FLOAT float_var_list/* NEW: For new float declarations: for(float f = 0.5; ...) */
    |                     /* Allows an empty init block: for(; i < 10; ...) */
    ;

for_update:
    assign_expr
    | expr
    | 
    ;



M: /* empty */ { $$ = tac_count; } ;
N: /* empty */ { $$ = makelist(tac_count); emit("goto", "", "", "-1"); } ;


statement:
    declaration
    | assign_expr ';'
    | expr ';'
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
    | expr { 
        char* t = new_temp();
        /* We compare the evaluated expression ($1) to zero */
        emit("!=", $1.place, "0", t); 
        
        /* Generate the standard Backpatching blank targets */
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
        if($1.dtype != $3.dtype){ 
            printf("Semantic error on line %d type mismatch\n",yylineno);
            exit(1); 
            }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("+", $1.place, $3.place, $$.place);
    }
    | expr SUB expr { 
        if($1.dtype != $3.dtype){ 
            printf("Semantic error on line %d type mismatch\n",yylineno);
            exit(1); 
            }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("-", $1.place, $3.place, $$.place);
    }
    | expr MUL expr { 
        if($1.dtype != $3.dtype){ 
            printf("Semantic error on line %d type mismatch\n",yylineno);
            exit(1); 
            }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("*", $1.place, $3.place, $$.place);
    }
    | expr DIV expr { 
        if($1.dtype != $3.dtype){ 
            printf("Semantic error on line %d type mismatch\n",yylineno);
            exit(1); 
            }
        $$.dtype = $1.dtype;
        strcpy($$.place, new_temp());
        emit("/", $1.place, $3.place, $$.place);
    }
    | '(' expr ')' { 
        $$.dtype=$2.dtype;
        strcpy($$.place,$2.place);
    }
    /* Post-increment (a++) */
    | VAR INC { 
        check_undeclared($1);
        if(get_symbol_type($1) != 1){ 
            printf("Semantic/Syntax error on line %d",yylineno);
            exit(1); 
            }
        
        $$.dtype = 1;
        /* 1. Save original value to be used in the surrounding math expression */
        char* val_temp = new_temp();
        emit("=", $1, "", val_temp);
        strcpy($$.place, val_temp);
        
        /* 2. Perform the increment side-effect in memory */
        char* inc_temp = new_temp();
        emit("+", $1, "1", inc_temp);
        emit("=", inc_temp, "", $1);
    }
    /* Post-decrement (a--) */
    | VAR DEC { 
        check_undeclared($1);
        if(get_symbol_type($1) != 1){
            printf("Semantic error on line %d",yylineno);
             exit(1); 
             }
        
        $$.dtype = 1;
        char* val_temp = new_temp();
        emit("=", $1, "", val_temp);
        strcpy($$.place, val_temp);
        
        char* dec_temp = new_temp();
        emit("-", $1, "1", dec_temp);
        emit("=", dec_temp, "", $1);
    }
    /* Pre-increment (++a) */
    | INC VAR { 
        check_undeclared($2);
        if(get_symbol_type($2) != 1){ 
            printf("Semantic/Syntax error on line %d",yylineno);
            exit(1); }
        
        $$.dtype = 1;
        /* 1. Perform the increment FIRST */
        char* inc_temp = new_temp();
        emit("+", $2, "1", inc_temp);
        emit("=", inc_temp, "", $2);
        
        /* 2. Use the new updated value for the surrounding math expression */
        strcpy($$.place, $2);
    }
    /* Pre-decrement (--a) */
    | DEC VAR { 
        check_undeclared($2);
        if(get_symbol_type($2) != 1){ printf("Semantic Error on line %d: Operation failed.\n", yylineno); exit(1); }
        
        $$.dtype = 1;
        char* dec_temp = new_temp();
        emit("-", $2, "1", dec_temp);
        emit("=", dec_temp, "", $2);
        
        strcpy($$.place, $2);
    }
    /* Relational Operators as Expressions */
    | expr EQ expr { 
        $$.dtype = 1; 
        strcpy($$.place, new_temp());
        emit("==", $1.place, $3.place, $$.place);
    }
    | expr NE expr { 
        $$.dtype = 1;
        strcpy($$.place, new_temp());
        emit("!=", $1.place, $3.place, $$.place);
    }
    | expr GT expr { 
        $$.dtype = 1;
        strcpy($$.place, new_temp());
        emit(">", $1.place, $3.place, $$.place);
    }
    | expr LT expr { 
        $$.dtype = 1;
        strcpy($$.place, new_temp());
        emit("<", $1.place, $3.place, $$.place);
    }
    | expr EGT expr { 
        $$.dtype = 1;
        strcpy($$.place, new_temp());
        emit(">=", $1.place, $3.place, $$.place);
    }
    | expr ELT expr { 
        $$.dtype = 1;
        strcpy($$.place, new_temp());
        emit("<=", $1.place, $3.place, $$.place);
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