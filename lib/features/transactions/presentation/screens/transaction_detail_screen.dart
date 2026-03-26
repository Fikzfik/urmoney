import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';

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
  late DateTime _selectedDate;
  String? _selectedWalletId;
  String? _toWalletId; // For transfers
  String? _selectedCategoryId;
  String? _selectedCategoryItemId;
  late String _type;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amountController = TextEditingController(text: t.amount.toStringAsFixed(0));
      _noteController = TextEditingController(text: t.note ?? '');
      _selectedDate = t.date;
      _selectedWalletId = t.walletId;
      _selectedCategoryId = t.categoryId;
      _selectedCategoryItemId = t.categoryItemId;
      _type = t.type;
    } else {
      final t = widget.transfer!;
      _amountController = TextEditingController(text: t.amount.toStringAsFixed(0));
      _noteController = TextEditingController(text: t.note ?? '');
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
      final updated = TransferModel(
        id: t.id,
        userId: t.userId,
        bookId: t.bookId,
        fromWalletId: _selectedWalletId!,
        toWalletId: _toWalletId!,
        amount: amount,
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
          items: wallets.map((w) => DropdownMenuItem(
            value: w.id,
            child: Row(
              children: [
                Icon(_getWalletIcon(w.type), size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(w.name, style: const TextStyle(fontSize: 15)),
                const Spacer(),
                Text(formatRp(w.balance), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCategorySelector(CategoryState catState) {
    final categories = _type == 'income' ? catState.incomeParents : catState.expenseParents;
    final items = _type == 'income' ? catState.incomeItems : catState.expenseItems;
    
    return Column(
      children: [
        // Category Pills
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSelected = cat.id == _selectedCategoryId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedCategoryItemId = null;
                      });
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                ),
              );
            },
          ),
        ),
        if (_selectedCategoryId != null) ...[
          const SizedBox(height: 12),
          // Subcategory Items
          Wrap(
            spacing: 8,
            children: items.where((i) => i.categoryId == _selectedCategoryId).map((item) {
              final isSelected = item.id == _selectedCategoryItemId;
              return ChoiceChip(
                label: Text(item.name),
                selected: isSelected,
                avatar: Icon(item.icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                onSelected: (val) {
                  setState(() => _selectedCategoryItemId = val ? item.id : null);
                },
                selectedColor: AppColors.primary.withOpacity(0.8),
                labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ],
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
