with open('LanguageManager.swift', 'r') as f:
    lines = f.readlines()

import re

# Check the en section (lines 102-168)
print("=== Checking en section for syntax issues ===\n")

# Extract the full en section text
en_text = ''.join(lines[101:168])

# Check for unbalanced quotes
quote_count = en_text.count('"')
if quote_count % 2 != 0:
    print(f"WARNING: Unbalanced quotes! Total quotes: {quote_count}")
else:
    print(f"Quote count OK: {quote_count} quotes (even number)")

# Check for tabs
tabs = en_text.count('\t')
if tabs > 0:
    print(f"WARNING: Found {tabs} tab characters")

# Check for any line that doesn't end with comma
for i, line in enumerate(lines[102:167], start=103):
    stripped = line.strip()
    # Skip empty lines and lines that are just ] or ],
    if not stripped or stripped in [']', '],']:
        continue
    # Check if it looks like a key-value pair but doesn't end with comma
    if ':' in stripped and not stripped.endswith(',') and not stripped.endswith('"'):
        print(f"Line {i}: Missing comma at end: {stripped[:80]}...")

# Check for consecutive commas or syntax errors
for i, line in enumerate(lines[102:167], start=103):
    if ',,' in line:
        print(f"Line {i}: Double comma found")
    if '": ""' in line:
        print(f"Line {i}: Empty value: {line.strip()[:80]}")

print("\n=== Syntax check complete ===")
