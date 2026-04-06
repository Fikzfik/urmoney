import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/core/widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background graphic
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundWave,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100),
                  topRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // Back Button
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    onPressed: () => context.go('/onboarding'),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Illustration
                        Center(
                          child: Image.asset('assets/images/ilustration-1.png', height: 200, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hello there, sign in to continue',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Forgot your password?', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          onPressed: _isLoading ? null : _login,
                          isLoading: _isLoading,
                          text: 'Sign In',
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
