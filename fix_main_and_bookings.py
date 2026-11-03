import os

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix widths in borders
    content = content.replace('width: 3', 'width: 1')
    content = content.replace('width: 2', 'width: 1')
    content = content.replace('width: 4', 'width: 1')
    
    if filepath.endswith('bookings_screen.dart'):
        # TabBar text colors shouldn't be blue if AppBar is blue
        # AppBar background is default white now? 
        # In main.dart we set AppBarTheme to backgroundColor: AppColors.primary
        # So AppBar is blue. We should use white for tabs.
        content = content.replace('labelColor: AppColors.primary,', 'labelColor: Colors.white,')
        content = content.replace('unselectedLabelColor: AppColors.textSecondary,', 'unselectedLabelColor: Colors.white70,')
        content = content.replace('indicatorColor: AppColors.primary,', 'indicatorColor: Colors.white,')
        # Also fix the title color
        content = content.replace('style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),', "style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),")
        
    if filepath.endswith('main.dart'):
        # We can also just make AppBar white to be safe and clean
        content = content.replace('backgroundColor: AppColors.primary,', 'backgroundColor: AppColors.surface,')
        content = content.replace('titleTextStyle: GoogleFonts.outfit(\n          color: Colors.white,', 'titleTextStyle: GoogleFonts.outfit(\n          color: AppColors.textPrimary,')
        content = content.replace('iconTheme: const IconThemeData(color: Colors.white),', 'iconTheme: const IconThemeData(color: AppColors.textPrimary),')
        
    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/main.dart')
fix_file('lib/features/booking/presentation/bookings_screen.dart')

