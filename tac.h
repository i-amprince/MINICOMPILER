#ifndef TAC_H
#define TAC_H

typedef struct {
    char op[10];
    char arg1[20];
    char arg2[20];
    char res[20];
} TAC;

/* --- NEW: Backpatching Structure --- */
typedef struct {
    int list[100];
    int count;
} IntList;

extern TAC tac_table[1000];
extern int tac_count;

char* new_temp();
char* new_label();
void emit(char* op, char* arg1, char* arg2, char* res);
void print_tac();
void optimize_tac();
void generate_assembly();

/* --- NEW: Backpatching Methods --- */
IntList makelist(int index);
IntList merge(IntList l1, IntList l2);
void backpatch(IntList l, int target);
void finish_backpatching(); 

#endif