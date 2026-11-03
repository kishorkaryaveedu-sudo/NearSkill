import json
import urllib.request
import os

os.makedirs('stitch_html', exist_ok=True)

with open('/home/heisenberg/.gemini/antigravity/brain/f4df5d05-d85c-4990-a169-7b1d98f3c28e/.system_generated/steps/111/output.txt', 'r') as f:
    data = json.load(f)

for screen in data['screens']:
    title = screen['title'].replace(' ', '_').lower()
    url = screen['htmlCode']['downloadUrl']
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req) as response:
            html = response.read().decode('utf-8')
            with open(f'stitch_html/{title}.html', 'w') as out:
                out.write(html)
            print(f"Downloaded {title}.html")
    except Exception as e:
        print(f"Failed to download {title}: {e}")
