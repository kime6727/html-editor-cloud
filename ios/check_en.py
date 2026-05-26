with open('LanguageManager.swift', 'r') as f:
    lines = f.readlines()

# Extract en section keys line by line
en_keys = []
current_line_keys = []
in_en = False

for i, line in enumerate(lines, 1):
    if '"en": [' in line:
        in_en = True
        continue
    if in_en and '],' in line:
        break
    if in_en:
        import re
        # Find all "key": patterns in this line
        keys = re.findall(r'"([^"]+)":\s*"', line)
        en_keys.extend(keys)

# Check for duplicates
from collections import Counter
counts = Counter(en_keys)
dupes = {k: v for k, v in counts.items() if v > 1}

if dupes:
    print(f"en has {len(dupes)} duplicate keys:")
    for k, count in dupes.items():
        print(f'  "{k}" appears {count} times')
else:
    print(f"en OK: {len(en_keys)} keys, no duplicates")
