# Instructions for Running

1. Generate parser:
```bash
   bison -d parser.y
```

2. Generate lexer:
```bash
   lex lexer.l
```

3. Compile:
```bash
   gcc parser.tab.c lex.yy.c -o myparser -lm
```

4. Run with input file:
```bash
   ./myparser < test.txt
```
