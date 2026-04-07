import sys
import os
from dotenv import load_dotenv
from openai import AzureOpenAI

load_dotenv()

# Create ai client
client = AzureOpenAI(
    api_version="2024-12-01-preview",
    azure_endpoint=os.environ["AZURE_ENDPOINT"],
    api_key=os.environ["AZURE_API_KEY"],
)

# Open the source code
with open(sys.argv[1], "r") as f:
    source = f.read()

# Create the response for the ai
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {
            "role": "system",
            "content": "You are an interpreter for a programming language. When given source code, execute it and only the output it would produce. Do not explain, just show the program output."
        },
        {
            "role": "user",
            "content": f"Execute this program:\n\n{source}"
        }
    ],
    max_tokens=1024
)

print("\nAI OUTPUT")
print(response.choices[0].message.content)