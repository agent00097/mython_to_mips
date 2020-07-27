%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
//int yyerror(char dcdddonsdsdft *s);
int yyerror();
int yylex();
const char* pass_msg = "Input Passed Checking\n";
int semantic_error = 0;
char function_name[30];
char last_used[20];
int is_print;
int str;
int label;
int labels[15];
int stack_index;
int function_called;
int is_return;
int inside;
int inside_a;
int f_call;

//Functions_ddused
char* lookup_char(char *name);
int lookup_int(char *name);
int lookup_type(char *name);
int checkFreeStr();
int checkFreeIndexA();
int checkFreeIndex();
int itExists();
void freeLWAregisters();
void freeAregisters();
void freeLWTregisters();
void freeTregisters();
void popTwoOnStack();
void pushTwoOnStack();
void add_in_scope(char* id, char* str_value, int type, int value);
void free_all_registers_a();
void free_all_registers();
void free_register(int i);
void freeScopes();
void print_all_scope();
int convertIndexToSP(int i);
int lookupSP(char *name);


struct symbol_table {
	char id_name[30];
	int value;
	char string_value[30];
	int type;
} SymbolTable;

struct symbol_table *scope;


//Creating an array of sdTdcsd_resdgdisddtdeffrsdd thcat hfdolds inct dvalue,t# is empty if it's 0 and 1 if it is occupied
int t[8];
int a[4];
%}
 

%union{
	char id_name[30];
	char name[30];
	int value;
	struct {
		int reg;
		int value;
		char this_name[30];
		int is_string;
	} loc;
}

%token ADD MINUS MUL DIV EQ LT LE GT GE ASSIGN NE
%token DEF ENDDEF IF ENDIF ELSE WHILE ENDWHILE PRINT INPUT TRUE FALSE RETURN
%token LP RP COLON COMMA
%token COMMENT
%token <value> INTEGER
%token <name> STRING ID
%type <loc> factor term exp expression expression_list assignment_stmt
%type <loc> rel_exp
%type <id_name> headofid
%type <name> id_lp input_stmt_two

%%

program		: function_list_end end_list 													{printf("\nli $v0,10\nsyscall\n");}

function_list_end	: function_list														{printf("\n\t.globl main\n\t.data\n\t.align 2\n\t.text\n\nmain:\n\n");freeScopes(); strcpy(function_name,"main"); free_all_registers(); free_all_registers_a();}

function_list 	: function_list function 												{freeScopes();}	
		| function																		{freeScopes();}																	

headstart	: function_start LP	parameters RP COLON										{printf("\n\tsw $ra,0($sp)\n\n");print_all_scope();}
			| function_start LP RP COLON												{printf("\n\tsw $ra,0($sp)\n\n");}

function_start	: DEF ID																{printf("\t.text\n%s_START:\n\t\n", $2); strcpy(function_name, $2);}

function	: headstart statements  ENDDEF 												{if(is_return == 1){free_all_registers();sprintf(last_used, "$t%d", checkFreeIndex());printf("\tmove $v0,%s\n", last_used);printf("\tlw %s,0($sp)", last_used); printf("\n\tjr %s\n", last_used); free_all_registers();}else{free_all_registers();sprintf(last_used, "$t%d", checkFreeIndex());printf("\tlw %s,0($sp)", last_used); printf("\n\tjr %s\n", last_used); free_all_registers();}}

parameters	: parameters COMMA ID 														{if(itExists($3) == 1){add_in_scope($3, "", 2, 0);}}
		| ID														 				 	{if(itExists($1) == 1){add_in_scope($1, "", 2, 0);}}												

statements	: statements statement 
		| statement

statement	: assignment_stmt 
		| print_stmt 
		| input_stmt 
		| condition_stmt 
		| while_stmt 
		| call_stmt 
		| return_stmt

headofid	:	ID ASSIGN											  {strcpy($$, $1);}

assignment_stmt	: headofid expression								  {if (itExists($1) == 1){add_in_scope($1,$2.this_name,$2.is_string,$2.value);}printf("sw %s,%d($sp)\n\n", last_used, lookupSP($1)); free_all_registers();}							  

return_stmt	: RETURN exp 											  {is_return = 1;}										  

expression	: rel_exp											      {$$.reg = $1.reg;}
		| exp													      {$$.reg = $1.reg; $$.value = $1.value; strcpy($$.this_name, $1.this_name); $$.is_string = $1.is_string;}

