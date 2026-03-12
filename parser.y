%{ 
#include <stdio.h> 
#include <string.h> 

//function declarations
void yyerror(const char *str);
int yywrap();
int yyparse();
int yylex();

void yyerror(const char *str) 
{ 
	fprintf(stderr,"error: %s\n",str); 
} 

int yywrap() 
{ 
	return 1; 
} 

int main() 
{ 
	yyparse();
	return 0;
}
%}

%token LET CONST IF ELSE ELIF WHILE FOR DO BREAK CONTINUE RETURN
%token TRY CATCH FINALLY THROW DISPLAY INPUT READ
%token BOOL_LIT NULL_LIT DOUBLE_LIT FLOAT_LIT INT_LIT STRING_LIT CHAR_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN 
%token EQUAL NEQUAL LESS_THAN LESS_THAN_E GREATER_THAN GREATER_THAN_E
%token AND OR NOT LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET SEMICOLON COLON COMMA DOT IDENTIFIER

%%

program:
	stmts
	;

stmts:
	stmts stmt
	;	

stmt:
	assign_stmt 
	|
	print_stmt
	;

assign_stmt:
	LET lvalue ASSIGN rvalue
	;

print_stmt:
	DISPLAY (expr)
	;

lvalue:
	IDENTIFIER
	;

rvalue:
	value
	|
	expr
	;

expr:
	value
	|
	value expr
	|
	value ADD value
	|
	value ADD expr
	|
	value SUB value
	|
	value SUB expr
	|
	value MUL value
	|
	value MUL expr
	|
	value DIV value
	|
	value DIV expr
	|
	value MOD value
	|
	value MOD expr
	|
	value POW value
	|
	value POW expr
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
