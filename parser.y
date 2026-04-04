%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "ast.h"

// Symbol Table
#define MAX_SCOPES 32
#define MAX_VARS   100

typedef struct {
    Variable vars[MAX_VARS];
    int count;
} Scope;

Scope scope_stack[MAX_SCOPES];
int scope_top = 0;

void push_scope() {
    if (scope_top + 1 >= MAX_SCOPES) { printf("[ERROR] Scope overflow\n"); return; }
    scope_top++;
    scope_stack[scope_top].count = 0;
}

void pop_scope() {
    if (scope_top == 0) { printf("[ERROR] Cannot pop global scope\n"); return; }
    scope_top--;
}

void set_var(char *name, Value value) {
    Scope *cur = &scope_stack[scope_top];
    for (int i = 0; i < cur->count; i++) {
        if (strcmp(cur->vars[i].name, name) == 0) {
            cur->vars[i].val = value;
            return;
        }
    }
    strcpy(cur->vars[cur->count].name, name);
    cur->vars[cur->count].val = value;
    cur->count++;
}

Value get_var(char *name) {
    for (int s = scope_top; s >= 0; s--)
        for (int i = 0; i < scope_stack[s].count; i++)
            if (strcmp(scope_stack[s].vars[i].name, name) == 0)
                return scope_stack[s].vars[i].val;
    printf("[SEMANTIC ERROR] Variable '%s' not defined\n", name);
    return (Value){TYPE_NULL};
}

char num_buf[50];

void display_value(char *s) {
    if (s[0] == '"')
        printf("%.*s", (int)strlen(s) - 2, s + 1);
    else
        printf("%s", s);
}

double to_num(Value v) {
    if (v.type == TYPE_INT)    return v.ival;
    if (v.type == TYPE_DOUBLE) return v.dval;
    if (v.type == TYPE_STRING) {
        printf("[TYPE ERROR] Cannot use string in numeric expression\n");
        return nan("");
    }
    printf("[TYPE ERROR] Expected number\n");
    return nan("");
}

ASTNode *ast_root = NULL;
FILE *cg_out;
void codegen(ASTNode *node);

int yylex();
void yyerror(const char *s) { fprintf(stderr, "error: %s\n", s); }
int yywrap() { return 1; }
%}

%union {
    char   *sval;
    int     ival;
    double  dval;
    ASTNode *node;
}

%token LET TRY CATCH END DISPLAY INPUT READ
%token NULL_LIT CHAR_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN

%token <sval> IDENTIFIER STRING_LIT
%token <ival> INT_LIT BOOL_LIT
%token <dval> FLOAT_LIT DOUBLE_LIT

%type <node> program stmts stmt expr value
%type <node> display_list display_item
%type <node> assign_stmt print_stmt try_stmt input_stmt

%left ADD SUB
%left MUL DIV MOD
%right POW
%left LPAREN RPAREN

%%

program:
    stmts {
        ast_root = $1;
        printf("\n ABSTRACT SYNTAX TREE \n");
        print_ast($1, 0);
        $$ = $1;
    }
;

stmts:
    /* empty */         { $$ = NULL; }
    | stmts stmt        { $$ = ($1 == NULL) ? $2 : create_node("SEQ", $1, $2); }
;

stmt:
    assign_stmt { $$ = $1; }
    | print_stmt  { $$ = $1; }
    | try_stmt    { $$ = $1; }
    | input_stmt  { $$ = $1; }
;

assign_stmt:
    LET IDENTIFIER ASSIGN expr {
        set_var($2, $4->val);
        if ($4->val.type == TYPE_INT)          printf("[ASSIGN] %s = %d\n", $2, $4->val.ival);
        else if ($4->val.type == TYPE_STRING)  printf("[ASSIGN] %s = %s\n", $2, $4->val.sval);
        else                                   printf("[ASSIGN] %s = %g\n", $2, $4->val.dval);
        ASTNode *id = create_leaf_id($2);
        $$ = create_node("LET", id, $4);
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
        if ($1->val.type == TYPE_INT)          printf("%d", $1->val.ival);
        else if ($1->val.type == TYPE_STRING)  display_value($1->val.sval);
        else                                   printf("%g", $1->val.dval);
        $$ = $1;
    }
;

try_stmt:
    TRY  { push_scope(); }
    stmts
    CATCH { pop_scope(); push_scope(); }
    stmts
    END  { pop_scope(); }
    {
        $$ = create_node("TRY", $3, $6);
    }
;

input_stmt:
    INPUT expr READ IDENTIFIER {
        double val;
        printf("Enter value for %s: ", $4);
        scanf("%lf", &val);
        Value v; v.type = TYPE_DOUBLE; 
        v.dval = val;
        set_var($4, v);
        ASTNode *id = create_leaf_id($4);
        $$ = create_node("INPUT", $2, id);
        free($4);
    }
;

