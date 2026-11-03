import os
import glob

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # Replace borders
    content = content.replace('BorderRadius.zero', 'BorderRadius.circular(16)')
    content = content.replace('blurRadius: 0', 'blurRadius: 8')
    content = content.replace('Offset(3, 3)', 'Offset(0, 4)')
    content = content.replace('Offset(4, 4)', 'Offset(0, 4)')
    
    # Replace fonts
    content = content.replace('GoogleFonts.ibmPlexMono', 'GoogleFonts.inter')
    content = content.replace('GoogleFonts.spaceMono', 'GoogleFonts.outfit')
    
    # Soften borders
    content = content.replace('Border.all(color: AppColors.border, width: 2)', 'Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1)')
    content = content.replace('Border.all(color: AppColors.border, width: 3)', 'Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1)')
    content = content.replace('Border.all(color: AppColors.border)', 'Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1)')
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

