%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "ast.h"

// Symbol Table
#define MAX_SCOPES 32
#define MAX_VARS   100

// Individual Scope
typedef struct {
    Variable vars[MAX_VARS];
    int count;
} Scope;

// Array or Stack of scopes
Scope scope_stack[MAX_SCOPES];

// Tracks the top of the scope
int scope_top = 0;

// Enter a new scope
void push_scope() {
    if (scope_top + 1 >= MAX_SCOPES) { 
        printf("[ERROR] Scope overflow\n"); 
        return; 
        }
    scope_top++;
    scope_stack[scope_top].count = 0;
}

// Leave the current scope
void pop_scope() {
    if (scope_top == 0) { 
        printf("[ERROR] Cannot pop global scope\n"); 
        return; 
        }
    scope_top--;
}

// Sets variable based on scope
void set_var(char *name, Value value) {
    // Gets current scope address
    Scope *cur = &scope_stack[scope_top];

    // Loops through variables in current scope
    for (int i = 0; i < cur->count; i++) {
        // If variable is in the scope, overwrite the value
        if (strcmp(cur->vars[i].name, name) == 0) {
            cur->vars[i].val = value;
            return;
        }
    }

    // If it is not in the scope , Adds the variable name and value to scope 
    strcpy(cur->vars[cur->count].name, name);
    cur->vars[cur->count].val = value;
    cur->count++;
}
 
// Searches through all the scopes, to get the value of the specified variable
Value get_var(char *name) {
    // All the scopes loop
    for (int s = scope_top; s >= 0; s--)
        // All variables in the scope loop
        for (int i = 0; i < scope_stack[s].count; i++)
            if (strcmp(scope_stack[s].vars[i].name, name) == 0)
                return scope_stack[s].vars[i].val;

    printf("[SEMANTIC ERROR] Variable '%s' not defined\n", name);
    return (Value){TYPE_NULL};
}

// Prints a string without the quotes
void display_value(char *s) {
    if (s[0] == '"')
        printf("%.*s", (int)strlen(s) - 2, s + 1);
    else
        printf("%s", s);
}

// Helps with math, returns errors for string
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

// Pointer for the top of the AST
ASTNode *ast_root = NULL;
// Pointer for the generated C code
FILE *cg_out;
// Code Generation Declaration
void codegen(ASTNode *node);

// Gets tokens from lex
int yylex();
// Syntax error
void yyerror(const char *s) { fprintf(stderr, "error: %s\n", s); }
// End of input
int yywrap() { return 1; }
%}

// Tells Yacc what values to expect for tokens
%union {
    char   *sval;
    int     ival;
    double  dval;
    ASTNode *node;
}

// Tokens
%token LET TRY CATCH END DISPLAY INPUT READ
%token NULL_LIT CHAR_LIT
%token ADD SUB MUL DIV MOD POW ASSIGN LPAREN RPAREN

// Tokens with appropriate values
%token <sval> IDENTIFIER STRING_LIT
%token <ival> INT_LIT BOOL_LIT
%token <dval> FLOAT_LIT DOUBLE_LIT

// Non terminals in grammar, produce nodes
%type <node> program stmts stmt expr value
%type <node> display_list display_item
%type <node> assign_stmt print_stmt try_stmt input_stmt

// Precedence
%left ADD SUB
%left MUL DIV MOD
%right POW
%left LPAREN RPAREN

%%

program:
    stmts {
        ast_root = $1;
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
    
        // Adding to AST
        ASTNode *id = create_leaf_id($2);
        $$ = create_node("LET", id, $4);
        free($2);
    }
;

print_stmt:
    DISPLAY display_list {
        $$ = create_node("DISPLAY", $2, NULL);
    }
;

display_list:
    display_item                  { $$ = $1; }
    | display_list display_item   { $$ = create_node("DLIST", $1, $2); }
;

display_item:
    // If what we are printing is a string, create a string leaf
    STRING_LIT {
        $$ = create_leaf_str($1);
        free($1);
    }
    | expr {
        $$ = $1;
    }
;

try_stmt:
    // Entering a try, is a new scope
    TRY     { push_scope(); }
    stmts
    // We leave the try scope and enter a new scope for catch
    CATCH   { pop_scope(); push_scope(); }
    stmts
    // Leave the catch scope
    END     { pop_scope(); }
    {
        // Create try node with try body and catch body as children
        $$ = create_node("TRY", $3, $6);
    }
;

