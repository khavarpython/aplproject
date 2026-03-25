#ifndef AST_H
#define AST_H

typedef struct ASTNode
{
    char type[20];
    double value;
    char name[50];
    char sval[256];
    struct ASTNode *left;
    struct ASTNode *right;
} ASTNode;

ASTNode *create_node(char *type, ASTNode *left, ASTNode *right);
ASTNode *create_leaf_num(double value);
ASTNode *create_leaf_id(char *name);
ASTNode *create_leaf_str(char *s);
void print_ast(ASTNode *root, int level);

#endif