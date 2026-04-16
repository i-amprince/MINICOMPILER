#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<ctype.h>
#include"tac.h"

TAC tac_table[1000];
int tac_count=0;
int temp_count=0;
int label_count=0;



char* new_temp(){
    char* t=malloc(10);

    sprintf(t, "t%d", ++temp_count);
    return t;

}

char* new_label(){


    char* l=malloc(10);
    sprintf(l, "L%d", ++label_count);
    return l;
}

void emit(char* op, char* arg1, char* arg2, char* res){

    strcpy(tac_table[tac_count].op,op);

    strcpy(tac_table[tac_count].arg1, arg1 ? arg1 : "");
    strcpy(tac_table[tac_count].arg2, arg2 ? arg2 : "");
    strcpy(tac_table[tac_count].res, res ? res : "");

    tac_count++;
}

void print_tac(){
    printf("\n     Three Address Code (Phase 4)     \n");
    for(int i=0;i<tac_count;i++){
        if(strcmp(tac_table[i].op,"label")==0){


            printf("%3d: %s:\n",i,tac_table[i].res);
        } 
        else if(strcmp(tac_table[i].op,"goto")==0){

            printf("%3d: \tgoto %s\n",i,tac_table[i].res);
        } 
        else if(strcmp(tac_table[i].op,"ifFalse")==0){
               printf("%3d: \tifFalse %s goto %s\n",i,tac_table[i].arg1,tac_table[i].res);
        } 
        else if(strcmp(tac_table[i].op,"return")==0){
            printf("%3d: \treturn %s\n",i,tac_table[i].arg1);
        } 
        else if(strcmp(tac_table[i].op, "=")==0){
               printf("%3d: \t%s = %s\n",i,tac_table[i].res,tac_table[i].arg1);

        } 
        else{
            printf("%3d: \t%s = %s %s %s\n",i,tac_table[i].res,tac_table[i].arg1,tac_table[i].op,tac_table[i].arg2);
        }
    }
}


int is_number(char *s){
    if(s==NULL || *s=='\0') return 0;

    if(*s=='-') s++;
    if(*s=='\0') return 0;

    while(*s){
        if(!isdigit(*s)) return 0;
        s++;
    }


    return 1;
}

