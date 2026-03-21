import 'package:flutter/material.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/dashboard/presentation/widgets/background_pattern.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/features/auth/providers/auth_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const BackgroundPattern(),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildProfileHeader(context),
                      const SizedBox(height: 32),
                      _buildSettingsGroup(
                        title: 'General',
                        items: [
                          _SettingsItem(icon: Icons.person_outline, title: 'Profile Info', onTap: () {}),
                          _SettingsItem(icon: Icons.currency_exchange, title: 'Currency', subtitle: 'IDR Rupiah', onTap: () {}),
                          _SettingsItem(icon: Icons.category_outlined, title: 'Manage Categories', onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSettingsGroup(
                        title: 'Preferences',
                        items: [
                          _SettingsItem(icon: Icons.dark_mode_outlined, title: 'Dark Mode', subtitle: 'Off', onTap: () {}),
                          _SettingsItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSettingsGroup(
                        title: 'Data & Security',
                        items: [
                          _SettingsItem(icon: Icons.download_outlined, title: 'Export Data', onTap: () {}),
                          _SettingsItem(icon: Icons.security, title: 'Security PIN', onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => ref.read(authServiceProvider).signOut(),
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'F',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fikz',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'fikz@example.com',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
