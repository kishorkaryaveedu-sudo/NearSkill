import os

filepath = 'lib/features/auth/presentation/login_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# We want to replace the `_buildField` and `build` and `_inputDecoration` methods.
# Find the start of `Widget _buildField`
build_field_idx = content.find('  Widget _buildField(')
if build_field_idx != -1:
    content = content[:build_field_idx]

new_code = '''
  Widget _buildFloatingInput(
    TextEditingController controller,
    String label,
    bool isPassword, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted),
        floatingLabelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                onPressed: onToggleObscure,
              )
            : null,
      ),
      validator: (v) {
        if (label.toLowerCase().contains('email')) {
          if (v == null || !v.contains('@')) return 'Enter a valid email';
        } else if (isPassword) {
          if (v == null || v.length < 6) return 'Min 6 characters';
        } else {
          if (v == null || v.trim().isEmpty) return 'This field is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 16),
                Text('NearSkill', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Your local expertise, instantly.', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                
                // Toggle Container
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () { if (!_isLogin) _toggleAuthMode(); },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: _isLogin ? [const BoxShadow(color: AppColors.shadow, blurRadius: 2, offset: Offset(0, 1))] : null,
                            ),
                            child: Center(
                              child: Text('Log In', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _isLogin ? AppColors.primary : AppColors.textSecondary)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () { if (_isLogin) _toggleAuthMode(); },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: !_isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: !_isLogin ? [const BoxShadow(color: AppColors.shadow, blurRadius: 2, offset: Offset(0, 1))] : null,
                            ),
                            child: Center(
                              child: Text('Sign Up', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: !_isLogin ? AppColors.primary : AppColors.textSecondary)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        _buildFloatingInput(_nameController, 'Full Name', false),
                        const SizedBox(height: 16),
                      ],
                      _buildFloatingInput(_emailController, 'Email Address', false, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      if (!_isLogin) ...[
                        _buildFloatingInput(_phoneController, 'Phone Number (optional)', false, keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                      ],
                      _buildFloatingInput(_passwordController, 'Password', true, obscure: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
                      
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        _buildFloatingInput(_confirmPasswordController, 'Confirm Password', true, obscure: _obscureConfirm, onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isWorkerAccount ? AppColors.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isWorkerAccount ? AppColors.primary : AppColors.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.engineering_outlined, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Register as Worker', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('Offer your services to clients', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Switch(value: _isWorkerAccount, onChanged: (v) => setState(() => _isWorkerAccount = v), activeColor: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                      
                      if (_isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text('Forgot Password?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                           child: Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
                        ),
                      ],

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'Log In' : 'Sign Up', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or continue with', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text('Google', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.apple, size: 22, color: AppColors.textPrimary),
                  label: Text('Apple', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
'''
content += new_code
with open(filepath, 'w') as f:
    f.write(content)
print("Rewrote login_screen.dart")
