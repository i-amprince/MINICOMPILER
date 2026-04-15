%{
#include "y.tab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
%}

%option yylineno

%%

"/*"      { 
              /* Non-greedy C-style comment handler */
              int c;
              while ((c = input()) != EOF && c != 0) {
                  if (c == '*') {
                      if ((c = input()) == '/') 
                          break;
                      else 
                          unput(c);
                  }
              }
          }

"//".*    { /* ignore single line comments */ }

\"[^\"]*\" { yylval.str=strdup(yytext); return STRING_LITERAL; }
\'[^\']*\' { yylval.str=strdup(yytext); return STRING_LITERAL; }

"int"     { return INT; }
"if"      { return IF; }
"else"    { return ELSE; }
"for"     { return FOR; }
"while"   { return WHILE; }
"#include".* { return INCLUDE_STMT; }
"return"  { return RETURN; }

"&&"      { return AND; }
"||"      { return OR; }
"++"      { return INC; }
"--"      { return DEC; }
"+="      { return PLUSEQ; }
"-="      { return MINUSEQ; }
"=="      { return EQ; }
">="      { return EGT; }
"<="      { return ELT; }
"!="      { return NE; }
"+"       { return ADD; }
"-"       { return SUB; }
"*"       { return MUL; }
"/"       { return DIV; }
"="       { return '='; }
">"       { return GT; }
"<"       { return LT; }
"!"       { return NOT; }

"("       { return '('; }
")"       { return ')'; }
";"       { return ';'; }
","       { return ','; }
"{"       { return '{'; }
"}"       { return '}'; }

[0-9]+\.[0-9]+  { 
                    yylval.fnum = atof(yytext); 
                    return FLOAT_NUM; 
                }
[0-9]+    { 
              yylval.num=atoi(yytext); 
              return NUM; 
          }

[a-zA-Z_][a-zA-Z0-9_]* { 
              yylval.str=strdup(yytext); 
              return VAR; 
          }

[ \t\r\n]+ { /* Ignore whitespace and Windows carriage returns */ }

.         { printf("Lexical Error on line %d: Invalid token %s\n", yylineno, yytext); }

%%

int yywrap(){
    return 1;
}