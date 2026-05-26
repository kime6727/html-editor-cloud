with open('LanguageManager.swift', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the exact bytes around the zh-Hans section closing
import re
# Find zh-Hans section
match = re.search(r'"zh-Hans":\s*\[', content)
if match:
    start = match.end()
    # Find the closing ],
    depth = 1
    pos = start
    while pos < len(content) and depth > 0:
        if content[pos] == '[':
            depth += 1
        elif content[pos] == ']':
            depth -= 1
        pos += 1
    
    # Extract section
    section = content[start:pos-1]
    
    # Check last 200 chars for issues
    print("Last 300 chars of zh-Hans section:")
    print(repr(section[-300:]))
    print()
    
    # Check first 300 chars
    print("First 300 chars of zh-Hans section:")
    print(repr(section[:300]))
