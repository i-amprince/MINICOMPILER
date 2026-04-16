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
    /* Instead of deleting, just mark variables in the current scope as inactive */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (symbol_table[i].scope == current_scope) {
            symbol_table[i].is_active = 0; // Deactivate it!
        } else if (symbol_table[i].scope < current_scope) {
            break; // We've reached an outer scope, stop searching
        }
    }
    current_scope--;
}

int check_symbol_current_scope(char* name) {
    /* Only check for duplicates in the EXACT SAME scope that are ACTIVE */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (symbol_table[i].scope != current_scope) break; // We left the current scope
        if (symbol_table[i].is_active && strcmp(symbol_table[i].name, name) == 0) {
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
    symbol_table[symbol_count].is_active = 1; /* NEW: Mark as active when created */
    symbol_count++;
}

void check_undeclared(char* name) {
    /* Search backwards, but ONLY match active variables */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (symbol_table[i].is_active && strcmp(symbol_table[i].name, name) == 0) {
            return; // Found an active variable!
        }
    }
    printf("Semantic error: undeclared variable '%s'\n", name);
    exit(1);
}

int get_symbol_type(char* name) {
    /* Search backwards, but ONLY match active variables */
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (symbol_table[i].is_active && strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].type;
        }
    }
    return -1;
}

void print_symbol_table() {
    printf("\n--- Phase 3: Semantic Analysis (Symbol Table) ---\n");
    printf("%-15s %-10s %-10s\n", "Variable Name", "Data Type", "Scope Level");
    printf("------------------------------------------\n");
    
    /* Prints ALL variables in the table regardless of active status */
    for (int i = 0; i < symbol_count; i++) {
        // Type 1 is Integer, 2 is Float (from parser.y rules)
        char* type_str = (symbol_table[i].type == 1) ? "INT" : "FLOAT";
        printf("%-15s %-10s %-10d\n", 
            symbol_table[i].name, type_str, symbol_table[i].scope);
    }
    printf("------------------------------------------\n");
}