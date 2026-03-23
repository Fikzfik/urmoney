import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/dashboard/presentation/widgets/background_pattern.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const BackgroundPattern(),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAppBar(context, ref),
                const SizedBox(height: 16),
                _buildWalletCards(),
                const SizedBox(height: 32),
                _buildRecentTransactions(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookProvider);
    final activeBook = bookState.activeBook;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buku Catatan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (bookState.isLoading && activeBook == null)
                    const Text('Memuat...', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark))
                  else if (bookState.books.isEmpty)
                    GestureDetector(
                      onTap: () => _showAddBookDialog(context, ref),
                      child: const Text('Buat Buku +', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    )
                  else
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeBook?.id,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        isDense: true,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                        items: bookState.books.map((b) {
                          return DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final book = bookState.books.firstWhere((b) => b.id == val);
                            ref.read(bookProvider.notifier).setActiveBook(book);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
              onPressed: () => _showAddBookDialog(context, ref),
            ),
          )
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Buku Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Nama Buku (Toples, Usaha...)',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(bookProvider.notifier).addBook(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCards() {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          _WalletCard(
            gradient: AppColors.cardDeepBlue,
            walletName: 'Bank BCA',
            balance: 'Rp 4.560.000',
            cardNumber: '**** **** 1234',
            icon: Icons.account_balance,
          ),
          SizedBox(width: 16),
          _WalletCard(
            gradient: AppColors.cardOrange,
            walletName: 'Gopay',
            balance: 'Rp 1.250.000',
            cardNumber: '0812 **** 5678',
            icon: Icons.account_balance_wallet,
          ),
          SizedBox(width: 16),
          _WalletCard(
            gradient: AppColors.cardPurple,
            walletName: 'Dana',
            balance: 'Rp 850.000',
            cardNumber: '0812 **** 5678',
            icon: Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'See all',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _TransactionItem(name: 'Netflix', category: 'Entertainment', amount: '- Rp 186.000', icon: Icons.movie, color: Colors.redAccent),
          const _TransactionItem(name: 'Salary', category: 'Income', amount: '+ Rp 5.000.000', icon: Icons.work, color: Colors.green, isIncome: true),
          const _TransactionItem(name: 'Gofood', category: 'Food', amount: '- Rp 55.000', icon: Icons.fastfood, color: Colors.orange),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final LinearGradient gradient;
  final String walletName;
  final String balance;
  final String cardNumber;
  final IconData icon;

  const _WalletCard({required this.gradient, required this.walletName, required this.balance, required this.cardNumber, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(walletName, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(balance, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(cardNumber, style: const TextStyle(color: Colors.white70, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String name;
  final String category;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const _TransactionItem({required this.name, required this.category, required this.amount, required this.icon, required this.color, this.isIncome = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIncome ? Colors.green : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
