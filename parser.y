%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <setjmp.h>
#include "ast.h"

// SYMBOL TABLE  
#define MAX_VARS 100
typedef struct {
    char name[50];
    double value;
} Variable;

Variable symtab[MAX_VARS];
int var_count = 0;

int find_var(char *name) {
    for (int i = 0; i < var_count; i++)
        if (strcmp(symtab[i].name, name) == 0) return i;
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

// DISPLAY HELPER  
void display_value(char *s) {
    if (s[0] == '"')
        printf("%.*s", (int)strlen(s) - 2, s + 1);
    else
        printf("%s", s);
}

// ERROR HANDLING 
int div_error = 0;
jmp_buf catch_point;
char num_buf[50];
 
int yylex();
void yyerror(const char *s) { fprintf(stderr, "error: %s\n", s); }
int yywrap() { return 1; }
%}

// UNION  
%union {
    char   *sval;
    int     ival;
    double  dval;
    ASTNode *node;
}

// TOKENS  
%token LET CONST TRY CATCH DISPLAY INPUT READ
%token NULL_LIT CHAR_LIT BOOL_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN

%token <sval> IDENTIFIER STRING_LIT
%token <ival> INT_LIT
%token <dval> FLOAT_LIT DOUBLE_LIT

// TYPES 
%type <node> program stmts stmt expr value
%type <node> display_list display_item
%type <node> assign_stmt const_stmt print_stmt try_stmt input_stmt

// PRECEDENCE (PEMDAS) 
%left ADD SUB
%left MUL DIV MOD
%right POW
%left LPAREN RPAREN

%%

program:
    stmts {
        printf("\n ABSTRACT SYNTAX TREE \n");
        print_ast($1, 0);
        printf("==\n");
        $$ = $1;
    }
;

stmts:
    /* empty */         { $$ = NULL; }
    | stmts stmt          { $$ = ($1 == NULL) ? $2 : create_node("SEQ", $1, $2); }
;

stmt:
    assign_stmt { $$ = $1; }
    | const_stmt  { $$ = $1; }
    | print_stmt  { $$ = $1; }
    | try_stmt    { $$ = $1; }
    | input_stmt  { $$ = $1; }
;

assign_stmt:
    LET IDENTIFIER ASSIGN expr {
        if (!div_error) {
            set_var($2, $4->value);
            printf("[ASSIGN] %s = %g\n", $2, $4->value);
        }
        ASTNode *id = create_leaf_id($2);
        $$ = create_node("LET", id, $4);
        free($2);
    }
;

const_stmt:
    CONST IDENTIFIER ASSIGN expr {
        if (!div_error) {
            set_var($2, $4->value);
            printf("[CONST] %s = %g\n", $2, $4->value);
        }
        ASTNode *id = create_leaf_id($2);
        $$ = create_node("CONST", id, $4);
        free($2);
    }
;

print_stmt:
    DISPLAY display_list {
        printf("\n");
        $$ = create_node("DISPLAY", $2, NULL);
    }
;

display_list:
    display_item                  { $$ = $1; }
    | display_list display_item   { $$ = create_node("DLIST", $1, $2); }
;

display_item:
    STRING_LIT {
        display_value($1);
        $$ = create_leaf_str($1);
        free($1);
    }
    | expr {
        printf("%g", $1->value);
        $$ = $1;
    }
;

try_stmt:
    TRY {
        div_error = 0;
        setjmp(catch_point);
    } stmts CATCH stmts {
        $$ = create_node("TRY", $3, $5);
    }
;

input_stmt:
    INPUT expr READ IDENTIFIER {
        double val;
        printf("Enter value for %s: ", $4);
        scanf("%lf", &val);
        set_var($4, val);
        ASTNode *id = create_leaf_id($4);
        $$ = create_node("INPUT", $2, id);
        free($4);
    }
;

expr:
    value                   { $$ = $1; }
    | expr ADD expr         { $$ = create_node("ADD", $1, $3); $$->value = $1->value + $3->value; }
    | expr SUB expr         { $$ = create_node("SUB", $1, $3); $$->value = $1->value - $3->value; }
    | expr MUL expr         { $$ = create_node("MUL", $1, $3); $$->value = $1->value * $3->value; }
    | expr DIV expr         {
        $$ = create_node("DIV", $1, $3);
        if ($3->value == 0) {
            div_error = 1;
            longjmp(catch_point, 1);
            $$->value = 0;
        } else {
            $$->value = $1->value / $3->value;
        }
    }
    | expr MOD expr         {
        $$ = create_node("MOD", $1, $3);
        $$->value = (int)$1->value % (int)$3->value;
    }
    | expr POW expr         {
        $$ = create_node("POW", $1, $3);
        $$->value = pow($1->value, $3->value);
    }
    | LPAREN expr RPAREN    { $$ = $2; }
    | SUB expr %prec MUL    { $$ = create_node("NEG", $2, NULL); $$->value = -$2->value; }
;

value:
    BOOL_LIT      { $$ = create_leaf_num(0); }
    | NULL_LIT    { $$ = create_leaf_num(0); }
    | INT_LIT     { $$ = create_leaf_num($1); }
    | FLOAT_LIT   { $$ = create_leaf_num($1); }
    | DOUBLE_LIT  { $$ = create_leaf_num($1); }
    | STRING_LIT  { $$ = create_leaf_str($1); free($1); }
    | CHAR_LIT    { $$ = create_leaf_num(0); }
    | IDENTIFIER  {
        double v = get_var($1);
        $$ = create_leaf_id($1);
        $$->value = v;
        free($1);
    }
;

%%

// AST IMPLEMENTATION  

ASTNode* create_node(char *type, ASTNode *left, ASTNode *right) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strncpy(node->type, type, 19);
    node->type[19] = '\0';
    node->left  = left;
    node->right = right;
    node->value = 0;
    node->name[0]  = '\0';
    node->sval[0]  = '\0';
    return node;
}

ASTNode* create_leaf_num(double value) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strcpy(node->type, "NUM");
    node->value = value;
    node->name[0]  = '\0';
    node->sval[0]  = '\0';
    node->left = node->right = NULL;
    return node;
}

ASTNode* create_leaf_id(char *name) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strcpy(node->type, "ID");
    strncpy(node->name, name, 49);
    node->name[49] = '\0';
    node->sval[0]  = '\0';
    node->value = 0;
    node->left = node->right = NULL;
    return node;
}

ASTNode* create_leaf_str(char *s) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strcpy(node->type, "STR");
    strncpy(node->sval, s, 255);
    node->sval[255] = '\0';
    node->name[0] = '\0';
    node->value   = 0;
    node->left = node->right = NULL;
    return node;
}

void print_ast(ASTNode *root, int level) {
    if (!root) return;

    for (int i = 0; i < level; i++) printf("  ");

    if (strcmp(root->type, "NUM") == 0)
        printf("NUM(%g)\n", root->value);
    else if (strcmp(root->type, "ID") == 0)
        printf("ID(%s)\n", root->name);
    else if (strcmp(root->type, "STR") == 0)
        printf("STR(%s)\n", root->sval);
    else
        printf("%s\n", root->type);
        
    print_ast(root->left,  level + 1);
    print_ast(root->right, level + 1);
}

int main() {
    yyparse();
    return 0;
}