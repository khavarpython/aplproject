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
SIGN        [+-]

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
BLOCK_CMT   "/*"([^*]|\*[^/])*"*/"

%%
{WHITESPACE}    { }
{NEWLINE}       { }
{LINE_CMT}      { }
{BLOCK_CMT}     { }

"let"           { return LET;      }
"const"         { return CONST;    }
"if"            { return IF;       }
"else"          { return ELSE;     }
"elif"          { return ELIF;     }
"for"           { return FOR;      }
"break"         { return BREAK;    }
"continue"      { return CONTINUE; }
"return"        { return RETURN;   }

"try"           { return TRY;      }
"catch"         { return CATCH;    }
"finally"       { return FINALLY;  }
"throw"         { return THROW;    }

"display"       { return DISPLAY;  }
"input"         { return INPUT;    }
"read"          { return READ;     }

{BOOL_VAL}      { return BOOL_LIT;    }
{NULL_VAL}      { return NULL_LIT;    }
{DOUBLE_VAL}    { return DOUBLE_LIT;  }
{FLOAT_VAL}     { return FLOAT_LIT;   }
{INT_VAL}       { return INT_LIT;     }
{STRING_VAL}    { return STRING_LIT;  }
{CHAR_VAL}      { return CHAR_LIT;    }

"+"             { return ADD;    }
"-"             { return SUB;    }
"**"            { return POW;    }
"*"             { return MUL;    }
"/"             { return DIV;    }
"%"             { return MOD;    }

"=="            { return EQUAL;  }
"="             { return ASSIGN;     }

"!="            { return NEQUAL; }
"<="            { return LESS_THAN_E; }
">="            { return GREATER_THAN_E; }
"<"             { return LESS_THAN;  }
">"             { return GREATER_THAN;  }

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
