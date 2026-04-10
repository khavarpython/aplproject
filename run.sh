#!/bin/bash
set -e
bison -d parser.y 2>/dev/null
lex lexer.l 2>/dev/null
gcc parser.tab.c lex.yy.c -o myparser -lm 2>/dev/null
cat "$1" | ./myparser
echo "~~SPLIT~~"
python3 ai_script.py "$1"