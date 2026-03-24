%{ 
#include <stdio.h> 
#include <string.h>
#include <stdlib.h>
#include <math.h>

//function declarations
void yyerror(const char *str);
int yywrap();
int yyparse();
int yylex();

void yyerror(const char *str) { fprintf(stderr,"error: %s\n",str); } 

int yywrap() { return 1; } 

int main() { yyparse();	return 0;	}	
%}

%union {
    char *sval;
    int ival;
    double dval;
}

%token LET CONST TRY CATCH DISPLAY INPUT READ
%token NULL_LIT CHAR_LIT BOOL_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN

%token <sval> IDENTIFIER STRING_LIT
%token <ival> INT_LIT
%token <dval> FLOAT_LIT DOUBLE_LIT

//PEMDAS
%left ADD SUB //lowest precedence (addition and subtraction)
%left MUL DIV MOD
%right POW
%left LPAREN RPAREN

%type <dval> expr value //expression types return double values


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
	print_stmt
	|
	try_stmt
	|
	input_stmt
	;

assign_stmt:
	LET IDENTIFIER ASSIGN expr
	|
	CONST IDENTIFIER ASSIGN expr
	;

print_stmt:
    DISPLAY expr
    | DISPLAY expr expr
    ;

try_stmt:
    TRY stmts CATCH stmts
    ;

input_stmt:
    INPUT expr READ IDENTIFIER
    ;

expr:
    value
    | expr ADD expr
    | expr SUB expr
    | expr MUL expr
    | expr DIV expr
    | expr MOD expr
    | expr POW expr
    | LPAREN expr RPAREN
    | SUB expr %prec MUL //to handle negative numbers
    ;

value:
	BOOL_LIT
	|
	NULL_LIT
	|
	DOUBLE_LIT
	|
	FLOAT_LIT
	|
	INT_LIT
	|
	STRING_LIT
	|
	CHAR_LIT
	|
	IDENTIFIER
	;
%%

