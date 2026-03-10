%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lex_tokens.h"
%}

%option yylineno
%option nodefault

DIGIT       [0-9]
LETTER      [a-zA-Z]
ALPHANUM    [a-zA-Z0-9_]
SIGN        [+-]

INT_LIT     {DIGIT}+
FLOAT_LIT   {DIGIT}+"."{DIGIT}+
DOUBLE_LIT  {DIGIT}+"."{DIGIT}+[dD]
STRING_LIT  \"([^\"\n\\]|\\.)*\"
CHAR_LIT    \'([^\'\n\\]|\\.)\'
BOOL_LIT    "true"|"false"
NULL_LIT    "null"

ID          {LETTER}{ALPHANUM}*

NEWLINE     \r?\n
WHITESPACE  [ \t\r]+

LINE_CMT    "//"[^\n]*
BLOCK_CMT   "/*"([^*]|\*+[^*/])*\*+"/"

%%
{WHITESPACE}    { }
{NEWLINE}       { }
{LINE_CMT}      { }
{BLOCK_CMT}     { }

"if"            { return IF;       }
"else"          { return ELSE;     }
"elif"          { return ELIF;     }
"while"         { return WHILE;    }
"for"           { return FOR;      }
"do"            { return DO;       }
"break"         { return BREAK;    }
"continue"      { return CONTINUE; }
"return"        { return RETURN;   }
"switch"        { return SWITCH;   }
"case"          { return CASE;     }
"default"       { return DEFAULT;  }

"try"           { return TRY;      }
"catch"         { return CATCH;    }
"finally"       { return FINALLY;  }
"throw"         { return THROW;    }

"func"          { return FUNC;     }

"print"         { return DISPLAY;  }
"input"         { return INPUT;    }
"read"          { return READ;     }

{BOOL_LIT}      { return BOOL_LIT;    }
{NULL_LIT}      { return NULL_LIT;    }
{DOUBLE_LIT}    { return DOUBLE_LIT;  }
{FLOAT_LIT}     { return FLOAT_LIT;   }
{INT_LIT}       { return INT_LIT;     }
{STRING_LIT}    { return STRING_LIT;  }
{CHAR_LIT}      { return CHAR_LIT;    }

"+"             { return ADD;    }
"-"             { return SUB;    }
"*"             { return MUL;    }
"/"             { return DIV;    }
"%"             { return MOD;    }
"**"            { return POW;    }

"="             { return ASSIGN;     }
"+="            { return ASSIGN_ADD; }
"-="            { return ASSIGN_SUB; }
"*="            { return ASSIGN_MUL; }
"/="            { return ASSIGN_DIV; }

"++"            { return INCREM; }
"--"            { return DECREM; }

"=="            { return EQUAL;  }
"!="            { return NEQUAL; }
"<"             { return LESS_THAN;  }
"<="            { return LESS_THAN_E; }
">"             { return GREATER_THAN;  }
">="            { return GREATER_THAN_E; }

"&&"            { return AND; }
"||"            { return OR;  }
"!"             { return NOT; }

"("             { return LPAREN;    }
")"             { return RPAREN;    }
"{"             { return LBRACE;    }
"}"             { return RBRACE;    }
"["             { return LBRACKET;  }
"]"             { return RBRACKET;  }
";"             { return SEMICOLON; }
":"             { return COLON;     }
","             { return COMMA;     }
"."             { return DOT;       }

{ID}            { yylval.sval = strdup(yytext); return IDENTIFIER;  }

.               { printf("[LEXICAL ERROR] Line %d: Unknown character '%s'\n", yylineno, yytext); }

%%

int yywrap(void) { return 1; }

int main(int argc, char* argv[]) {
    if (argc > 1) {
        FILE* f = fopen(argv[1], "r");
        if (!f) { printf("Error: Cannot open file '%s'\n", argv[1]); return 1; }
        yyin = f;
    }
    
    int token;
    while ((token = yylex()) != 0) {  
    }
    
    return 0;
}
