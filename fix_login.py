import os

filepath = 'lib/features/auth/presentation/login_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Fix dialog border
content = content.replace('side: BorderSide(color: AppColors.border, width: 3)', 'side: BorderSide.none')
# Fix reset icon border
content = content.replace('border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),', 'borderRadius: BorderRadius.circular(12),')
# Fix reset button radius
content = content.replace('borderRadius: BorderRadius.all(Radius.circular(16)))', 'borderRadius: BorderRadius.all(Radius.circular(8)))')
# Fix _buildField borders
content = content.replace('''        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.border, width: 2),
        ),''', '''        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),''')
content = content.replace('''        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.secondary, width: 3),
        ),''', '''        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),''')
content = content.replace('''        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),''', '''        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),''')
# Fix _inputDecoration borders
content = content.replace('Radius.circular(16)', 'Radius.circular(8)')
content = content.replace('borderSide: BorderSide(color: AppColors.border, width: 2)', 'borderSide: BorderSide(color: AppColors.border, width: 1)')
content = content.replace('borderSide: BorderSide(color: AppColors.secondary, width: 3)', 'borderSide: BorderSide(color: AppColors.primary, width: 2)')
content = content.replace('borderSide: BorderSide(color: AppColors.error, width: 2)', 'borderSide: BorderSide(color: AppColors.error, width: 1)')
content = content.replace('borderSide: BorderSide(color: AppColors.error, width: 3)', 'borderSide: BorderSide(color: AppColors.error, width: 2)')

# Fix worker switch
content = content.replace('''                            decoration: BoxDecoration(
                              color: _isWorkerAccount
                                  ? AppColors.accent
                                  : AppColors.surface,
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                            ),''', '''                            decoration: BoxDecoration(
                              color: _isWorkerAccount
                                  ? AppColors.primaryLight.withOpacity(0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isWorkerAccount ? AppColors.primary : AppColors.border,
                                width: 1,
                              ),
                            ),''')

with open(filepath, 'w') as f:
    f.write(content)
print(f"Fixed {filepath}")