rel_exp		: exp EQ exp 											  {$$.reg = $1.reg; printf("seq $t%d,$t%d,$t%d\n", $1.reg,$1.reg,$3.reg);free_register($3.reg);free_register($$.reg);}
		| exp NE exp 												  {$$.reg = $1.reg; printf("sne $t%d,$t%d,$t%d\n", $1.reg,$1.reg,$3.reg);free_register($3.reg);free_register($$.reg);}
		| exp LT exp 												  {$$.reg = $1.reg; printf("slt $t%d,$t%d,$t%d\n", $1.reg,$1.reg,$3.reg);free_register($3.reg);free_register($$.reg);}
		| exp LE exp 												  {$$.reg = $1.reg; printf("sle $t%d,$t%d,$t%d\n", $1.reg,$1.reg,$3.reg);free_register($3.reg);free_register($$.reg);}
		| exp GT exp 												  {$$.reg = $1.reg; printf("sgt $t%d,$t%d,$t%d\n", $1.reg,$1.reg,$3.reg);free_register($3.reg);free_register($$.reg);}
		| exp GE exp 												  {$$.reg = $1.reg; printf("sge $t%d,$t%d,$t%d\n", $1.reg,$1.reg,$3.reg);free_register($3.reg);free_register($$.reg);}
		| LP rel_exp RP

exp		: exp ADD term 												  {$$.reg = $1.reg; $$.value = $1.value + $3.value;  printf("add $t%d,$t%d,$t%d\n", $$.reg, $$.reg, $3.reg); sprintf(last_used, "$t%d", $$.reg);free_register($3.reg);}
		| exp MINUS term 											  {$$.reg = $1.reg; $$.value = $1.value - $3.value;  printf("sub $t%d,$t%d,$t%d\n", $$.reg, $$.reg, $3.reg); sprintf(last_used, "$t%d", $$.reg);free_register($3.reg);}
		| term														  {$$.reg = $1.reg; $$.value = $1.value; strcpy($$.this_name, $1.this_name); $$.is_string = $1.is_string;}

term		: term MUL factor 										  {$$.value = $1.value * $3.value; $$.reg = $1.reg; printf("mul $t%d,$t%d,$t%d\n", $$.reg, $$.reg, $3.reg); sprintf(last_used, "$t%d", $$.reg); free_register($3.reg);}
		| term DIV factor 											  {$$.value = $1.value / $3.value; $$.reg = $1.reg; printf("div $t%d,$t%d,$t%d\n", $$.reg, $$.reg, $3.reg); sprintf(last_used, "$t%d", $$.reg); free_register($3.reg);}
		| factor													  {$$.reg = $1.reg; $$.value = $1.value; strcpy($$.this_name, $1.this_name); $$.is_string = $1.is_string;}

factor		: LP exp RP 
		| INTEGER                                                     {$$.reg = checkFreeIndex(); $$.value = $1; printf("li $t%d, %d\n", $$.reg, $1); sprintf(last_used, "$t%d", $$.reg); if(function_called == 1){printf("move $a%d, $t%d\n",checkFreeIndexA(),$$.reg); free_all_registers();}}
		| STRING 													  {$$.reg = checkFreeIndex();strcpy($$.this_name, $1); $$.is_string = 1; printf("\t.data\nSTR%d:\t.asciiz %s\n\t.text\n",checkFreeStr(), $1); str++;sprintf(last_used, "$t%d", $$.reg);printf("la $t%d,STR%d\n",$$.reg,str-1);}
		| ID 														  {$$.reg = checkFreeIndex();$$.is_string = lookup_type($1); if(lookup_type($1) == 1) {strcpy($$.this_name, lookup_char($1));} else {$$.value = lookup_int($1);} sprintf(last_used,"$t%d", $$.reg);printf("lw %s, %d($sp)\n", last_used, lookupSP($1));if(function_called == 1){printf("move $a%d, $t%d\n",checkFreeIndexA(),$$.reg); free_all_registers();}}
		| TRUE 
		| FALSE 
		| MINUS factor 												  {printf("neg $t%d,$t%d\n", $2.reg, $2.reg);}
		| call_stmt													  

print_head	: PRINT LP												  {is_print = 1;}

comma_found	: COMMA

print_stmt	: print_head expression_list RP							  {is_print = 0;}						  

input_stmt_two	: ID ASSIGN INPUT									  {add_in_scope($1,"", 0, 0);}