void optimize_tac(){
    printf("\n     Optimized Three Address Code (Phase 5)    \n");


    char const_vars[100][20];
    char const_vals[100][20];
    int const_count=0;



    for(int i=0;i<tac_count;i++){
        if(strcmp(tac_table[i].op,"label")==0 || strcmp(tac_table[i].op,"goto")==0 || strcmp(tac_table[i].op,"ifFalse")==0){
               const_count=0; 
               continue;
        }



        for(int c=0;c<const_count;c++){

            if(strcmp(tac_table[i].arg1,const_vars[c])==0){
                   strcpy(tac_table[i].arg1,const_vals[c]);
            }

            if(strcmp(tac_table[i].arg2,const_vars[c])==0){

                   strcpy(tac_table[i].arg2, const_vals[c]);
            }
        }

        if(is_number(tac_table[i].arg1) && is_number(tac_table[i].arg2) && strcmp(tac_table[i].op,"=")!=0){
            
                int v1=atoi(tac_table[i].arg1);
                int v2=atoi(tac_table[i].arg2);
                int res_val=0;
                int opt=1;



            if(strcmp(tac_table[i].op,"+")==0) res_val=v1+v2;
            else if(strcmp(tac_table[i].op, "-")==0) res_val=v1-v2;
            else if(strcmp(tac_table[i].op, "*")==0) res_val=v1*v2;
            else if(strcmp(tac_table[i].op, "/")==0 && v2!=0) res_val=v1/v2;
            else if(strcmp(tac_table[i].op, "==")==0) res_val=(v1==v2);
            else if(strcmp(tac_table[i].op, "!=")==0) res_val=(v1!=v2);
            else if(strcmp(tac_table[i].op, ">")==0) res_val=(v1>v2);
            else if(strcmp(tac_table[i].op, "<")==0) res_val=(v1<v2);
            else if(strcmp(tac_table[i].op, ">=")==0) res_val=(v1>=v2);
            else if(strcmp(tac_table[i].op, "<=")==0) res_val=(v1<=v2);
            else opt=0;

            if(opt){


                strcpy(tac_table[i].op,"=");
                sprintf(tac_table[i].arg1, "%d",res_val);
                strcpy(tac_table[i].arg2,"");
            }
        }

        if(strcmp(tac_table[i].op,"=")==0 && is_number(tac_table[i].arg1)){
            int found=0;
            for(int c=0; c<const_count;c++){
                if(strcmp(const_vars[c], tac_table[i].res)==0){
                    strcpy(const_vals[c],tac_table[i].arg1);
                    found=1;
                    break;
                }
            }
            if(!found && const_count<100){
                strcpy(const_vars[const_count],tac_table[i].res);
                strcpy(const_vals[const_count],tac_table[i].arg1);
                const_count++;
            }
        }
    }


    for(int i=0;i<tac_count;i++){
        if(strcmp(tac_table[i].op,"label")==0 || strcmp(tac_table[i].op,"goto")==0 || 
              strcmp(tac_table[i].op,"ifFalse")==0 || 
            strcmp(tac_table[i].op,"=")==0 ||
                strcmp(tac_table[i].op,"return")==0){
            continue; 
        }

        for(int j=i-1;j>=0;j--){
            if(strcmp(tac_table[j].op, "label")==0 || strcmp(tac_table[j].op,"goto")==0 || 
                strcmp(tac_table[j].op,"ifFalse")==0){
                   break; 
            }

            if(strcmp(tac_table[i].op, tac_table[j].op)==0 && strcmp(tac_table[i].arg1, tac_table[j].arg1)==0 && 
            strcmp(tac_table[i].arg2, tac_table[j].arg2)==0){
                
                strcpy(tac_table[i].op,"=");
                  strcpy(tac_table[i].arg1,tac_table[j].res); 
                  strcpy(tac_table[i].arg2,"");
                break;
            }
            
            if(strcmp(tac_table[j].res,tac_table[i].arg1)==0 || strcmp(tac_table[j].res, tac_table[i].arg2)==0){
                break;
            }
        }
    }


    for(int i=0;i<tac_count;i++){
        
        if(tac_table[i].res[0]=='t' && tac_table[i].res[1]>='0' && tac_table[i].res[1]<='9'){
               int is_used=0;
            
            
            for(int j=i+1;j<tac_count;j++){
                if(strcmp(tac_table[j].arg1,tac_table[i].res)==0 || strcmp(tac_table[j].arg2,tac_table[i].res)==0){
                    is_used=1;
                    break;
                }
            }
            
            
            if(!is_used){
                strcpy(tac_table[i].op,"DELETED");
            }
        }
    }

    
    for(int i=0;i<tac_count;i++){
    
        if(strcmp(tac_table[i].op,"DELETED")==0) continue;

        if(strcmp(tac_table[i].op, "label")==0){
            printf("%3d: %s:\n",i,tac_table[i].res);
        } 
        else if(strcmp(tac_table[i].op,"goto")==0){
            printf("%3d: \tgoto %s\n",i,tac_table[i].res);
        } 
        else if(strcmp(tac_table[i].op, "ifFalse")==0){
            printf("%3d: \tifFalse %s goto %s\n",i,tac_table[i].arg1,tac_table[i].res);
        } 
        else if(strcmp(tac_table[i].op,"return")==0){
            printf("%3d: \treturn %s\n", i, tac_table[i].arg1);
        } 
        else if(strcmp(tac_table[i].op,"=")==0){
            printf("%3d: \t%s = %s\n",i,tac_table[i].res,tac_table[i].arg1);
        } 
        else {
            printf("%3d: \t%s = %s %s %s\n",i,tac_table[i].res,tac_table[i].arg1,tac_table[i].op,tac_table[i].arg2);
        }
    }
}



IntList makelist(int index){
    IntList res;
    res.count=1;
    res.list[0]=index;
    return res;
}

IntList merge(IntList l1, IntList l2){
      IntList res;
      res.count=0;


    for(int i=0;i<l1.count;i++) res.list[res.count++]=l1.list[i];
    for(int i=0;i<l2.count;i++) res.list[res.count++]=l2.list[i];
    return res;
}

void backpatch(IntList l, int target){
    for(int i=0;i<l.count;i++){
        
        sprintf(tac_table[l.list[i]].res,"%d",target);
    }
}


void finish_backpatching(){
    char labels[2000][20]={0};
    

    for(int i=0;i<tac_count;i++){
        if(strcmp(tac_table[i].op, "goto")==0 || strcmp(tac_table[i].op,"ifFalse")==0){
            int target=atoi(tac_table[i].res);
            if(target>=0 && strcmp(tac_table[i].res,"-1")!=0){ 
                if(labels[target][0]=='\0'){
                    sprintf(labels[target], "L%d", ++label_count);
                }
                strcpy(tac_table[i].res,labels[target]);
            }
        }
    }
    
    
    TAC new_table[2000];
    int new_count=0;
    
    for(int i=0; i<=tac_count;i++){

        if(labels[i][0]!='\0'){
            strcpy(new_table[new_count].op,"label");
            strcpy(new_table[new_count].arg1, "");
            strcpy(new_table[new_count].arg2, "");
            strcpy(new_table[new_count].res, labels[i]);
            new_count++;
        }
        
        if(i < tac_count){
            new_table[new_count++]=tac_table[i];
        }
    }
    
    
    for(int i=0;i<new_count;i++){
        tac_table[i]=new_table[i];
    }
    tac_count=new_count;
}