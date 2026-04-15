#ifndef SEMANTIC_H
#define SEMANTIC_H

typedef struct {
    char* name;
    int type;
    int scope;
} Symbol;

void add_symbol(char* name, int type);
int check_symbol(char* name);
void check_undeclared(char* name);
int get_symbol_type(char* name);

void enter_scope();
void exit_scope();

#endif