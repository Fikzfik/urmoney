import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/core/theme/wallet_styles.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:urmoney/features/wallets/presentation/screens/add_edit_wallet_screen.dart';

class WalletsTab extends ConsumerWidget {
  const WalletsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBook = ref.watch(bookProvider.select((s) => s.activeBook));
    final walletsAsync = ref.watch(walletProvider);

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dompet Saya', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              activeBook?.name ?? 'Buku Utama',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditWalletScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Total balance
                    walletsAsync.when(
                      data: (wallets) {
                        final total = wallets.fold(0.0, (s, w) => s + w.balance);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Saldo', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              formatRp(total),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                            ),
                          ],
                        );
                      },
                      loading: () => const Text('Memuat...', style: TextStyle(color: Colors.white70)),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Wallet List ───────────────────────────────────────────────
          Expanded(
            child: walletsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (wallets) {
                if (wallets.isEmpty) return _buildEmptyState(context);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  itemCount: wallets.length,
                  itemBuilder: (ctx, i) => _buildWalletCard(ctx, ref, wallets[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _typeLabels = {
    'bankmobile': 'Bank Mobile',
    'digitalbank': 'Digital Bank',
    'ewallet': 'e-Wallet',
    'cash': 'Tunai',
  };

  static const _typeIcons = {
    'bankmobile': Icons.account_balance_rounded,
    'digitalbank': Icons.phonelink_ring_rounded,
    'ewallet': Icons.wallet_rounded,
    'cash': Icons.money_rounded,
  };

  Widget _buildWalletCard(BuildContext context, WidgetRef ref, WalletModel w) {
    final style = WalletStyles.getStyle(w.name, w.type);
    final icon = _typeIcons[w.type] ?? Icons.account_balance_wallet_rounded;
    final typeLabel = _typeLabels[w.type] ?? w.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: style.gradient.last.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          if (style.backgroundImagePath != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(style.backgroundImagePath!, fit: BoxFit.cover),
              ),
            ),
          
          // Optional Brand Logo in background (only if no background image)
          if (style.backgroundImagePath == null && style.logoPath != null)
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(style.logoPath!, width: 140, height: 140, fit: BoxFit.contain),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (style.logoPath != null)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Image.asset(style.logoPath!, width: 24, height: 24),
                          )
                        else
                          Icon(icon, color: style.iconColor ?? Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.name, style: TextStyle(color: style.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(typeLabel, style: TextStyle(color: style.textColor.withOpacity(0.7), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditWalletScreen(wallet: w)));
                        } else if (val == 'delete') {
                          _confirmDelete(context, ref, w);
                        }
                      },
                      icon: Icon(Icons.more_vert_rounded, color: style.textColor.withOpacity(0.8)),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Balance
                Text('Saldo', style: TextStyle(color: style.textColor.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 4),
                Text(formatRp(w.balance), style: TextStyle(color: style.textColor, fontWeight: FontWeight.bold, fontSize: 26)),
                // Extra info row
                if (w.type == 'bankmobile' && w.taxRate != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.receipt_long_outlined, label: 'Pajak: ${formatRp(w.taxRate!)} / tgl ${w.taxDay ?? "?"}', textColor: style.textColor),
                    ],
                  ),
                ],
                if (w.type == 'digitalbank' && w.interestRate != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.trending_up_rounded, label: 'Bunga: ${w.interestRate}% (${w.payoutSchedule ?? "harian"})', textColor: style.textColor),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WalletModel w) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Dompet?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${w.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(walletProvider.notifier).deleteWallet(w.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, size: 56, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text('Belum ada dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Klik tombol + di atas untuk menambahkan dompet pertama.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  const _InfoChip({required this.icon, required this.label, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
