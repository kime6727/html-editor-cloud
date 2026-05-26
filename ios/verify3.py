with open('LanguageManager.swift', 'r') as f:
    lines = f.readlines()

# Find where each language section starts and ends
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    # Print context around language declarations
    if '"en": [' in stripped or '"zh-Hans": [' in stripped:
        print(f"Line {i}: {stripped}")
        # Show next 3 lines
        for j in range(i, min(i+3, len(lines))):
            print(f"Line {j+1}: {lines[j].strip()[:100]}")
        print()

# Also check closing brackets
print("=== Checking closing brackets ===")
for i in [167, 168, 169, 170, 378, 379, 380, 381]:
    if i <= len(lines):
        print(f"Line {i}: {lines[i-1].strip()}")

print("\n=== Line counts ===")
print(f"Total lines: {len(lines)}")
