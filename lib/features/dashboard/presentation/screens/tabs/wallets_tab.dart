import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/dashboard/presentation/widgets/background_pattern.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:urmoney/features/wallets/presentation/screens/add_edit_wallet_screen.dart';

class WalletsTab extends ConsumerWidget {
  const WalletsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBook = ref.watch(bookProvider.select((s) => s.activeBook));
    final walletsAsync = ref.watch(walletProvider);

    return Stack(
      children: [
        const BackgroundPattern(),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dompet di',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          activeBook?.name ?? 'Buku Utama',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _showAddWalletDialog(context, ref),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: walletsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Center(child: Text('Error: $err')),
                  data: (wallets) {
                    if (wallets.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    final totalBalance = wallets.fold(0.0, (sum, w) => sum + w.balance);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardDeepBlue,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cardDeepBlue.colors.last.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Saldo', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text('Rp ${totalBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: wallets.length,
                            itemBuilder: (ctx, i) {
                              final w = wallets[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
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
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(_formatType(w.type), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Text('Rp ${w.balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditWalletDialog(context, ref, w);
                                        } else if (value == 'delete') {
                                          _confirmDeleteWallet(context, ref, w);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'bankmobile':
        return 'Bank Mobile';
      case 'digitalbank':
        return 'Digital Bank';
      case 'ewallet':
        return 'e-Wallet';
      case 'cash':
        return 'Tunai';
      default:
        return type;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.cardPurple.colors.first.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.cardPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardPurple.colors.first.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Total Saldo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp 0',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Belum ada dompet di buku ini. Klik tombol + di atas untuk menambahkan dompet pertama.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditWalletScreen()),
    );
  }

  void _showEditWalletDialog(BuildContext context, WidgetRef ref, WalletModel wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditWalletScreen(wallet: wallet)),
    );
  }

  void _confirmDeleteWallet(BuildContext context, WidgetRef ref, WalletModel wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text('Apakah Anda yakin ingin menghapus "${wallet.name}"? Semua transaksi di dompet ini akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(walletProvider.notifier).deleteWallet(wallet.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
