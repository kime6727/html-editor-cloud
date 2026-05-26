import re

with open('LanguageManager.swift', 'r') as f:
    content = f.read()

pattern = r'"([^"]+)":\s*"'

langs = ['en', 'zh-Hans', 'zh-Hant']

for lang in langs:
    match = re.search(rf'"{lang}":\s*\[(.*?)\],', content, re.DOTALL)
    if match:
        section = match.group(1)
        keys = re.findall(pattern, section)
        seen = {}
        dupes = []
        for k in keys:
            if k in seen:
                dupes.append(k)
            else:
                seen[k] = True
        if dupes:
            print(f"X {lang}: {len(dupes)} duplicates: {set(dupes)}")
        else:
            print(f"OK {lang}: {len(keys)} keys, no duplicates")
    else:
        print(f"NOT FOUND: {lang}")

print("Done")
