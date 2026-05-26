with open('LanguageManager.swift', 'r') as f:
    lines = f.readlines()

# Manual parsing - find each "key": "value" pair line by line
import re

# Check en section (lines 102-168)
print("=== Parsing en section line by line ===")
en_keys = []
for i in range(101, min(168, len(lines))):
    line = lines[i].strip()
    if not line or line in [']', '],']:
        continue
    # Extract key from "key": "value"
    match = re.match(r'^"([^"]+)":', line)
    if match:
        en_keys.append(match.group(1))

seen = {}
dupes = []
for k in en_keys:
    if k in seen:
        dupes.append(k)
    else:
        seen[k] = True

if dupes:
    print(f"en has {len(dupes)} duplicates: {set(dupes)}")
    for d in set(dupes):
        positions = [i+1 for i, k in enumerate(en_keys) if k == d]
        print(f'  "{d}" at key indices: {positions}')
else:
    print(f"en: OK ({len(en_keys)} keys)")

print()

# Check zh-Hans section (lines 330-380)  
print("=== Parsing zh-Hans section line by line ===")
zh_keys = []
for i in range(329, min(380, len(lines))):
    line = lines[i].strip()
    if not line or line in [']', '],']:
        continue
    match = re.match(r'^"([^"]+)":', line)
    if match:
        zh_keys.append(match.group(1))

seen = {}
dupes = []
for k in zh_keys:
    if k in seen:
        dupes.append(k)
    else:
        seen[k] = True

if dupes:
    print(f"zh-Hans has {len(dupes)} duplicates: {set(dupes)}")
    for d in set(dupes):
        positions = [i+1 for i, k in enumerate(zh_keys) if k == d]
        print(f'  "{d}" at key indices: {positions}')
else:
    print(f"zh-Hans: OK ({len(zh_keys)} keys)")

print("\nDone")
