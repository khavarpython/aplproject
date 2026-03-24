%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
%}

%option yylineno
%option nodefault
%option noyywrap

DIGIT       [0-9]
LETTER      [a-zA-Z]
ALPHANUM    [a-zA-Z0-9_]

INT_VAL     {DIGIT}+
FLOAT_VAL   {DIGIT}+"."{DIGIT}+
DOUBLE_VAL  {DIGIT}+"."{DIGIT}+[dD]
STRING_VAL  \"([^\"\n\\]|\\.)*\"
CHAR_VAL    \'([^\'\n\\]|\\.)\'
BOOL_VAL    "true"|"false"
NULL_VAL    "null"

ID          {LETTER}{ALPHANUM}*

NEWLINE     \r?\n
WHITESPACE  [ \t\r]+

LINE_CMT    "--"[^\n]*

%%
{WHITESPACE}    { }
{NEWLINE}       { }
{LINE_CMT}      { }

"let"           { return LET;      }
"const"         { return CONST;    }

"try"           { return TRY;      }
"catch"         { return CATCH;    }

"display"       { return DISPLAY;  }
"input"         { return INPUT;    }
"read"          { return READ;     }

{BOOL_VAL}      { yylval.ival = strcmp(yytext, "true") == 0 ? 1 : 0; return BOOL_LIT; }
{NULL_VAL}      { return NULL_LIT;    }
{DOUBLE_VAL}    { yylval.dval = atof(yytext); return DOUBLE_LIT; }
{FLOAT_VAL}     { yylval.dval = atof(yytext); return FLOAT_LIT;  }
{INT_VAL}       { yylval.ival = atoi(yytext); return INT_LIT;    }
{STRING_VAL}    { yylval.sval = strdup(yytext); return STRING_LIT; }
{CHAR_VAL}      { yylval.ival = yytext[1]; return CHAR_LIT; }

"+"             { return ADD;    }
"-"             { return SUB;    }
"**"            { return POW;    }
"*"             { return MUL;    }
"/"             { return DIV;    }
"%"             { return MOD;    }
"="             { return ASSIGN; }

"("             { return LPAREN; }
")"             { return RPAREN; }

{ID}            { yylval.sval = strdup(yytext); return IDENTIFIER;  }

.               { printf("[LEXICAL ERROR] Line %d: Unknown character '%s'\n", yylineno, yytext); }
%%
