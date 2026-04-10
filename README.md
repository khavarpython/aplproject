# APL Compiler
## Requirements

- GCC
- Bison
- Flex
- Python 3
- pip
- openai
- python-dotenv
- GTK 3

## Setup

### 1. Install dependencies (Ubuntu/WSL)

```bash
sudo apt update && sudo apt install gcc bison flex python3 python3-pip libgtk-3-dev -y
pip install openai python-dotenv
```

### 2. Clone the repo

```bash
git clone https://github.com/khavarpython/aplproject
cd aplproject
```

### 3. Configure environment

Create a `.env` file in the project root:
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
## Build & Run

### 1. Compile the IDE

```bash
gcc IDE.c -o IDE $(pkg-config --cflags --libs gtk+-3.0)
```

### 2. Run

```bash
./IDE
```

## Run LLM Comparison
```bash
python3 ai_script.py test.txt
```
