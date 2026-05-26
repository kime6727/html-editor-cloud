#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re

with open('LanguageManager.swift', 'r') as f:
    content = f.read()

# Find lines that start with "onboarding_title_3" and are very long (>500 chars)
# If two consecutive lines both start with "onboarding_title_3", keep only the one with "syntax_highlight_disabled"
lines = content.split('\n')
cleaned = []
skip_next = False

for i, line in enumerate(lines):
    stripped = line.strip()
    
    # Check if this is a long dict line starting with "onboarding_title_3"
    if stripped.startswith('"onboarding_title_3"') and len(stripped) > 500:
        # Check if next line also starts with "onboarding_title_3"
        if i + 1 < len(lines):
            next_stripped = lines[i + 1].strip()
            if next_stripped.startswith('"onboarding_title_3"') and len(next_stripped) > 500:
                # Both lines are duplicates - keep the one with syntax_highlight_disabled
                if '"syntax_highlight_disabled"' in stripped:
                    cleaned.append(line)
                    skip_next = True
                elif '"syntax_highlight_disabled"' in next_stripped:
                    skip_next = True
                    continue
                else:
                    cleaned.append(line)
            else:
                if not skip_next:
                    cleaned.append(line)
                else:
                    skip_next = False
        else:
            if not skip_next:
                cleaned.append(line)
            else:
                skip_next = False
    else:
        if skip_next and stripped.startswith('"onboarding_title_3"') and len(stripped) > 500:
            skip_next = False
            continue
        elif skip_next:
            skip_next = False
            cleaned.append(line)
        else:
            cleaned.append(line)

result = '\n'.join(cleaned)
with open('LanguageManager.swift', 'w') as f:
    f.write(result)

# Count remaining onboarding_title_3 lines
count = sum(1 for line in result.split('\n') if line.strip().startswith('"onboarding_title_3"') and len(line.strip()) > 500)
print("Remaining onboarding_title_3 long lines: " + str(count))

disabled_count = result.count('"syntax_highlight_disabled"')
print("syntax_highlight_disabled occurrences: " + str(disabled_count))
