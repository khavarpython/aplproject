%{ 
#include <stdio.h> 
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <setjmp.h>

// Function declarations
int yyparse();
int yylex();

void yyerror(const char *str) { fprintf(stderr,"error: %s\n",str); } 

int yywrap() { return 1; } 

int main() { yyparse();	return 0;	}	

// Symbol Table
#define MAX_VARS 100

typedef struct {
    char name[50];
    double value;
} Variable;

// Global Variables
Variable symtab[MAX_VARS];
int var_count = 0;
int div_error = 0;
jmp_buf catch_point;
char num_buf[50];  

// Functions
int find_var(char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(symtab[i].name, name) == 0)
            return i;
    }
    return -1;
}

void set_var(char *name, double value) {
    int idx = find_var(name);
    if (idx == -1) {
        strcpy(symtab[var_count].name, name);
        symtab[var_count].value = value;
        var_count++;
    } else {
        symtab[idx].value = value;
    }
}

double get_var(char *name) {
    int idx = find_var(name);
    if (idx == -1) {
        printf("[SEMANTIC ERROR] Variable '%s' not defined\n", name);
        return 0;
    }
    return symtab[idx].value;
}

void display_value(char *s) {
    if (s[0] == '"') {
        printf("%.*s", (int)strlen(s)-2, s+1);
    } else {
        printf("%s", s);
    }
}
%}

// Token Values
%union {
    char *sval;
    int ival;
    double dval;
}

// Tokens
%token LET CONST TRY CATCH DISPLAY INPUT READ
%token NULL_LIT CHAR_LIT BOOL_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN

%token <sval> IDENTIFIER STRING_LIT
%token <ival> INT_LIT
%token <dval> FLOAT_LIT DOUBLE_LIT

// PEMDAS
%left ADD SUB
%left MUL DIV MOD
%right POW
%left LPAREN RPAREN


%type <dval> expr value

%%
program:
	stmts
	;

stmts:
    /* empty */
    | stmts stmt
    ;

stmt:
	assign_stmt 
	|
    const_stmt
    |
	print_stmt
	|
	try_stmt
	|
	input_stmt
	;
	
assign_stmt:
    LET IDENTIFIER ASSIGN expr {
        if (!div_error) {
            set_var($2, $4);
            printf("[ASSIGN] %s = %lf\n", $2, $4);
        }
    }
    ;
	
const_stmt:
    CONST IDENTIFIER ASSIGN expr {
		if (!div_error) {
        	set_var($2, $4);
			printf("[CONST] %s = %lf\n", $2, $4);
		}
    }
    ;

print_stmt:
    DISPLAY display_list { printf("\n"); }
    ;

display_list:
    display_item
    | display_list display_item
    ;

display_item:
    STRING_LIT  { display_value($1); free($1); }
    | expr      { sprintf(num_buf, "%g", $1); printf("%s", num_buf); }
    ;

try_stmt:
    TRY {
        div_error = 0;
        setjmp(catch_point);
    } stmts CATCH stmts
    ;
    
input_stmt:
    INPUT expr READ IDENTIFIER {
        double val;
        printf("Enter value for %s: ", $4);
        scanf("%lf", &val);
        set_var($4, val);
    }
    ;

expr:
    value { $$ = $1; }
    | expr ADD expr { $$ = $1 + $3; }
    | expr SUB expr { $$ = $1 - $3; }
    | expr MUL expr { $$ = $1 * $3; }
    | expr DIV expr {
        if ($3 == 0) {
            div_error = 1;
            longjmp(catch_point, 1);
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    | expr MOD expr { $$ = (int)$1 % (int)$3; }
    | expr POW expr { $$ = pow($1, $3); }
    | LPAREN expr RPAREN { $$ = $2; }
    | SUB expr %prec MUL { $$ = -$2; }
    ;

value:
	BOOL_LIT { $$ = 0; }
	|
	NULL_LIT { $$ = 0; }
	|
	DOUBLE_LIT { $$ = $1; }
	|
	FLOAT_LIT { $$ = $1; }
	|
	INT_LIT { $$ = $1; }
	|
	STRING_LIT { $$ = 0; }
	|
	CHAR_LIT { $$ = 0; }
	|
	IDENTIFIER { $$ = get_var($1); }
	;
%%