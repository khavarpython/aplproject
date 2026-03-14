%{ 
#include <stdio.h> 
#include <string.h> 

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

%token LET CONST TRY CATCH FINALLY THROW DISPLAY INPUT READ
%token NULL_LIT CHAR_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN

%token <sval> IDENTIFIER STRING_LIT
%token <ival> INT_LIT
%token <dval> FLOAT_LIT DOUBLE_LIT
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
	;

assign_stmt:
	LET IDENTIFIER ASSIGN expr
	;

print_stmt:
    DISPLAY expr
    | DISPLAY expr expr
    ;

expr:
    value
    | value ADD expr
    | value SUB expr
    | value MUL expr
    | value DIV expr
    | value MOD expr
    | value POW expr
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

