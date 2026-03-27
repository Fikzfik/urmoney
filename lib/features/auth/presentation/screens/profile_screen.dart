import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/auth/providers/auth_provider.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/core/widgets/gradient_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController.text = user?.userMetadata?['full_name'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).updateProfile(name: name);
      
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception('Password tidak cocok');
        }
        if (_passwordController.text.length < 6) {
          throw Exception('Password minimal 6 karakter');
        }
        await ref.read(authServiceProvider).updatePassword(
          newPassword: _passwordController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppColors.income,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Info Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Email (Read-only)'),
                  const SizedBox(height: 8),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: email),
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  Text(
                    'UBAH PASSWORD (OPSIONAL)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Password Baru'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Konfirmasi Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Ketik ulang password baru',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  GradientButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    isLoading: _isLoading,
                    text: 'Simpan Perubahan',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}
