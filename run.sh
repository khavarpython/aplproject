#!/bin/bash
set -e
bison -d parser.y
lex lexer.l
gcc parser.tab.c lex.yy.c -o myparser -lm
./myparser < test.txt
