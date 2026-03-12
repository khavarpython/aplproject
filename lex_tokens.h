#ifndef LEX_TOKENS_H
#define LEX_TOKENS_H

#define IF 1
#define ELSE 2
#define ELIF 3
#define WHILE 4
#define FOR 5
#define DO 6
#define BREAK 7
#define CONTINUE 8
#define RETURN 9
#define SWITCH 10
#define CASE 11
#define DEFAULT 12
#define TRY 13
#define CATCH 14
#define FINALLY 15
#define THROW 16
#define FUNC 17
#define DISPLAY 18
#define INPUT 19
#define READ 20
#define LET 21
#define CONST 22
#define BOOL_LIT 23
#define NULL_LIT 24
#define DOUBLE_LIT 25
#define FLOAT_LIT 26
#define INT_LIT 27
#define STRING_LIT 28
#define CHAR_LIT 29
#define ADD 30
#define SUB 31
#define MUL 32
#define DIV 33
#define MOD 34
#define POW 35
#define ASSIGN 36
#define ASSIGN_ADD 37
#define ASSIGN_SUB 38
#define ASSIGN_MUL 39
#define ASSIGN_DIV 40
#define INCREM 41
#define DECREM 42
#define EQUAL 43
#define NEQUAL 44
#define LESS_THAN 45
#define LESS_THAN_E 46
#define GREATER_THAN 47
#define GREATER_THAN_E 48
#define AND 49
#define OR 50
#define NOT 51
#define LPAREN 52
#define RPAREN 53
#define LBRACE 54
#define RBRACE 55
#define LBRACKET 56
#define RBRACKET 57
#define SEMICOLON 58
#define COLON 59
#define COMMA 60
#define DOT 61
#define IDENTIFIER 62

typedef union
{
    int ival;
    float fval;
    double dval;
    char *sval;
} YYSTYPE;
YYSTYPE yylval;
#endif
