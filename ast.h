#ifndef AST_H
#define AST_H

typedef enum
{
    TYPE_INT,
    TYPE_DOUBLE,
    TYPE_STRING,
    TYPE_BOOL,
    TYPE_NULL
} VType;

typedef struct
{
    VType type;
    union
    {
        int ival;
        double dval;
        char sval[256];
    };
} Value;

typedef struct ASTNode
{
    char type[20];
    char name[50];
    Value val;
    struct ASTNode *left, *right;
} ASTNode;

ASTNode *create_node(char *type, ASTNode *left, ASTNode *right);
ASTNode *create_leaf_num(double d);
ASTNode *create_leaf_int(int i);
ASTNode *create_leaf_str(char *s);
ASTNode *create_leaf_id(char *name);
void print_ast(ASTNode *root, int level);

#endif