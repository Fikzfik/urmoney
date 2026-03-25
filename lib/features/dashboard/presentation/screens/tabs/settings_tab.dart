import 'package:flutter/material.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/features/auth/providers/auth_provider.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/transactions/presentation/screens/category_settings_screen.dart';
import 'package:urmoney/features/books/presentation/screens/book_management_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'Unknown Email';
    final name = user?.userMetadata?['full_name'] ?? user?.email?.split('@')[0] ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Header ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: Center(
                        child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(email, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.cloud_done_outlined, size: 13, color: Colors.greenAccent),
                            const SizedBox(width: 4),
                            Text('Cloud Synced', style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Settings body ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                children: [
                  _buildGroup(
                    title: 'Umum',
                    items: [
                      _SettingsItem(icon: Icons.person_outline, title: 'Info Profil', iconColor: AppColors.primary, onTap: () {}),
                      _SettingsItem(
                        icon: Icons.book_outlined,
                        title: 'Kelola Buku',
                        iconColor: const Color(0xFF6A1B9A),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BookManagementScreen())),
                      ),
                      _SettingsItem(icon: Icons.currency_exchange, title: 'Mata Uang', subtitle: 'IDR Rupiah', iconColor: AppColors.income, onTap: () {}),
                      _SettingsItem(
                        icon: Icons.category_outlined,
                        title: 'Kelola Kategori',
                        iconColor: const Color(0xFFE65100),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CategorySettingsScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGroup(
                    title: 'Preferensi',
                    items: [
                      _SettingsItem(icon: Icons.dark_mode_outlined, title: 'Mode Gelap', subtitle: 'Nonaktif', iconColor: Colors.grey.shade700, onTap: () {}),
                      _SettingsItem(icon: Icons.notifications_outlined, title: 'Notifikasi', iconColor: Colors.amber.shade700, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGroup(
                    title: 'Data & Keamanan',
                    items: [
                      _SettingsItem(icon: Icons.download_outlined, title: 'Ekspor Data', iconColor: AppColors.primary, onTap: () {}),
                      _SettingsItem(icon: Icons.security, title: 'PIN Keamanan', iconColor: Colors.redAccent, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.08),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.25)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.title, this.subtitle, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
