import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/category_item_model.dart';
import 'package:urmoney/features/transactions/data/models/category_model.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/transactions/presentation/screens/category_settings_screen.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';

String _evalMath(String expr) {
  try {
    var s = expr.replaceAll('×', '*').replaceAll('÷', '/');
    List<String> tokens = [];
    String numStr = '';
    for (int i = 0; i < s.length; i++) {
      var c = s[i];
      if (['+', '-', '*', '/'].contains(c)) {
        if (numStr.isNotEmpty) tokens.add(numStr);
        tokens.add(c);
        numStr = '';
      } else {
        numStr += c;
      }
    }
    if (numStr.isNotEmpty) tokens.add(numStr);
    if (tokens.isEmpty) return '0';

    for (int i = 1; i < tokens.length - 1; i += 2) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        double a = double.parse(tokens[i - 1]);
        double b = double.parse(tokens[i + 1]);
        double res = tokens[i] == '*' ? a * b : a / b;
        tokens.replaceRange(i - 1, i + 2, [res.toString()]);
        i -= 2;
      }
    }
    double result = double.parse(tokens[0]);
    for (int i = 1; i < tokens.length - 1; i += 2) {
      double b = double.parse(tokens[i + 1]);
      if (tokens[i] == '+') result += b;
      if (tokens[i] == '-') result -= b;
    }

    if (result == result.toInt()) return result.toInt().toString();
    String formatted = result.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      formatted = formatted.substring(0, formatted.length - 3);
    } else if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  } catch (e) {
    return expr;
  }
}

String _updateAmountForm(String amount, String val) {
  if (val == 'C') return '0';
  if (val == '=') return _evalMath(amount);
  if (val == '⌫') {
    if (amount.length > 1) return amount.substring(0, amount.length - 1);
    return '0';
  }

  if (amount == '0' && !['.', '+', '-', '×', '÷'].contains(val)) return val;

  if (['+', '-', '×', '÷'].contains(val)) {
    String last = amount[amount.length - 1];
    if (['+', '-', '×', '÷', '.'].contains(last)) {
      return amount.substring(0, amount.length - 1) + val;
    } else {
      return amount + val;
    }
  }

  if (amount.length < 25) return amount + val;
  return amount;
}

class AddTransactionBottomSheet extends StatelessWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(text: 'Pengeluaran'),
                Tab(text: 'Pemasukan'),
                Tab(text: 'Transfer')
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _TransactionForm(isExpense: true),
                  _TransactionForm(isExpense: false),
                  _TransferForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  final bool isExpense;
  const _TransactionForm({required this.isExpense});

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  String _amount = '0';
  int _selectedParentIndex = 0;
  int _selectedItemIndex = -1;
  WalletModel? _selectedWallet;
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _handleSave() async {
    final state = ref.read(categoryProvider);
    final parents =
        widget.isExpense ? state.expenseParents : state.incomeParents;
    if (parents.isEmpty) return;

    final activeIdx = _selectedParentIndex.clamp(0, parents.length - 1);
    final parent = parents[activeIdx];
    final items = state.itemsFor(parent.id, widget.isExpense);

    if (_selectedItemIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih item kategori dulu ya!')),
      );
      return;
    }

    final amountDouble = double.tryParse(_evalMath(_amount)) ?? 0;
    if (amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    final activeBook = ref.read(bookProvider).activeBook;
    final user = ref.read(currentUserProvider);
    final wallet = _selectedWallet ?? ref.read(walletProvider).value?.first;

    if (activeBook == null || user == null || wallet == null) return;

    final transaction = TransactionModel(
      id: '',
      userId: user.id,
      bookId: activeBook.id,
      walletId: wallet.id,
      categoryId: parent.id,
      categoryItemId: items[_selectedItemIndex].id,
      amount: amountDouble,
      type: widget.isExpense ? 'expense' : 'income',
      note: _noteController.text,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await ref.read(transactionProvider.notifier).addTransaction(transaction);
    if (mounted) Navigator.pop(context);
  }

  void _onKeypadTap(String val) {
    setState(() {
      _amount = _updateAmountForm(_amount, val);
    });
  }

  Widget _buildItemsGrid(List<CategoryItemModel> items, Color themeColor) {
    if (items.isEmpty) {
      return Center(
        child: Text('Belum ada item',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItemIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedItemIndex = index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color:
                      isSelected ? themeColor.withOpacity(0.15) : Colors.white,
                  border: Border.all(
                    color: isSelected ? themeColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: themeColor.withOpacity(0.2), blurRadius: 8)
                        ]
                      : [],
                ),
                child: Icon(
                  item.icon,
                  color: isSelected ? themeColor : Colors.grey.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? themeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChipsRow(BuildContext context, List<CategoryModel> parents,
      int activeIndex, Color themeColor) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: parents.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == parents.length) {
            return ActionChip(
              avatar: Icon(Icons.settings_rounded, size: 16, color: themeColor),
              label: const Text('Pengaturan',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade200),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CategorySettingsScreen()));
                setState(() {});
              },
            );
          }
          final parent = parents[index];
          final isSelected = activeIndex == index;
          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(parent.icon,
                size: 14, color: isSelected ? Colors.white : themeColor),
            label: Text(
              parent.name,
              style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
            ),
            selected: isSelected,
            selectedColor: themeColor,
            backgroundColor: Colors.white,
            side: BorderSide(
                color: isSelected ? themeColor : Colors.grey.shade200),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            onSelected: (_) => setState(() {
              _selectedParentIndex = index;
              _selectedItemIndex = -1;
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProvider);
    final parents =
        widget.isExpense ? state.expenseParents : state.incomeParents;
    final themeColor = widget.isExpense ? Colors.blue : Colors.teal;
    final activeIdx =
        _selectedParentIndex.clamp(0, parents.isEmpty ? 0 : parents.length - 1);
    final items = parents.isEmpty
        ? <CategoryItemModel>[]
        : state.itemsFor(parents[activeIdx].id, widget.isExpense);

    return Column(
      children: [
        _buildChipsRow(context, parents, activeIdx, themeColor),
        Expanded(child: _buildItemsGrid(items, themeColor)),
        _CustomKeypad(
          amount: _amount,
          noteController: _noteController,
          onKeypadTap: _onKeypadTap,
          themeColor: themeColor,
          selectedWallet: _selectedWallet ??
              (ref.watch(walletProvider).value?.isNotEmpty == true
                  ? ref.watch(walletProvider).value!.first
                  : null),
          onWalletChanged: (wallet) => setState(() => _selectedWallet = wallet),
          selectedDate: _selectedDate,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onSave: _handleSave,
        ),
      ],
    );
  }
}

