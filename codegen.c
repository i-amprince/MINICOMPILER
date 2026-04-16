#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "tac.h"

int is_num_val(char *s) {
    if (s == NULL || *s == '\0') return 0;
    if (*s == '-') s++;
    if (*s == '\0') return 0;
    while (*s) {
        if (!isdigit(*s)) return 0;
        s++;
    }
    return 1;
}

void load_reg(char* reg, char* arg) {
    if (is_num_val(arg)) {
        printf("\tli %s, %s\t\t# Load immediate number\n", reg, arg);
    } else {
        printf("\tlw %s, %s\t\t# Load variable from memory\n", reg, arg);
    }
}

void generate_assembly() {
    printf("\n--- Phase 6: MIPS Assembly Code ---\n");
    
    printf(".data\n");
    
    char declared[1000][20];
    int decl_count = 0;

    for (int i = 0; i < tac_count; i++) {
        TAC t = tac_table[i];
        if (strcmp(t.op, "DELETED") == 0 || strcmp(t.op, "label") == 0 || 
            strcmp(t.op, "goto") == 0 || strcmp(t.op, "return") == 0) continue;

        if (strlen(t.res) > 0 && !is_num_val(t.res)) {
            int found = 0;
            for(int j=0; j<decl_count; j++) if(strcmp(declared[j], t.res) == 0) found = 1;
            if(!found) {
                printf("%s:\t.word 0\n", t.res);
                strcpy(declared[decl_count++], t.res);
            }
        }
    }

    printf("\n.text\n");
    printf(".globl main\n");
    printf("main:\n");

    for (int i = 0; i < tac_count; i++) {
        TAC t = tac_table[i];
        
        if (strcmp(t.op, "DELETED") == 0) continue;

        if (strcmp(t.op, "label") == 0) {
            printf("\n%s:\n", t.res);
        } else {
            printf("\t# %s = %s %s %s\n", t.res, t.arg1, t.op, t.arg2);
        }

        if (strcmp(t.op, "goto") == 0) {
            printf("\tj %s\n", t.res);
        } else if (strcmp(t.op, "ifFalse") == 0) {
            load_reg("$t0", t.arg1);
            printf("\tbeq $t0, $zero, %s\n", t.res);
        } else if (strcmp(t.op, "return") == 0) {
            load_reg("$a0", t.arg1);
            printf("\tli $v0, 1\t\t# Print integer syscall\n");
            printf("\tsyscall\n");
            printf("\tli $v0, 10\t\t# Exit program syscall\n");
            printf("\tsyscall\n");
        } else if (strcmp(t.op, "=") == 0) {
            load_reg("$t0", t.arg1);
            printf("\tsw $t0, %s\n", t.res);
        } else if (strcmp(t.op, "+") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tadd $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "-") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tsub $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "*") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tmul $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "/") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tdiv $t0, $t1\n");
            printf("\tmflo $t2\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "==") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tseq $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "!=") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tsne $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, ">") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tsgt $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "<") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tslt $t2, $t0, $t1\n");
            printf("\tsw $t2, %s\n", t.res);
        }
        else if (strcmp(t.op, ">=") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tsge $t2, $t0, $t1\n"); 
            printf("\tsw $t2, %s\n", t.res);
        } else if (strcmp(t.op, "<=") == 0) {
            load_reg("$t0", t.arg1);
            load_reg("$t1", t.arg2);
            printf("\tsle $t2, $t0, $t1\n"); 
            printf("\tsw $t2, %s\n", t.res);
        }
    }
}