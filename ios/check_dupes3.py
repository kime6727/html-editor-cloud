with open('LanguageManager.swift', 'r') as f:
    content = f.read()

import re

langs = ['en', 'zh-Hans', 'zh-Hant', 'ja', 'ko', 'fr', 'de', 'es', 'it', 'pt', 'ru', 'ar', 'hi', 'tr', 'vi', 'th', 'id', 'nl', 'pl', 'ms']

for lang in langs:
    pattern = rf'"{lang}":\s*\['
    match = re.search(pattern, content)
    if not match:
        print(f"NOT FOUND: {lang}")
        continue
    
    start = match.end()
    depth = 1
    pos = start
    while pos < len(content) and depth > 0:
        if content[pos] == '[':
            depth += 1
        elif content[pos] == ']':
            depth -= 1
        pos += 1
    
    section = content[start:pos-1]
    
    # Extract keys - match "key": at the beginning
    keys = []
    # Find all occurrences of "key": "value"
    # Use regex to find "key": patterns
    key_pattern = re.findall(r'"([^"]+)":\s*"[^"]*"', section)
    keys = key_pattern
    
    seen = set()
    dupes = set()
    for k in keys:
        if k in seen:
            dupes.add(k)
        seen.add(k)
    
    if dupes:
        print(f"X {lang}: {len(dupes)} dupes: {sorted(dupes)}")
    else:
        print(f"OK {lang}: {len(keys)} keys")

print("Done")