class _TransferForm extends ConsumerStatefulWidget {
  const _TransferForm();
  @override
  ConsumerState<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends ConsumerState<_TransferForm> {
  String _amount = '0';
  final TextEditingController _noteController = TextEditingController();
  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  DateTime _selectedDate = DateTime.now();
  bool _hasFee = false;
  final TextEditingController _feeController = TextEditingController(text: '0');

  void _onKeypadTap(String val) {
    setState(() {
      _amount = _updateAmountForm(_amount, val);
    });
  }

  Future<void> _handleSave() async {
    final amountDouble = double.tryParse(_evalMath(_amount)) ?? 0;
    if (amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    if (_fromWallet == null || _toWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet asal dan tujuan')),
      );
      return;
    }

    if (_fromWallet!.id == _toWallet!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dompet asal dan tujuan tidak boleh sama')),
      );
      return;
    }

    final activeBook = ref.read(bookProvider).activeBook;
    final user = ref.read(currentUserProvider);

    if (activeBook == null || user == null) return;

    final feeAmount = _hasFee ? (double.tryParse(_feeController.text.replaceAll('.', '')) ?? 0.0) : 0.0;

    final transfer = TransferModel(
      id: '',
      userId: user.id,
      bookId: activeBook.id,
      fromWalletId: _fromWallet!.id,
      toWalletId: _toWallet!.id,
      amount: amountDouble,
      fee: feeAmount,
      note: _noteController.text,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await ref.read(transactionProvider.notifier).addTransfer(transfer);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return const Center(child: Text('Belum ada dompet'));
                }
                _fromWallet ??= wallets.first;
                _toWallet ??= wallets.length > 1 ? wallets[1] : wallets.first;

                return Column(
                  children: [
                    _buildWalletSelector('Dari Dompet', _fromWallet!, wallets,
                        (val) => setState(() => _fromWallet = val)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.keyboard_double_arrow_down_rounded,
                            color: Colors.blueAccent, size: 20),
                      ),
                    ),
                    _buildWalletSelector('Ke Dompet', _toWallet!, wallets,
                        (val) => setState(() => _toWallet = val)),
                    const SizedBox(height: 20),
                    _buildFeeSelector(),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
        _CustomKeypad(
          amount: _amount,
          noteController: _noteController,
          onKeypadTap: _onKeypadTap,
          themeColor: Colors.blueAccent,
          selectedWallet: _fromWallet,
          onWalletChanged: (w) => setState(() => _fromWallet = w),
          selectedDate: _selectedDate,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onSave: _handleSave,
        ),
      ],
    );
  }

  Widget _buildFeeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biaya Transfer / Pajak',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                      Text('Aktifkan jika ada biaya admin',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Text('Rp',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletSelector(String title, WalletModel value,
      List<WalletModel> wallets, ValueChanged<WalletModel?> onChanged) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _WalletPicker(
            themeColor: Colors.blueAccent,
            selectedWallet: value,
            onWalletChanged: onChanged,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                          'Rp ${value.balance.toStringAsFixed(0).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomKeypad extends StatefulWidget {
  final String amount;
  final TextEditingController noteController;
  final Function(String) onKeypadTap;
  final VoidCallback onSave;
  final WalletModel? selectedWallet;
  final ValueChanged<WalletModel?> onWalletChanged;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final Color themeColor;

  const _CustomKeypad({
    required this.amount,
    required this.noteController,
    required this.onKeypadTap,
    required this.onSave,
    required this.themeColor,
    this.selectedWallet,
    required this.onWalletChanged,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<_CustomKeypad> createState() => _CustomKeypadState();
}

class _CustomKeypadState extends State<_CustomKeypad> {
  bool _showExtras = false;

  String _formatAmount(String amt) {
    if (amt.isEmpty || amt == '0' || !RegExp(r'[0-9]').hasMatch(amt)) return '0';
    String cleaned = amt.replaceAll(RegExp(r'[^0-9.+-×÷]'), '');
    if (cleaned.isEmpty) return '0';

    return cleaned.replaceAllMapped(RegExp(r'\d+(\.\d+)?'), (match) {
      String numStr = match.group(0)!;
      final parts = numStr.split('.');
      final ints = parts[0];
      String res = '';
      int count = 0;
      for (int i = ints.length - 1; i >= 0; i--) {
        count++;
        res = ints[i] + res;
        if (count % 3 == 0 && i != 0) res = '.$res';
      }
      if (parts.length > 1) return '$res,${parts[1]}';
      return res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _showExtras = !_showExtras),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Center(
                  child: AnimatedRotation(
                    turns: _showExtras ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Colors.white54, size: 24),
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState:
                  _showExtras ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                            child: Icon(Icons.photo_library_rounded,
                                color: Colors.white, size: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: color, size: 20),
                            const SizedBox(height: 2),
                            const Text('Lokasi Nonaktifkan',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showWalletPicker(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              color: color, size: 16),
                          if (widget.selectedWallet != null) ...[
                            const SizedBox(width: 4),
                            Text(widget.selectedWallet!.name,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.noteController,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Nota',
                        hintStyle:
                            TextStyle(fontSize: 14, color: Colors.black38),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatAmount(widget.amount),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildKeyGrid(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyGrid(Color color) {
    final rows = [
      ['C', '÷', '×', '⌫'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['DATE', '0', '.', '✓'],
    ];

    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: row.map((k) {
                    bool isDigit = RegExp(r'[0-9.]').hasMatch(k);
                    bool isAction = k == '✓';

                    Color btnColor;
                    Color textColor;
                    if (isAction) {
                      btnColor = Colors.white;
                      textColor = color;
                    } else if (isDigit) {
                      btnColor = Colors.white;
                      textColor = Colors.black87;
                    } else {
                      btnColor = Colors.white.withOpacity(0.25);
                      textColor = Colors.white;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            if (k == '✓') {
                              widget.onSave();
                            } else if (k == 'DATE') {
                              _handleDatePicker(context);
                            } else {
                              widget.onKeypadTap(k);
                            }
                          },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: btnColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isDigit || isAction
                                  ? [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: _buildKeyContent(k, textColor),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildKeyContent(String k, Color color) {
    if (k == '⌫')
      return Icon(Icons.backspace_rounded, color: color, size: 18);
    if (k == '✓') return Icon(Icons.check_rounded, color: color, size: 24);
    if (k == 'DATE') {
      final now = DateTime.now();
      final isToday = widget.selectedDate.year == now.year &&
          widget.selectedDate.month == now.month &&
          widget.selectedDate.day == now.day;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded,
              color: color, size: isToday ? 16 : 14),
          if (!isToday) ...[
            const SizedBox(height: 2),
            Text(
              '${widget.selectedDate.day}/${widget.selectedDate.month}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      );
    }
    return Text(k,
        style:
            TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color));
  }

  Future<void> _handleDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.themeColor,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateChanged(picked);
    }
  }

  void _showWalletPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletPicker(
        themeColor: widget.themeColor,
        selectedWallet: widget.selectedWallet,
        onWalletChanged: widget.onWalletChanged,
      ),
    );
  }
}

class _WalletPicker extends ConsumerWidget {
  final Color themeColor;
  final WalletModel? selectedWallet;
  final ValueChanged<WalletModel?> onWalletChanged;

  const _WalletPicker({
    required this.themeColor,
    this.selectedWallet,
    required this.onWalletChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);

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
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Pilih Dompet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          walletsAsync.when(
            data: (wallets) => Column(
              children: wallets
                  .map((w) => ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.account_balance_wallet_rounded,
                              color: themeColor, size: 20),
                        ),
                        title: Text(w.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Rp ${w.balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                          style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        trailing: selectedWallet?.id == w.id
                            ? Icon(Icons.check_circle_rounded,
                                color: themeColor)
                            : null,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          onWalletChanged(w);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
