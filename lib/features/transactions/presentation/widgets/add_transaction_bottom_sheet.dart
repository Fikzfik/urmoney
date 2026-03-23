import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/screens/category_settings_screen.dart';
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
              height: 5, width: 50,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan'), Tab(text: 'Transfer')],
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
  int _selectedParentIndex = -1;
  int _selectedItemIndex = -1;
  final TextEditingController _noteController = TextEditingController();

  void _onKeypadTap(String val) {
    setState(() {
      if (val == '⌫') {
        if (_amount.length > 1) _amount = _amount.substring(0, _amount.length - 1);
        else _amount = '0';
      } else if (val == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') _amount = val;
        else if (_amount.length < 15) _amount += val;
      }
    });
  }


  Widget _buildItemsGrid(List<CategoryItem> items, Color themeColor) {
    if (items.isEmpty) {
      return Center(
        child: Text('Belum ada item', style: TextStyle(color: Colors.grey.shade400)),
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
                height: 55, width: 55,
                decoration: BoxDecoration(
                  color: isSelected ? themeColor.withOpacity(0.15) : Colors.white,
                  border: Border.all(
                    color: isSelected ? themeColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 8)] : [],
                ),
                child: Icon(
                  item.icon,
                  color: isSelected ? themeColor : Colors.grey.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
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
  Widget _buildChipsRow(BuildContext context, List<ParentCategory> parents, int activeIndex, Color themeColor) {
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
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategorySettingsScreen()));
                setState(() {});
              },
            );
          }
          final parent = parents[index];
          final isSelected = activeIndex == index;
          return ChoiceChip(
            avatar: Icon(parent.icon, size: 14, color: isSelected ? Colors.white : themeColor),
            label: Text(
              parent.label,
              style: TextStyle(fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600),
            ),
            selected: isSelected,
            selectedColor: themeColor,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? themeColor : Colors.grey.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final parents = widget.isExpense ? state.expenseParents : state.incomeParents;
    final themeColor = widget.isExpense ? Colors.redAccent : Colors.teal;
    final activeIdx = _selectedParentIndex.clamp(0, parents.isEmpty ? 0 : parents.length - 1);
    final items = parents.isEmpty ? <CategoryItem>[] : state.itemsFor(parents[activeIdx].id, widget.isExpense);

    return Column(
      children: [
        _buildChipsRow(context, parents, activeIdx, themeColor),
        Expanded(child: _buildItemsGrid(items, themeColor)),
        _CustomKeypad(
          amount: _amount,
          noteController: _noteController,
          onKeypadTap: _onKeypadTap,
          themeColor: themeColor,
          onSave: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _TransferForm extends StatefulWidget {
  const _TransferForm();
  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  String _amount = '0';
  final TextEditingController _noteController = TextEditingController();
  String _fromWallet = 'Gopay';
  String _toWallet = 'Bank BCA';
  final List<String> _wallets = ['Gopay', 'Bank BCA', 'Dana', 'Cash'];

  void _onKeypadTap(String val) {
    setState(() {
      if (val == '⌫') {
        if (_amount.length > 1) _amount = _amount.substring(0, _amount.length - 1);
        else _amount = '0';
      } else if (val == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') _amount = val;
        else if (_amount.length < 15) _amount += val;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildWalletDropdown('Dari Dompet', _fromWallet, (val) => setState(() => _fromWallet = val!)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.blueAccent),
                  ),
                ),
                _buildWalletDropdown('Ke Dompet', _toWallet, (val) => setState(() => _toWallet = val!)),
              ],
            ),
          ),
        ),
        _CustomKeypad(
          amount: _amount,
          noteController: _noteController,
          onKeypadTap: _onKeypadTap,
          themeColor: Colors.blueAccent,
          onSave: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildWalletDropdown(String title, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CustomKeypad extends StatelessWidget {
  final String amount;
  final TextEditingController noteController;
  final Function(String) onKeypadTap;
  final VoidCallback onSave;
  final Color themeColor;

  const _CustomKeypad({
    required this.amount,
    required this.noteController,
    required this.onKeypadTap,
    required this.onSave,
    required this.themeColor,
  });

  String _formatAmount(String amt) {
    if (amt.isEmpty || amt == '0') return '0';
    List<String> parts = amt.split('.');
    String ints = parts[0];
    String res = '';
    int count = 0;
    for (int i = ints.length - 1; i >= 0; i--) {
      count++;
      res = ints[i] + res;
      if (count % 3 == 0 && i != 0 && ints[i-1] != '-') res = '.$res';
    }
    if (parts.length > 1) return '$res,${parts[1]}';
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_note_rounded, color: themeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Tulis Catatan...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Text(
                  _formatAmount(amount),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildRow(['7', '8', '9']),
                      _buildRow(['4', '5', '6']),
                      _buildRow(['1', '2', '3']),
                      _buildRow(['.', '0', '⌫']),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade200),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_rounded, color: Colors.grey.shade600, size: 20),
                                const SizedBox(height: 4),
                                Text('Hari Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(height: 1, color: Colors.grey.shade200),
                      Expanded(
                        flex: 3,
                        child: Material(
                          color: themeColor,
                          child: InkWell(
                            onTap: onSave,
                            child: const Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 36)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((k) {
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: k == keys.last ? 0 : 1),
                  bottom: BorderSide(color: Colors.grey.shade200, width: k == '.' || k == '0' || k == '⌫' ? 0 : 1),
                )
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onKeypadTap(k),
                  child: Center(
                    child: k == '⌫' 
                      ? Icon(Icons.backspace_rounded, color: Colors.grey.shade700)
                      : Text(k, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
