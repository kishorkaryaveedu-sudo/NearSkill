import os
import re

def fix_system_ui(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # 1. Brutalist leftovers: BoxShape.rectangle -> BoxShape.circle
    content = content.replace('BoxShape.rectangle', 'BoxShape.circle')
    
    # 2. Shadows: from brutalist/old to Stitch Ambient Shadows
    content = re.sub(
        r'BoxShadow\(\s*color:.*?alpha:\s*0\.[0-9]+\).*?blurRadius:\s*[0-9]+.*?offset:.*?Offset\([0-9]+,\s*[0-9]+\).*?\)',
        'BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))',
        content,
        flags=re.DOTALL
    )
    
    # Also replace specific hardcoded shadows
    content = content.replace('blurRadius: 8', 'blurRadius: 4')
    content = content.replace('offset: const Offset(0, 4)', 'offset: const Offset(0, 2)')
    
    # 3. Radii: default 16 -> 8
    # Using regex to target BorderRadius.all(Radius.circular(16)) or BorderRadius.circular(16)
    content = content.replace('Radius.circular(16)', 'Radius.circular(8)')
    content = content.replace('BorderRadius.circular(16)', 'BorderRadius.circular(8)')
    
    # 4. Map pins and circular things might have been forced to circular(8) now if they used circular(16).
    # But usually circles use BoxShape.circle.
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart'):
            fix_system_ui(os.path.join(root, file))
