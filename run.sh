#!/bin/bash
set -e
bison -d parser.y
lex lexer.l
gcc parser.tab.c lex.yy.c -o myparser -lm
./myparser < "$1"
python3 ai_script.py "$1"