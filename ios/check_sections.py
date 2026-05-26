with open('LanguageManager.swift', 'r') as f:
    lines = f.readlines()

import re

# Find line numbers where each language section starts and ends
sections = []
current_lang = None
start_line = None

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    # Match language start: "en": [ or "zh-Hans": [
    match = re.match(r'^"([a-z-]+)":\s*\[\s*$', stripped)
    if match:
        if current_lang:
            sections.append((current_lang, start_line, i-1))
        current_lang = match.group(1)
        start_line = i
    elif stripped == '],' and current_lang:
        sections.append((current_lang, start_line, i))
        current_lang = None
        start_line = None

if current_lang:
    sections.append((current_lang, start_line, len(lines)))

print(f"Found {len(sections)} sections")

for lang, start, end in sections:
    section_text = ''.join(lines[start-1:end])
    keys = re.findall(r'"([^"]+)":\s*"', section_text)
    
    seen = set()
    dupes = {}
    for i, k in enumerate(keys):
        if k in seen:
            if k not in dupes:
                dupes[k] = [seen[k]]
            dupes[k].append(i)
        seen[k] = i
    
    if dupes:
        print(f"\nX {lang} (lines {start}-{end}): {len(dupes)} duplicate(s)")
        for k, positions in dupes.items():
            print(f'  "{k}" at positions {positions}')
    else:
        print(f"OK {lang} (lines {start}-{end}): {len(keys)} keys")

print("\nDone")
