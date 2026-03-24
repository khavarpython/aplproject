import sys
import os
from dotenv import load_dotenv
from openai import AzureOpenAI

load_dotenv()

client = AzureOpenAI(
    api_version="2024-12-01-preview",
    azure_endpoint=os.environ["AZURE_ENDPOINT"],
    api_key=os.environ["AZURE_API_KEY"],
)

if len(sys.argv) < 2:
    print("Usage: python ai_script.py <source_file>")
    sys.exit(1)

with open(sys.argv[1], "r") as f:
    source = f.read()

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {
            "role": "system",
            "content": "You are an interpreter for a mini programming language. When given source code, execute it and show ONLY the output it would produce. Do not explain, just show the program output."
        },
        {
            "role": "user",
            "content": f"Execute this program:\n\n{source}"
        }
    ],
    max_tokens=1024
)

print("=" * 40)
print("LLM EXECUTION OUTPUT (Azure OpenAI)")
print("=" * 40)
print(response.choices[0].message.content)