%{
#include"tac.h"
#include"y.tab.h"
#include<stdio.h>
#include<string.h>
#include<stdlib.h>


#define PRINT_TOKEN(token_name) printf("  [Line %2d] Token- %-15s | Lexeme- '%s'\n",yylineno,token_name,yytext)
%}

%option yylineno

%%

"/*"      { 
            
                int c;
              while((c=input())!=EOF && c!=0){
                     if(c=='*'){
                      if((c=input())=='/') 
                          break;
                      else 
                            unput(c);
                  }
              }
          }

"//".* {  }

\"[^\"]*\" { PRINT_TOKEN("STRING_LITERAL");
               yylval.str=strdup(yytext); 
            return STRING_LITERAL; 
            }
\'[^\']*\' { PRINT_TOKEN("STRING_LITERAL"); 
            yylval.str=strdup(yytext); 
              return STRING_LITERAL; 
            }

"int"     { PRINT_TOKEN("INT"); 
              return INT; 
            }
"float"   { PRINT_TOKEN("FLOAT"); 
            return FLOAT; 
               }
"if"      { PRINT_TOKEN("IF");
               return IF; 
             }
"else"         { PRINT_TOKEN("ELSE");
                    return ELSE; 
              }
"for"     { PRINT_TOKEN("FOR");
             return FOR; 
               }
"while"   { PRINT_TOKEN("WHILE"); 
            return WHILE; 
               }
"#include".* { PRINT_TOKEN("INCLUDE_STMT");
                 return INCLUDE_STMT;
                    }
"return"  { PRINT_TOKEN("RETURN");
             return RETURN; 
             }

"&&"      { PRINT_TOKEN("AND");
             return AND; 
             }
"||"      {       PRINT_TOKEN("OR");
                  return OR; 
             }
"++"      { PRINT_TOKEN("INC"); 
            return INC; 
            }
"--"      { PRINT_TOKEN("DEC"); 
              return DEC; 
            }
"+="      { PRINT_TOKEN("PLUSEQ"); 
            return PLUSEQ; 
            }
"-="      { PRINT_TOKEN("MINUSEQ");
             return MINUSEQ; 
             }
"=="      { PRINT_TOKEN("EQ");
             return EQ; 
             }
">="      { PRINT_TOKEN("EGT"); 
            return EGT; 
            }
"<="      { PRINT_TOKEN("ELT");
             return ELT; 
             }
"!="      { PRINT_TOKEN("NE");
             return NE; 
             }
"+"       { PRINT_TOKEN("ADD");
             return ADD; 
             }
"-"       {        PRINT_TOKEN("SUB");
                   return SUB; 
             }
"*"       { PRINT_TOKEN("MUL");
             return MUL; 
             }
"/"       { PRINT_TOKEN("DIV"); 
            return DIV; 
            }
"="       {     PRINT_TOKEN("ASSIGN"); 
                return '='; 
               }
">"       { PRINT_TOKEN("GT");
             return GT; 
             }
"<"       {     PRINT_TOKEN("LT");
                return LT; 
             }
"!"       { PRINT_TOKEN("NOT");
             return NOT; 
             }

"("       { PRINT_TOKEN("LPAREN");
             return '('; 
             }
")"       { PRINT_TOKEN("RPAREN"); 
            return ')'; 
            }
";"       { PRINT_TOKEN("SEMI"); 
            return ';'; 
            }
","       { PRINT_TOKEN("COMMA"); 
            return ','; 
            }
"{"       { PRINT_TOKEN("LBRACE"); 
            return '{'; 
            }
"}"       { PRINT_TOKEN("RBRACE"); 
            return '}'; 
            }

[0-9]+\.[0-9]+  { 
                    PRINT_TOKEN("FLOAT_NUM");
                    yylval.fnum=atof(yytext); 
                    return FLOAT_NUM; 
                }
[0-9]+    { 
                  PRINT_TOKEN("NUM");
                  yylval.num=atoi(yytext); 
                  return NUM; 
          }

[a-zA-Z_][a-zA-Z0-9_]* { 
              PRINT_TOKEN("VAR");
              yylval.str=strdup(yytext); 
              return VAR; 
          }

[ \t\r\n]+ {    }

.         { printf("Lexical error on line %d invalid token %s\n", yylineno, yytext); }

%%

int yywrap(){
    return 1;
}