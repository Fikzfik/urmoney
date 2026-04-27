import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/data/models/category_model.dart';
import 'package:urmoney/features/transactions/data/models/category_item_model.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:urmoney/core/theme/wallet_styles.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  final TransferModel? transfer;

  const TransactionDetailScreen({
    super.key,
    this.transaction,
    this.transfer,
  }) : assert(transaction != null || transfer != null);

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _feeController;
  late DateTime _selectedDate;
  String? _selectedWalletId;
  String? _toWalletId; // For transfers
  String? _selectedCategoryId;
  String? _selectedCategoryItemId;
  late String _type;
  bool _hasFee = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amountController = TextEditingController(text: t.amount.toStringAsFixed(0));
      _noteController = TextEditingController(text: t.note ?? '');
      _feeController = TextEditingController(text: '0');
      _selectedDate = t.date;
      _selectedWalletId = t.walletId;
      _selectedCategoryId = t.categoryId;
      _selectedCategoryItemId = t.categoryItemId;
      _type = t.type;
    } else {
      final t = widget.transfer!;
      _amountController = TextEditingController(text: t.amount.toStringAsFixed(0));
      _noteController = TextEditingController(text: t.note ?? '');
      _feeController = TextEditingController(text: t.fee.toStringAsFixed(0));
      _hasFee = t.fee > 0;
      _selectedDate = t.date;
      _selectedWalletId = t.fromWalletId;
      _toWalletId = t.toWalletId;
      _type = 'transfer';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan jumlah yang valid')));
      return;
    }

    if (widget.transaction != null) {
      final t = widget.transaction!;
      final updated = TransactionModel(
        id: t.id,
        userId: t.userId,
        bookId: t.bookId,
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId!,
        categoryItemId: _selectedCategoryItemId,
        amount: amount,
        type: _type,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: t.createdAt,
      );
      ref.read(transactionProvider.notifier).updateTransaction(updated);
    } else {
      final t = widget.transfer!;
      if (_selectedWalletId == _toWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dompet asal dan tujuan tidak boleh sama')));
        return;
      }
      
      final feeAmount = _hasFee ? (double.tryParse(_feeController.text.replaceAll('.', '')) ?? 0.0) : 0.0;

      final updated = TransferModel(
        id: t.id,
        userId: t.userId,
        bookId: t.bookId,
        fromWalletId: _selectedWalletId!,
        toWalletId: _toWalletId!,
        amount: amount,
        fee: feeAmount,
        date: _selectedDate,
        note: _noteController.text.trim(),
        createdAt: t.createdAt,
      );
      ref.read(transactionProvider.notifier).updateTransfer(updated);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus?'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (widget.transaction != null) {
                ref.read(transactionProvider.notifier).deleteTransaction(widget.transaction!.id);
              } else {
                ref.read(transactionProvider.notifier).deleteTransfer(widget.transfer!.id);
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dihapus')));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider).value ?? [];
    final catState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Detail Transaksi' : 'Detail Transfer',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            const _Label('Jumlah'),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Date
            const _Label('Tanggal'),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Wallet Selection
            if (widget.transaction != null) ...[
              const _Label('Dompet'),
              _buildWalletDropdown(wallets, _selectedWalletId, (val) => setState(() => _selectedWalletId = val)),
            ] else ...[
              const _Label('Dari Dompet'),
              _buildWalletDropdown(wallets, _selectedWalletId, (val) => setState(() => _selectedWalletId = val)),
              const SizedBox(height: 12),
              const _Label('Ke Dompet'),
              _buildWalletDropdown(wallets, _toWalletId, (val) => setState(() => _toWalletId = val)),
              const SizedBox(height: 24),
              _buildFeeSection(),
            ],
            const SizedBox(height: 20),

            // Category (Only for transactions)
            if (widget.transaction != null) ...[
              const _Label('Kategori'),
              _buildCategorySelector(catState),
              const SizedBox(height: 20),
            ],

            // Note
            const _Label('Catatan'),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDropdown(List<WalletModel> wallets, String? selectedId, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          items: wallets.map((w) {
            final style = WalletStyles.getStyle(w.name, w.type);
            return DropdownMenuItem(
              value: w.id,
              child: Row(
                children: [
                   if (style.logoPath != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                      child: Image.asset(style.logoPath!, width: 20, height: 20),
                    )
                  else
                    Icon(_getWalletIcon(w.type), size: 20, color: style.gradient.first),
                  const SizedBox(width: 12),
                  Text(w.name, style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  Text(formatRp(w.balance), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showCategoryPicker(CategoryState catState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final categories = _type == 'income' ? catState.incomeParents : catState.expenseParents;
          final activeCat = categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first);
          final items = catState.itemsFor(activeCat.id, _type == 'expense');
          final themeColor = _type == 'expense' ? Colors.blue : Colors.teal;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 16),
                const Text('Pilih Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                
                // Categories Row
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final isSelected = cat.id == _selectedCategoryId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : themeColor),
                          label: Text(cat.name, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _selectedCategoryId = cat.id);
                              setState(() => _selectedCategoryId = cat.id);
                            }
                          },
                          selectedColor: themeColor,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? themeColor : Colors.grey.shade200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ),

                // Items Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final isSelected = item.id == _selectedCategoryItemId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryItemId = item.id;
                            _selectedCategoryId = item.categoryId;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 50, width: 50,
                              decoration: BoxDecoration(
                                color: isSelected ? themeColor.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? themeColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                              ),
                              child: item.iconPath != null
                                  ? Image.asset(item.iconPath!, width: 24, height: 24)
                                  : Icon(item.icon ?? Icons.help_outline, color: isSelected ? themeColor : Colors.grey.shade600, size: 24),
                            ),
                            const SizedBox(height: 6),
                            Text(item.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? themeColor : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(CategoryState catState) {
    CategoryModel? parent;
    CategoryItemModel? item;

    if (_type == 'income') {
      parent = catState.incomeParents.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => catState.incomeParents.first);
      item = catState.incomeItems.firstWhere((i) => i.id == _selectedCategoryItemId, orElse: () => catState.incomeItems.firstWhere((i) => i.categoryId == parent?.id, orElse: () => catState.incomeItems.first));
    } else {
      parent = catState.expenseParents.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => catState.expenseParents.first);
      item = catState.expenseItems.firstWhere((i) => i.id == _selectedCategoryItemId, orElse: () => catState.expenseItems.firstWhere((i) => i.categoryId == parent?.id, orElse: () => catState.expenseItems.first));
    }

    return GestureDetector(
      onTap: () => _showCategoryPicker(catState),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: item.iconPath != null
                  ? Image.asset(item.iconPath!, width: 20, height: 20)
                  : Icon(item.icon ?? Icons.help_outline, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parent.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biaya Transfer / Pajak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      Text('Aktifkan jika ada biaya admin', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _hasFee,
                activeColor: Colors.blueAccent,
                onChanged: (val) => setState(() => _hasFee = val),
              ),
            ],
          ),
          if (_hasFee) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              children: [
                const Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'bankmobile': return Icons.account_balance_rounded;
      case 'digitalbank': return Icons.phonelink_setup_rounded;
      case 'ewallet': return Icons.account_balance_wallet_rounded;
      default: return Icons.payments_rounded;
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
    );
  }
}
