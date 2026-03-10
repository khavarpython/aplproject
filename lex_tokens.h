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
#define BOOL_LIT 21
#define NULL_LIT 22
#define DOUBLE_LIT 23
#define FLOAT_LIT 24
#define INT_LIT 25
#define STRING_LIT 26
#define CHAR_LIT 27
#define ADD 28
#define SUB 29
#define MUL 30
#define DIV 31
#define MOD 32
#define POW 33
#define ASSIGN 34
#define ASSIGN_ADD 35
#define ASSIGN_SUB 36
#define ASSIGN_MUL 37
#define ASSIGN_DIV 38
#define INCREM 39
#define DECREM 40
#define EQUAL 41
#define NEQUAL 42
#define LESS_THAN 43
#define LESS_THAN_E 44
#define GREATER_THAN 45
#define GREATER_THAN_E 46
#define AND 47
#define OR 48
#define NOT 49
#define LPAREN 50
#define RPAREN 51
#define LBRACE 52
#define RBRACE 53
#define LBRACKET 54
#define RBRACKET 55
#define SEMICOLON 56
#define COLON 57
#define COMMA 58
#define DOT 59
#define IDENTIFIER 60

typedef union
{
    int ival;
    float fval;
    double dval;
    char *sval;
} YYSTYPE;

YYSTYPE yylval;


#endif
