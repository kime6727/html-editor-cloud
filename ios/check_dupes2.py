with open('LanguageManager.swift', 'r') as f:
    content = f.read()

# Split by language sections more carefully
# Find "en": [ and its closing ],
import re

langs = ['en', 'zh-Hans', 'zh-Hant', 'ja', 'ko', 'fr', 'de', 'es', 'it', 'pt', 'ru', 'ar', 'hi', 'tr', 'vi', 'th', 'id', 'nl', 'pl', 'ms']

for lang in langs:
    pattern = rf'"{lang}":\s*\['
    match = re.search(pattern, content)
    if not match:
        print(f"NOT FOUND: {lang}")
        continue
    
    start = match.end()
    # Find matching closing bracket
    depth = 1
    pos = start
    while pos < len(content) and depth > 0:
        if content[pos] == '[':
            depth += 1
        elif content[pos] == ']':
            depth -= 1
        pos += 1
    
    section = content[start:pos-1]
    
    # Extract only top-level keys (pattern: "key": "value" or "key": "value with special chars")
    # Match "key": at the start of a key-value pair
    keys = []
    # Split section by ", then look for pattern "key": "
    parts = section.split('", "')
    for part in parts:
        # Each part should start with key": "value...
        if '": "' in part:
            key = part.split('": "')[0].strip().strip('"')
            # The key might have leading whitespace or be at start
            if key:
                keys.append(key)
    
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