input_stmt:
    INPUT expr READ IDENTIFIER {
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
        // Creates the node
        $$ = create_node("DIV",$1,$3);

        // Checks for divide by 0
        if (to_num($3->val) == 0) {
            $$->val.type=TYPE_DOUBLE; 
            $$->val.dval=0;
        } 
        else { // Does the division if it is not divide by 0
            // Sets the value type to double
            $$->val.type=TYPE_DOUBLE; 
            // Stores the result
            $$->val.dval=to_num($1->val)/to_num($3->val);
        }
    }
    | expr MOD expr         {
        $$ = create_node("MOD",$1,$3);
        $$->val.type=TYPE_INT; 
        $$->val.ival=(int)to_num($1->val)%(int)to_num($3->val);
    }
    | expr POW expr         {
        $$ = create_node("POW",$1,$3);
        $$->val.type=TYPE_DOUBLE; 
        $$->val.dval=pow(to_num($1->val),to_num($3->val));
    }
    | LPAREN expr RPAREN    { $$ = $2; }
    | SUB expr %prec MUL    { $$ = create_node("NEG",$2,NULL); $$->val.type=TYPE_DOUBLE; $$->val.dval=-to_num($2->val); } // Negative Numbers
;

value:
    BOOL_LIT      { $$ = create_leaf_num(0); }
    | NULL_LIT    { $$ = create_leaf_num(0); }
    | INT_LIT     { $$ = create_leaf_int($1); }
    | FLOAT_LIT   { $$ = create_leaf_num($1); }
    | DOUBLE_LIT  { $$ = create_leaf_num($1); }
    | STRING_LIT  { $$ = create_leaf_str($1); free($1); }
    | IDENTIFIER  {
        // Looks in symbol table for identifier
        Value v = get_var($1);
        
        // Create leaf node
        $$ = create_leaf_id($1);

        // Sets the value to the what we saw in the symbol table
        $$->val = v;
        free($1);
    }
;

%%

// AST IMPLEMENTATION
ASTNode* create_node(char *type, ASTNode *left, ASTNode *right) {
    // Create node
    ASTNode *node = malloc(sizeof(ASTNode));
    // Copy the type of node
    strncpy(node->type, type, 19);
    node->type[19] = '\0';

    // Set the children
    node->left  = left;
    node->right = right;

    // Leave the value and name empty to be filled in later
    node->val   = (Value){TYPE_NULL};
    node->name[0] = '\0';
    return node;
}

ASTNode* create_leaf_num(double d) {
    // Create node 
    ASTNode *n = malloc(sizeof(ASTNode));
    // Set the type to num(double)
    strcpy(n->type, "NUM");
    n->val.type = TYPE_DOUBLE;

    // Set the value
    n->val.dval = d;
    n->name[0] = '\0';

    // Empty children
    n->left = n->right = NULL;
    return n;
}

ASTNode* create_leaf_int(int i) {
    // Create node
    ASTNode *n = malloc(sizeof(ASTNode));
    // Set the type to num(int)
    strcpy(n->type, "NUM");
    n->val.type = TYPE_INT;

    // Set the value 
    n->val.ival = i;
    n->name[0] = '\0';

    // Empty children
    n->left = n->right = NULL;
    return n;
}

ASTNode* create_leaf_id(char *name) {
    // Create node
    ASTNode *n = malloc(sizeof(ASTNode));
    // Set the type to identifier
    strcpy(n->type, "ID");

    // Set the identifier name
    strncpy(n->name, name, 49);
    n->name[49] = '\0';

    // Leave the value and children null
    n->val = (Value){TYPE_NULL};
    n->left = n->right = NULL;
    return n;
}

ASTNode* create_leaf_str(char *s) {
    // Create node
    ASTNode *n = malloc(sizeof(ASTNode));
    // Set the type to string
    strcpy(n->type, "STR");
    n->val.type = TYPE_STRING;

    // Set the string value
    strncpy(n->val.sval, s, 255);
    n->name[0] = '\0';

    // Children null
    n->left = n->right = NULL;
    return n;
}

