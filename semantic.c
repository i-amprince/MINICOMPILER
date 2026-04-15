#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "semantic.h"

Symbol symbol_table[100];
int symbol_count = 0;
int current_scope = 0; /* Starts at Global Scope (0) */

void enter_scope() {
    current_scope++;
}

void exit_scope() {
    /* When leaving a block, delete all variables declared inside it */
    while (symbol_count > 0 && symbol_table[symbol_count - 1].scope == current_scope) {
        free(symbol_table[symbol_count - 1].name); // Free memory
        symbol_count--; // Shrink the table
    }
    current_scope--;
}

int check_symbol_current_scope(char* name) {
    /* Only check for duplicates in the EXACT SAME scope */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (symbol_table[i].scope != current_scope) break; // We left the current scope
        if (strcmp(symbol_table[i].name, name) == 0) {
            return 1;
        }
    }
    return 0;
}

void add_symbol(char* name, int type) {
    if (check_symbol_current_scope(name)) {
        printf("Semantic error: '%s' is already declared in this scope\n", name);
        exit(1);
    }
    symbol_table[symbol_count].name = strdup(name);
    symbol_table[symbol_count].type = type;
    symbol_table[symbol_count].scope = current_scope;
    symbol_count++;
}

void check_undeclared(char* name) {
    /* Search backwards to find the closest local variable first */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return; // Found it!
        }
    }
    printf("Semantic error: undeclared variable '%s'\n", name);
    exit(1);
}

int get_symbol_type(char* name) {
    /* Search backwards to find the closest local variable first */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].type;
        }
    }
    return -1;
}