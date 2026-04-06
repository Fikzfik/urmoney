import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/core/widgets/gradient_button.dart';
import 'package:urmoney/features/auth/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Monitor Pengeluaran Anda',
      description: 'Catat setiap transaksi dengan mudah dan pantau ke mana uang Anda pergi setiap harinya.',
      image: 'assets/images/onboarding_1.png',
    ),
    OnboardingItem(
      title: 'Atur Anggaran Cerdas',
      description: 'Buat anggaran untuk berbagai kategori dan pastikan Anda tidak melebihi batas pengeluaran.',
      image: 'assets/images/onboarding_2.png',
    ),
    OnboardingItem(
      title: 'Capai Kebebasan Finansial',
      description: 'Analisis kebiasaan belanja Anda dan mulailah menabung untuk masa depan yang lebih cerah.',
      image: 'assets/images/onboarding_3.png',
    ),
  ];

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _complete() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background wave similar to login screen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _complete,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return OnboardingPage(item: _items[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      const SizedBox(height: 32),
                      GradientButton(
                        onPressed: _onNext,
                        text: _currentPage == _items.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        height: 8,
        width: _currentPage == index ? 24 : 8,
        decoration: BoxDecoration(
          color: _currentPage == index ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String image;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                item.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Standard placeholder if image not found
                  return Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
