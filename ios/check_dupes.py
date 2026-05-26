import re

with open('LanguageManager.swift', 'r') as f:
    content = f.read()

# Find all language sections
pattern = r'"([a-z-]+)":\s*\['
matches = list(re.finditer(pattern, content))

for idx, match in enumerate(matches):
    lang = match.group(1)
    start = match.end()
    
    # Find the closing bracket for this section
    bracket_depth = 1
    pos = start
    while pos < len(content) and bracket_depth > 0:
        if content[pos] == '[':
            bracket_depth += 1
        elif content[pos] == ']':
            bracket_depth -= 1
        pos += 1
    
    section_text = content[start:pos-1]
    
    # Extract all keys
    keys = re.findall(r'"([^"]+)":\s*"', section_text)
    seen = {}
    dupes = {}
    for i, k in enumerate(keys):
        if k in seen:
            dupes[k] = (seen[k], i)
        else:
            seen[k] = i
    
    if dupes:
        print(f"\nX {lang}: {len(dupes)} duplicate(s)!")
        for k, (first, second) in dupes.items():
            print(f'  "{k}" first at index {first}, duplicate at index {second}')
    else:
        print(f"OK {lang}: {len(keys)} keys, no duplicates")

print("Done")