expr:
    value                   { $$ = $1; }
    | expr ADD expr         { $$ = create_node("ADD",$1,$3); $$->val.type=TYPE_DOUBLE; $$->val.dval=to_num($1->val)+to_num($3->val); }
    | expr SUB expr         { $$ = create_node("SUB",$1,$3); $$->val.type=TYPE_DOUBLE; $$->val.dval=to_num($1->val)-to_num($3->val); }
    | expr MUL expr         { $$ = create_node("MUL",$1,$3); $$->val.type=TYPE_DOUBLE; $$->val.dval=to_num($1->val)*to_num($3->val); }
    | expr DIV expr         {
        $$ = create_node("DIV",$1,$3);
        if (to_num($3->val) == 0) {
            printf("[RUNTIME ERROR] Division by zero\n");
            $$->val.type=TYPE_DOUBLE; $$->val.dval=0;
        } else {
            $$->val.type=TYPE_DOUBLE; $$->val.dval=to_num($1->val)/to_num($3->val);
        }
    }
    | expr MOD expr         {
        $$ = create_node("MOD",$1,$3);
        $$->val.type=TYPE_INT; $$->val.ival=(int)to_num($1->val)%(int)to_num($3->val);
    }
    | expr POW expr         {
        $$ = create_node("POW",$1,$3);
        $$->val.type=TYPE_DOUBLE; $$->val.dval=pow(to_num($1->val),to_num($3->val));
    }
    | LPAREN expr RPAREN    { $$ = $2; }
    | SUB expr %prec MUL    { $$ = create_node("NEG",$2,NULL); $$->val.type=TYPE_DOUBLE; $$->val.dval=-to_num($2->val); }
;

value:
    BOOL_LIT      { $$ = create_leaf_num(0); }
    | NULL_LIT    { $$ = create_leaf_num(0); }
    | INT_LIT     { $$ = create_leaf_int($1); }
    | FLOAT_LIT   { $$ = create_leaf_num($1); }
    | DOUBLE_LIT  { $$ = create_leaf_num($1); }
    | STRING_LIT  { $$ = create_leaf_str($1); free($1); }
    | IDENTIFIER  {
        Value v = get_var($1);
        $$ = create_leaf_id($1);
        $$->val = v;
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
    node->val   = (Value){TYPE_NULL};
    node->name[0] = '\0';
    return node;
}

ASTNode* create_leaf_num(double d) {
    ASTNode *n = malloc(sizeof(ASTNode));
    strcpy(n->type, "NUM");
    n->val.type = TYPE_DOUBLE;
    n->val.dval = d;
    n->name[0] = '\0';
    n->left = n->right = NULL;
    return n;
}

ASTNode* create_leaf_int(int i) {
    ASTNode *n = malloc(sizeof(ASTNode));
    strcpy(n->type, "NUM");
    n->val.type = TYPE_INT;
    n->val.ival = i;
    n->name[0] = '\0';
    n->left = n->right = NULL;
    return n;
}

ASTNode* create_leaf_id(char *name) {
    ASTNode *n = malloc(sizeof(ASTNode));
    strcpy(n->type, "ID");
    strncpy(n->name, name, 49);
    n->name[49] = '\0';
    n->val = (Value){TYPE_NULL};
    n->left = n->right = NULL;
    return n;
}

ASTNode* create_leaf_str(char *s) {
    ASTNode *n = malloc(sizeof(ASTNode));
    strcpy(n->type, "STR");
    n->val.type = TYPE_STRING;
    strncpy(n->val.sval, s, 255);
    n->name[0] = '\0';
    n->left = n->right = NULL;
    return n;
}

void print_ast(ASTNode *root, int level) {
    if (!root) return;
    for (int i = 0; i < level; i++) printf("  ");

    if (strcmp(root->type, "NUM") == 0) {
        if (root->val.type == TYPE_INT) printf("NUM(%d)\n", root->val.ival);
        else printf("NUM(%g)\n", root->val.dval);
    }
    else if (strcmp(root->type, "ID") == 0)
        printf("ID(%s)\n", root->name);
    else if (strcmp(root->type, "STR") == 0)
        printf("STR(%s)\n", root->val.sval);
    else
        printf("%s\n", root->type);

    print_ast(root->left,  level + 1);
    print_ast(root->right, level + 1);
}

