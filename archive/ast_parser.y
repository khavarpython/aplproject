%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// AST Node
typedef struct ASTNode {
    char type[20];
    double value;
    char name[50];
    struct ASTNode *left;
    struct ASTNode *right;
} ASTNode;

// Function prototypes
ASTNode* create_node(char *type, ASTNode *left, ASTNode *right);
ASTNode* create_leaf_num(double value);
ASTNode* create_leaf_id(char *name);
void print_ast(ASTNode *root, int level);

int yylex();
void yyerror(const char *s);
%}

%union {
    double dval;
    char *sval;
    ASTNode *node;
}

%token LET CONST DISPLAY INPUT READ TRY CATCH
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN
%token <sval> IDENTIFIER STRING_LIT
%token <dval> INT_LIT FLOAT_LIT DOUBLE_LIT

%type <node> program stmts stmt expr value

%left ADD SUB
%left MUL DIV MOD
%right POW

%%

program:
    stmts { 
        printf("\n===== ABSTRACT SYNTAX TREE =====\n");
        print_ast($1, 0);
    }
;

stmts:
      stmt                { $$ = $1; }
    | stmts stmt          { $$ = create_node("SEQ", $1, $2); }
;

stmt:
      LET IDENTIFIER ASSIGN expr {
          ASTNode *id = create_leaf_id($2);
          $$ = create_node("ASSIGN", id, $4);
      }
    | DISPLAY expr {
          $$ = create_node("DISPLAY", $2, NULL);
      }
;

expr:
      expr ADD expr { $$ = create_node("ADD", $1, $3); }
    | expr SUB expr { $$ = create_node("SUB", $1, $3); }
    | expr MUL expr { $$ = create_node("MUL", $1, $3); }
    | expr DIV expr { $$ = create_node("DIV", $1, $3); }
    | expr MOD expr { $$ = create_node("MOD", $1, $3); }
    | expr POW expr { $$ = create_node("POW", $1, $3); }
    | LPAREN expr RPAREN { $$ = $2; }
    | value { $$ = $1; }
;

value:
      INT_LIT    { $$ = create_leaf_num($1); }
    | FLOAT_LIT  { $$ = create_leaf_num($1); }
    | DOUBLE_LIT { $$ = create_leaf_num($1); }
    | IDENTIFIER { $$ = create_leaf_id($1); }
;

%%

// ================= IMPLEMENTATION =================

ASTNode* create_node(char *type, ASTNode *left, ASTNode *right) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strcpy(node->type, type);
    node->left = left;
    node->right = right;
    node->value = 0;
    node->name[0] = '\0';
    return node;
}

ASTNode* create_leaf_num(double value) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strcpy(node->type, "NUM");
    node->value = value;
    node->left = node->right = NULL;
    return node;
}

ASTNode* create_leaf_id(char *name) {
    ASTNode *node = malloc(sizeof(ASTNode));
    strcpy(node->type, "ID");
    strcpy(node->name, name);
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
    else
        printf("%s\n", root->type);

    print_ast(root->left, level + 1);
    print_ast(root->right, level + 1);
}

void yyerror(const char *s) {
    printf("Parse error: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}
