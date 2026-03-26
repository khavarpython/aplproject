# APL Compiler

## Requirements
- GCC
- Bison
- Flex
- Python 3
- pip

## Setup

### 1. Install dependencies (Ubuntu/WSL)

### 2. Clone the repo

### 3. Configure environment


## Quick Start (Recommended)
```bash
chmod +x run.sh
./run.sh
```

---

## Manual Build & Run

### 1. Generate parser
```bash
bison -d parser.y
```

### 2. Generate lexer
```bash
lex lexer.l
```

### 3. Compile
```bash
gcc parser.tab.c lex.yy.c -o myparser -lm
```

### 4. Run with input file
```bash
./myparser < test.txt
```

---

## Run LLM Comparison
```bash
python3 ai_script.py test.txt
```