// CODE GENERATION
int in_try_block = 0;
void codegen_expr(ASTNode *node, char *buf, int bufsz) {
    if (!node) { snprintf(buf, bufsz, "0"); return; }

    char L[256] = {0}, R[256] = {0};

    if (strcmp(node->type, "NUM") == 0) {
        if (node->val.type == TYPE_INT)
            snprintf(buf, bufsz, "%d", node->val.ival);
        else
            snprintf(buf, bufsz, "%g", node->val.dval);

    } else if (strcmp(node->type, "ID") == 0) {
        snprintf(buf, bufsz, "%s", node->name);

    } else if (strcmp(node->type, "STR") == 0) {
        const char *s = node->val.sval;
        if (s[0] == '"') snprintf(buf, bufsz, "%s", s);
        else             snprintf(buf, bufsz, "\"%s\"", s);

    } else {
        codegen_expr(node->left,  L, sizeof L);
        codegen_expr(node->right, R, sizeof R);

        if      (strcmp(node->type,"ADD")==0) snprintf(buf,bufsz,"(%s + %s)",L,R);
        else if (strcmp(node->type,"SUB")==0) snprintf(buf,bufsz,"(%s - %s)",L,R);
        else if (strcmp(node->type,"MUL")==0) snprintf(buf,bufsz,"(%s * %s)",L,R);
        else if (strcmp(node->type,"DIV")==0)
            snprintf(buf,bufsz,"((%s) != 0 ? (%s) / (%s) : (_had_error=1, 0.0))",R,L,R);
        else if (strcmp(node->type,"MOD")==0)
            snprintf(buf,bufsz,"((%s) != 0 ? (int)(%s) %% (int)(%s) : (_had_error=1, 0))",R,L,R);
        else if (strcmp(node->type,"POW")==0) snprintf(buf,bufsz,"pow(%s,%s)",L,R);
        else if (strcmp(node->type,"NEG")==0) snprintf(buf,bufsz,"(-%s)",L);
        else snprintf(buf, bufsz, "0");
    }
}

void codegen(ASTNode *node) {
    if (!node) return;

    if (strcmp(node->type, "SEQ") == 0) {
        codegen(node->left);
        codegen(node->right);
        return;
    }

    // LET
    if (strcmp(node->type, "LET") == 0) {
        char expr_buf[512];
        codegen_expr(node->right, expr_buf, sizeof expr_buf);
        const char *varname = node->left->name;

        if (node->right->val.type == TYPE_STRING) {
            fprintf(cg_out, "    char *%s = %s;\n", varname, expr_buf);
        } else {
            fprintf(cg_out, "    double %s = %s;\n", varname, expr_buf);
        }
        return;
    }

    // DISPLAY
    if (strcmp(node->type, "DISPLAY") == 0) {
        codegen(node->left);
        fprintf(cg_out, "    printf(\"\\n\");\n");
        return;
    }

    // DLIST
    if (strcmp(node->type, "DLIST") == 0) {
        codegen(node->left);
        codegen(node->right);
        return;
    }

    // STR
    if (strcmp(node->type, "STR") == 0) {
        const char *s = node->val.sval;
        if (s[0] == '"') {
            int len = (int)strlen(s);
            char clean[512];
            strncpy(clean, s + 1, len - 2);
            clean[len - 2] = '\0';
            fprintf(cg_out, "    printf(\"%%s\", \"%s\");\n", clean);
        } else {
            fprintf(cg_out, "    printf(\"%%s\", \"%s\");\n", s);
        }
        return;
    }

    // TRY / CATCH
    if (strcmp(node->type, "TRY") == 0) {
        fprintf(cg_out,
            "    {\n"
            "        int _had_error = 0;\n"
            "        //try\n");
        in_try_block = 1;
        codegen(node->left);
        in_try_block = 0;
        fprintf(cg_out,
            "        //catch\n"
            "        if (_had_error) {\n");
        codegen(node->right);
        fprintf(cg_out,
            "        }\n"
            "    }\n");
        return;
    }

    // INPUT
    if (strcmp(node->type, "INPUT") == 0) {
        const char *varname = node->right->name;
        fprintf(cg_out,
            "    {\n"
            "        double %s = 0;\n"
            "        printf(\"Enter value for %s: \");\n"
            "        if (scanf(\"%%lf\", &%s) != 1) {\n"
            "            printf(\"[RUNTIME ERROR] Invalid input for %s\\n\");\n"
            "        } else {\n"
            "            printf(\"%s = %%g\\n\", %s);\n"
            "        }\n"
            "    }\n",
            varname, varname, varname, varname, varname, varname);
        return;
    }

    {
        char expr_buf[512];
        codegen_expr(node, expr_buf, sizeof expr_buf);
        if (node->val.type == TYPE_STRING)
            fprintf(cg_out, "    printf(\"%%s\", %s);\n", expr_buf);
        else
            fprintf(cg_out, "    printf(\"%%g\", (double)(%s));\n", expr_buf);
    }
}

void generate_and_run(ASTNode *root) {
    const char *cfile = "output.c";
    const char *bin   = "./output";

    cg_out = fopen(cfile, "w");
    if (!cg_out) { perror("fopen output.c"); return; }

    fprintf(cg_out,
        "#include <stdio.h>\n"
        "#include <string.h>\n"
        "#include <math.h>\n\n"
        "int main(void) {\n");

    codegen(root);

    fprintf(cg_out,
        "    return 0;\n"
        "}\n");

    fclose(cg_out);

    char cmd[256];
    snprintf(cmd, sizeof cmd, "gcc -o %s %s -lm 2>/dev/null", bin, cfile);
    int ret = system(cmd);
    if (ret != 0) {
        printf("Compilation failed.\n");
        return;
    }

    printf("\nOUTPUT\n");
    fflush(stdout);
    system(bin);
}

int main() {
    scope_stack[0].count = 0;
    scope_top = 0;
    yyparse();
    generate_and_run(ast_root);
    return 0;
}
