# APL Compiler
## Requirements
- GCC
- Bison
- Flex
- Python 3
- pip
- openai
- python-dotenv

## Setup
### 1. Install dependencies (Ubuntu/WSL)
```bash
sudo apt update && sudo apt install gcc bison flex python3 python3-pip -y
sudo apt install libgtk-3-dev gcc
pip install openai python-dotenv
```

### 2. Clone the repo
```bash
git clone https://github.com/khavarpython/aplproject
```

### 3. Configure environment
Create a `.env` file in the project root:
```
AZURE_ENDPOINT=https://your-resource-name.openai.azure.com/
AZURE_API_KEY=your-api-key-here
```

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