void print_ast(ASTNode *root, int level) {
    if (!root) return;
    
    // Ident for ever level of the tree
    for (int i = 0; i < level; i++) printf("    ");

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

// Walks the AST and writes the C code into buf
void codegen_expr(ASTNode *node, char *buf, int bufsz) {
    // If the node is null, it writes 0 into the C file
    if (!node) { snprintf(buf, bufsz, "0"); return; }

    // Holds the C code for the left child and the right child
    char L[256] = {0}, R[256] = {0};

    // Writes the actual number into the c file
    if (strcmp(node->type, "NUM") == 0) {
        if (node->val.type == TYPE_INT)
            snprintf(buf, bufsz, "%d", node->val.ival);
        else
            snprintf(buf, bufsz, "%g", node->val.dval);

    }
    // Writes the actual identifier in the c file
    else if (strcmp(node->type, "ID") == 0) {
        snprintf(buf, bufsz, "%s", node->name);

    } 
    // Writes the actual string in the c file
    else if (strcmp(node->type, "STR") == 0) {
        const char *s = node->val.sval;

        // If the string has quotes, write it. If it doesnt then add the quotes then write it
        if (s[0] == '"') snprintf(buf, bufsz, "%s", s);
        else             snprintf(buf, bufsz, "\"%s\"", s);
    } 

    else {
        // Recursivly generate the left and right side for the expressions
        codegen_expr(node->left,  L, sizeof L);
        codegen_expr(node->right, R, sizeof R);

        // Operations
        // Just write the expression into the c file
        if      (strcmp(node->type,"ADD")==0) snprintf(buf,bufsz,"(%s + %s)",L,R);
        else if (strcmp(node->type,"SUB")==0) snprintf(buf,bufsz,"(%s - %s)",L,R);
        else if (strcmp(node->type,"MUL")==0) snprintf(buf,bufsz,"(%s * %s)",L,R);

        // Division has a divide by 0 check
        else if (strcmp(node->type,"DIV")==0) snprintf(buf,bufsz,"((%s) != 0 ? (%s) / (%s) : (_had_error=1, 0.0))",R,L,R);
        // Modulus has a mod by 0 check
        else if (strcmp(node->type,"MOD")==0) snprintf(buf,bufsz,"((%s) != 0 ? (int)(%s) %% (int)(%s) : (_had_error=1, 0))",R,L,R);

        else if (strcmp(node->type,"POW")==0) snprintf(buf,bufsz,"pow(%s,%s)",L,R);
        else if (strcmp(node->type,"NEG")==0) snprintf(buf,bufsz,"(-%s)",L);
        else snprintf(buf, bufsz, "0");
    }
}

// Writes c statements
void codegen(ASTNode *node) {
    if (!node) return;

    // Generates the left side of the sequence then the right side with recursion
    if (strcmp(node->type, "SEQ") == 0) {
        codegen(node->left);
        codegen(node->right);
        return;
    }

    // LET
    if (strcmp(node->type, "LET") == 0) {
        // This will hold the value 
        char expr_buf[512];

        //  Walks the rights side of the let, so the value that we are assigning
        codegen_expr(node->right, expr_buf, sizeof expr_buf);

        // Gets the name of identifier
        const char *varname = node->left->name;

        // If the value on the right is a string, declare as a string else declare as a double
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
        // Splits up the display list until all items are printed
        codegen(node->left);
        codegen(node->right);
        return;
    }

    // STR
    if (strcmp(node->type, "STR") == 0) {
        // Gets the string
        const char *s = node->val.sval;

        // Removes quotes from the string and adds null terminator
        if (s[0] == '"') {
            int len = (int)strlen(s);
            char clean[512];
            strncpy(clean, s + 1, len - 2);
            clean[len - 2] = '\0';

            // %%s become %s in the c file
            fprintf(cg_out, "    printf(\"%%s\", \"%s\");\n", clean);
        } else {
            fprintf(cg_out, "    printf(\"%%s\", \"%s\");\n", s);
        }
        return;
    }

    // TRY / CATCH
    if (strcmp(node->type, "TRY") == 0) {
        // Simulate try and catch using a flag
        // Runs the try body and if any division by 0 occurs then we run the catch body
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
            "    printf(\"Enter value for %s: \");\n"
            "    scanf(\"%%lf\", &%s);\n",
            varname, varname);
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
    // File that we will write to
    const char *cfile = "output.c";
    // Executable
    const char *bin   = "./output";

    // Open the c file
    cg_out = fopen(cfile, "w");
    if (!cg_out) { perror("fopen output.c"); return; }

    // Write all the neccesarry headers
    fprintf(cg_out,
        "#include <stdio.h>\n"
        "#include <string.h>\n"
        "#include <math.h>\n\n"
        "int main(void) {\n");
    
    // Generate the body of the code
    codegen(root);

    // Close the body
    fprintf(cg_out,
        "    return 0;\n"
        "}\n");

    // Close the file
    fclose(cg_out);

    // Compiles the c file with gcc and supresses compiler error messages
    char cmd[256];
    snprintf(cmd, sizeof cmd, "gcc -o %s %s -lm 2>/dev/null", bin, cfile);
    int ret = system(cmd);
    if (ret != 0) {
        printf("Compilation failed.\n");
        return;
    }

    // Prints the output of the c file
    fflush(stdout);
    system(bin);
}

int main() {
    // Intialiaze scope stack
    scope_stack[0].count = 0;
    scope_top = 0;
    // Yacc parse
    yyparse();
    // Compile and execute
    generate_and_run(ast_root);
    return 0;
}
