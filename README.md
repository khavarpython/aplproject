# MyLanguageName Compiler

## Requirements
- GCC
- Bison
- Flex/Lex
- Python 3
- pip

Install dependencies (Ubuntu/WSL):
```bash
sudo apt install gcc bison flex
pip install python-dotenv openai
```

## Setup
1. Clone the repo
2. Copy `.env.example` to `.env`
3. Fill in your Azure API key and endpoint in `.env`

## Build & Run Compiler
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

## Run LLM Comparison
```bash
python3 ai_script.py test.txt
```
