import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/services/ai_service.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:intl/intl.dart';

class ScanReviewScreen extends ConsumerStatefulWidget {
  final AIReceiptResult result;

  const ScanReviewScreen({super.key, required this.result});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late List<AIReceiptItem> _items;
  late DateTime _selectedDate;
  WalletModel? _selectedWallet;
  bool _isSaving = false;
  String? _mainCategoryId;
  String? _mainCategoryItemId;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.result.items);
    _selectedDate = widget.result.date ?? DateTime.now();
    _autoMatchWallet();
  }

  void _autoMatchWallet() {
    final walletsAsync = ref.read(walletProvider);
    final wallets = walletsAsync.value;
    if (wallets == null || wallets.isEmpty) return;

    final pm = widget.result.paymentMethod?.toLowerCase() ?? '';

    if (pm.isEmpty) {
      _selectedWallet = wallets.first;
      return;
    }

    // Try to match wallet by name or type
    WalletModel? matched;

    // Check e-wallet names
    final ewalletNames = ['gopay', 'ovo', 'shopeepay', 'dana', 'linkaja'];
    for (var name in ewalletNames) {
      if (pm.contains(name)) {
        matched = wallets.cast<WalletModel?>().firstWhere(
          (w) => w!.name.toLowerCase().contains(name),
          orElse: () => null,
        );
        break;
      }
    }

    // Check cash
    if (matched == null && (pm.contains('cash') || pm.contains('tunai'))) {
      matched = wallets.cast<WalletModel?>().firstWhere(
        (w) => w!.type == 'cash',
        orElse: () => null,
      );
    }

    // Check bank names
    if (matched == null) {
      final bankNames = ['bca', 'bri', 'bni', 'mandiri', 'seabank', 'jago', 'cimb', 'permata'];
      for (var bank in bankNames) {
        if (pm.contains(bank)) {
          matched = wallets.cast<WalletModel?>().firstWhere(
            (w) => w!.name.toLowerCase().contains(bank),
            orElse: () => null,
          );
          break;
        }
      }
    }

    // Check debit/kredit → first bank wallet
    if (matched == null && (pm.contains('debit') || pm.contains('kredit') || pm.contains('qris'))) {
      matched = wallets.cast<WalletModel?>().firstWhere(
        (w) => w!.type == 'bankmobile' || w.type == 'digitalbank',
        orElse: () => null,
      );
    }

    _selectedWallet = matched ?? wallets.first;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final catNotifier = ref.read(categoryProvider.notifier);
      
      // Auto-create categories/items for each scanned item
      for (var item in _items) {
        final catId = await catNotifier.findOrCreateCategory(item.suggestedCategory);
        await catNotifier.findOrCreateItem(catId, item.suggestedCategoryItem);
      }

      // Use the first item's category as the main transaction category
      final firstItem = _items.first;
      final mainCatId = await catNotifier.findOrCreateCategory(firstItem.suggestedCategory);
      final mainItemId = await catNotifier.findOrCreateItem(mainCatId, firstItem.suggestedCategoryItem);

      final activeBook = ref.read(bookProvider).activeBook;
      final user = ref.read(currentUserProvider);
      final wallet = _selectedWallet ?? ref.read(walletProvider).value?.first;

      if (activeBook == null || user == null || wallet == null) {
        throw Exception('Data buku/user/wallet tidak lengkap');
      }

      final transaction = TransactionModel(
        id: '',
        userId: user.id,
        bookId: activeBook.id,
        walletId: wallet.id,
        categoryId: mainCatId,
        categoryItemId: mainItemId,
        amount: widget.result.total,
        type: 'expense',
        note: widget.result.toFormattedNote(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      await ref.read(transactionProvider.notifier).addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${_items.length} item berhasil disimpan!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEditCategoryDialog(int itemIndex) {
    final item = _items[itemIndex];
    final catController = TextEditingController(text: item.suggestedCategory);
    final itemController = TextEditingController(text: item.suggestedCategoryItem);

    final catState = ref.read(categoryProvider);
    final existingCategories = catState.expenseParents.map((c) => c.name).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4, width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Kategori — ${item.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Category suggestions
              const Text('Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...existingCategories.map((c) => GestureDetector(
                    onTap: () => catController.text = c,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catController,
                decoration: InputDecoration(
                  hintText: 'Nama kategori...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),
              const Text('Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: itemController,
                decoration: InputDecoration(
                  hintText: 'Nama item kategori...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _items[itemIndex].suggestedCategory = catController.text.trim();
                      _items[itemIndex].suggestedCategoryItem = itemController.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider).value ?? [];
    final catState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.result.storeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'id').format(_selectedDate),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('Hasil Scan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Info Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Payment Method
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.payment_rounded,
                      label: 'Pembayaran',
                      value: widget.result.paymentMethod ?? 'Tidak terdeteksi',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Wallet
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showWalletPicker(wallets),
                      child: _InfoCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Dompet',
                        value: _selectedWallet?.name ?? 'Pilih...',
                        color: AppColors.primary,
                        showArrow: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tax info
          if (widget.result.tax > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Termasuk PPN: ${formatRp(widget.result.tax)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Section: Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Daftar Item',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_items.length} item',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap untuk edit kategori',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

          // Item List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildItemCard(index, catState),
                childCount: _items.length,
              ),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // Total + Save Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRp(widget.result.total),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, CategoryState catState) {
    final item = _items[index];
    final qtyText = item.quantity > 1 ? ' x${item.quantity}' : '';

    // Check if category exists
    final existingCats = catState.expenseParents.map((c) => c.name.toLowerCase()).toList();
    final isNewCategory = !existingCats.any(
      (c) => c.contains(item.suggestedCategory.toLowerCase()) ||
             item.suggestedCategory.toLowerCase().contains(c),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showEditCategoryDialog(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Index number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.name}$qtyText',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.folder_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${item.suggestedCategory} > ${item.suggestedCategoryItem}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isNewCategory) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'BARU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRp(item.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.expense,
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        '@ ${formatRp(item.price)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWalletPicker(List<WalletModel> wallets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4, width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Pilih Dompet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...wallets.map((w) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  formatRp(w.balance),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                trailing: _selectedWallet?.id == w.id
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  setState(() => _selectedWallet = w);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showArrow;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }
}
