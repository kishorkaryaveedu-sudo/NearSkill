import os

def refactor_fonts(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # Replace fonts
    content = content.replace('GoogleFonts.manrope', 'GoogleFonts.inter')
    content = content.replace('GoogleFonts.outfit', 'GoogleFonts.inter')
    
    # Optional: soften borders everywhere slightly to make sure it matches the new design system
    # Many cards already use Card() from ThemeData which is now updated, but just in case:
    # content = content.replace('Radius.circular(16)', 'Radius.circular(8)')
    # Wait, we might not want to blindly replace all 16 to 8 since 16 is used for large components
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Refactored {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            refactor_fonts(os.path.join(root, file))