input_stmt	: input_stmt_two LP RP									  {printf("li $v0,5\nsyscall\n"); sprintf(last_used, "$v0"); printf("sw %s,%d($sp)\n", last_used, lookupSP($1));}

id_lp		: ID LP													  {f_call = 1;;if(strcmp(function_name,"main")==0){inside++;}freeTregisters();freeAregisters(); function_called = 1; strcpy($$,$1);}

call_stmt	: id_lp RP												  {printf("subu $sp,$sp,104\naddiu $fp,$sp,100\n");printf("jal %s_START\n", $1);printf("addiu $sp,$sp,104\n");freeLWTregisters();freeLWAregisters();free_all_registers();free_all_registers_a();} 
		| id_lp expr_list RP										  {printf("sw $fp,4($sp)\n");printf("subu $sp,$sp,104\naddiu $fp,$sp,100\n");printf("jal %s_START\n", $1);printf("addiu $sp,$sp,104\n");printf("lw $fp,4($sp)\n");freeLWTregisters();freeLWAregisters();printf("move %s,$v0\n", last_used);if(inside == 2){printf("move $a%d,%s\n", inside_a, last_used);inside_a++;}free_all_registers_a();if(strcmp(function_name,"main") == 0){inside--;}}

else_colon	: ELSE COLON											  {printf("\nb L%d\nL%d:\n\t",labels[stack_index], labels[stack_index-1]);}

condition_stmt	: if_head statements ENDIF 
		| if_head statements else_colon statements ENDIF			  {printf("\nL%d:\n\t", labels[stack_index]);popTwoOnStack();}

if_head		: IF expression COLON									 {label+=2;pushTwoOnStack();printf("beqz $t%d,L%d\n", $2.reg, labels[stack_index-1]);}

while_head	: WHILE													 {label+=2;pushTwoOnStack();printf("L%d:\t",labels[stack_index-1]);}

while_other_head	: while_head expression COLON					 {printf("beqz $t%d,L%d\n",$2.reg,labels[stack_index]);checkFreeIndex();}

while_stmt	: while_other_head statements ENDWHILE					 {printf("b L%d\nL%d:\n",labels[stack_index-1],labels[stack_index]); popTwoOnStack();}

expression_list	: expression_list comma_found expression 			 {if(is_print == 1) {if($3.is_string == 1){printf("li $v0,4\nmove $a0,%s\nsyscall\n",last_used); free_all_registers();} else {printf("li $v0,1\nmove $a0,%s\nsyscall\n", last_used); free_all_registers();}}}
		| expression												 {$$.reg = $1.reg; $$.value = $1.value; strcpy($$.this_name, $1.this_name); if(is_print == 1) {if($1.is_string != 1){printf("li $v0,1\nmove $a0,%s\nsyscall\n", last_used); free_all_registers();} else {printf("li $v0,4\nmove $a0,%s\nsyscall\n", last_used); free_all_registers();}} free_all_registers();}

expr_list	: expr_list COMMA exp 
		| exp

end_list	: end_list end 
		| end

end		: call_stmt 
		| print_stmt 
		| input_stmt

%%

int checkFreeStr() {
	return str;
}

int checkFreeIndex() {
	for(int i = 0 ; i < 8 ; i++) {
		if(t[i] == 0) {
			t[i] = 1;
			return i;
		}
	}
	return -1;
}

int checkFreeIndexA() {
	for(int i = 0 ; i < 8 ; i++) {
		if(a[i] == 0) {
			a[i] = 1;
			return i;
		}
	}
	return -1;
}

void print_all_scope() {
	int i = 0;
	int a = 0;
	for(i = 0; i < 20; i++) {
		
		if(strcmp(scope[i].id_name,"") == 0) {
			return;
		}
		int get = 56 + (i)*4;
		printf("sw $a%d,%d($sp)\n",a,get);
		a++;
	}
}

void scope_pr() {
	int i = 0;
	int a = 0;
	for(i = 0; i < 20; i++) {
		
		if(strcmp(scope[i].id_name,"") == 0) {
			return;
		}
		printf("PRINT %s",scope[i].id_name);
		a++;
	}
}

int itExists(char *name) {
	// printf("What I am looking for is : %s\n", name);
	for(int i = 0; i < 20; i++) {
		// printf("Entry %d : %s\n", i, scope[i].id_name);
		if(strcmp(scope[i].id_name,name) == 0) {
			// printf("What the fuck, it exists!\n");
			//We found thed ID
			return 0;
		}
	}
	return 1;
}

