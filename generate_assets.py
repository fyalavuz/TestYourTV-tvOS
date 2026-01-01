import os
import requests
import json
import sys
import base64

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

def generate_image(prompt, output_file):
    # Image Generation icin Experimental Model
    model_name = "gemini-2.0-flash-exp-image-generation"
    print(f"🍌 Deneniyor: {model_name} ile '{prompt}'...")
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={API_KEY}"
    
    headers = {
        "Content-Type": "application/json"
    }
    
    data = {
      "contents": [
        {
          "parts": [
            {
              "text": prompt
            }
          ]
        }
      ],
      # responseMimeType kaldirildi, varsayilan birakildi.
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        
        if response.status_code == 200:
            result = response.json()
            try:
                # Gemini Image Gen modelleri genelde inlineData doner
                part = result["candidates"][0]["content"]["parts"][0]
                
                if "inlineData" in part:
                    image_data = part["inlineData"]["data"]
                    with open(output_file, "wb") as f:
                        f.write(base64.b64decode(image_data))
                    print(f"✅ Gorsel basariyla kaydedildi: {output_file}")
                else:
                    print("⚠️ API metin dondu (Gorsel uretemedi):", json.dumps(part, indent=2))
                    
            except (KeyError, IndexError) as e:
                print("⚠️ API yanit yapisi beklenmedik:", json.dumps(result, indent=2))
        else:
            print(f"❌ API Hatasi ({response.status_code}): {response.text}")
            
    except Exception as e:
        print(f"❌ Bir hata olustu: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Kullanim: python3 generate_assets.py <output_path> <prompt>")
    else:
        generate_image(sys.argv[2], sys.argv[1])