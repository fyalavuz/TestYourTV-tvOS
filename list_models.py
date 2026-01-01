import os
import requests
import json

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    try:
        with open(os.path.expanduser("~/.zshrc"), "r") as f:
            for line in f:
                if "GEMINI_API_KEY" in line:
                    API_KEY = line.split('=')[1].strip().strip('"')
                    break
    except:
        pass

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"
response = requests.get(url)
print(json.dumps(response.json(), indent=2))