void freeScopes() {
	int i = 0;
	for(i = 0; i < 20; i++) {
		strcpy(scope[i].id_name,"");
	}
}

void free_register(int i) {
	t[i] = 0;
}

void free_all_registers() {
	int i = 0;
	for(i = 0; i < 8; i++) {
		t[i] = 0;
	}
}

void free_all_registers_a() {
	int i = 0;
	for(i = 0; i < 4; i++) {
		a[i] = 0;
	}
}

int main() {
	 //Code for debugging
    #if YYDEBUG == 1
    extern int yydebug;
    yydebug = 1;
    #endif
	is_return = 0;
	stack_index = -1;
	scope = malloc(20 * sizeof * scope);
	for(int i = 0; i < 15; i++) {
		labels[i] = 0;
	}
	f_call = 0;
	inside_a = 0;
	inside = 0;
	str = 0;
	label = -1;
	function_called = 0;
   yyparse();
   return 0;
}

void addTwoOnLabel() {
	label += 2;
}

void add_in_scope(char* id, char* str_value, int type, int value) {
	for(int i = 0; i < 20; i++) {
		if(strcmp(scope[i].id_name,"") == 0) {
			strcpy(scope[i].id_name, id);
			strcpy(scope[i].string_value, str_value);
			scope[i].type = type;
			scope[i].value = value;
			// printf("After adding in_string value to %s is %d\n", scope[i].id_name, scope[i].type);
			return;
		}
	}
}

int lookup_type(char* name) {
	for(int i = 0; i < 20; i++) {
		if(strcmp(scope[i].id_name,name) == 0) {
			//We found the ID
			return scope[i].type;
		}
	}
	return -1;
}

int checkFreeLabel() {
	label++;
	return label-1;
}

char* lookup_char(char *name) {
	for(int i = 0; i < 20; i++) {
		if(strcmp(scope[i].id_name,name) == 0) {
			//We found the ID
			return scope[i].string_value;
		}
	}
	return "";
}

int lookupSP(char *name) {
	// printf("In Lookup, %s is what I am here for\n", name);
	for(int i = 0; i < 20; i++) {
		if(strcmp(scope[i].id_name,name) == 0) {
			// printf("Name found is : %s\n", scope[i].id_name);
			// printf("Index is: %d\n", i);
			// printf("Is string value is : %d\n", scope[i].type);
			//We found the ID
			return (56 + i*(4));
		}
	}
	return -1;
}

int lookup_int(char *name) {
	for(int i = 0; i < 20; i++) {
		if(strcmp(scope[i].id_name,name) == 0) {
			//We found the ID
			return scope[i].value;
		}
	}
	return -1;
}
 

void pushTwoOnStack() {
	int i = 0;
	for(i = 0; i < 15; i++) {
		if(labels[i] == 0) {
			labels[i] = label;
			labels[i+1] = label+1;
			stack_index += 2;
			return;
		}
	}
} 

void popTwoOnStack() {
	int i = 0;
	for(i = 0; i < 15; i++) {
		if(labels[i] == 0) {
			labels[i-1] = 0;
			labels[i-2] = 0;
			stack_index -= 2;
			return;
		}
	}
}

//int yyerror (char const *s) {
int yyerror(){
   //fprintf (stderr, "%s at line %d\n", s, yylineno);
   fprintf(stderr, "syntex error at line %d\n", yylineno);
   //return 0;
   exit(-1);
}

void freeTregisters() {
	printf("sw $t0, 8($sp)\n");
	int i = 1;
	int x = 12;
	for(i = 1; i < 7; i++) {
		printf("sw $t%d, %d($sp)\n",i, x);
		x += 4;
	}
}

void freeLWTregisters() {
	printf("lw $t0, 8($sp)\n");
	int i = 1;
	int x = 12;
	for(i = 1; i < 7; i++) {
		printf("lw $t%d, %d($sp)\n",i, x);
		x += 4;
	}
}

void freeAregisters() {
	int i = 0;
	int x = 40;
	for(i = 0; i < 4; i++) {
		printf("sw $a%d, %d($sp)\n", i, x);
		x += 4;
	}
}

void freeLWAregisters() {
	int i = 0;
	int x = 40;
	for(i = 0; i < 4; i++) {
		printf("lw $a%d, %d($sp)\n", i, x);
		x += 4;
	}
}

int convertIndexToSP(int i) {
	return (56 + (i) * 4);
}