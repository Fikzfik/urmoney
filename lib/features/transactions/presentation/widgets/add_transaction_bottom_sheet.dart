import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/screens/category_settings_screen.dart';

String _evalMath(String expr) {
  try {
    var s = expr.replaceAll('×', '*').replaceAll('÷', '/');
    List<String> tokens = [];
    String numStr = '';
    for (int i=0; i<s.length; i++) {
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
    
    for (int i=1; i<tokens.length-1; i+=2) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double a = double.parse(tokens[i-1]);
          double b = double.parse(tokens[i+1]);
          double res = tokens[i] == '*' ? a * b : a / b;
          tokens.replaceRange(i-1, i+2, [res.toString()]);
          i -= 2; 
        }
    }
    double result = double.parse(tokens[0]);
    for (int i=1; i<tokens.length-1; i+=2) {
        double b = double.parse(tokens[i+1]);
        if (tokens[i] == '+') result += b;
        if (tokens[i] == '-') result -= b;
    }
    
    if (result == result.toInt()) return result.toInt().toString();
    String formatted = result.toStringAsFixed(2);
    if (formatted.endsWith('.00')) formatted = formatted.substring(0, formatted.length - 3);
    else if (formatted.endsWith('0')) formatted = formatted.substring(0, formatted.length - 1);
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
      _amount = _updateAmountForm(_amount, val);
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
            showCheckmark: false,
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
    final themeColor = widget.isExpense ? Colors.blue : Colors.teal;
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
      _amount = _updateAmountForm(_amount, val);
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

class _CustomKeypad extends StatefulWidget {
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

  @override
  State<_CustomKeypad> createState() => _CustomKeypadState();
}

class _CustomKeypadState extends State<_CustomKeypad> {
  bool _showExtras = false;
  String _selectedWallet = 'Bawaan';
  final List<String> _wallets = ['Bawaan', 'Gopay', 'Dana', 'Bank BCA', 'Cash'];

  String _formatAmount(String amt) {
    if (amt.isEmpty || amt == '0') return '0';
    return amt.replaceAllMapped(RegExp(r'\d+(\.\d+)?'), (match) {
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
            // ── ^ handle ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _showExtras = !_showExtras),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Center(
                  child: AnimatedRotation(
                    turns: _showExtras ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54, size: 24),
                  ),
                ),
              ),
            ),
            // ── extras panel (gallery + GPS) ───────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showExtras ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded, color: color, size: 20),
                              const SizedBox(height: 2),
                              const Text('Lokasi Nonaktifkan', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

            // Note & Amount Row
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showWalletPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.account_balance_wallet_rounded, color: color, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.noteController,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Nota',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatAmount(widget.amount),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Keypad Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      ['TODAY', '0', '.', '✓'],
    ];

    return Column(
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: row.map((k) {
            bool isDigit = RegExp(r'[0-9.]').hasMatch(k) || k == 'TODAY';
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
                    if (k == '✓') widget.onSave();
                    else widget.onKeypadTap(k);
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDigit || isAction ? [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ] : [],
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
      )).toList(),
    );
  }

  Widget _buildKeyContent(String k, Color color) {
    if (k == '⌫') return Icon(Icons.backspace_rounded, color: color, size: 18);
    if (k == '✓') return Icon(Icons.check_rounded, color: color, size: 24);
    if (k == 'TODAY') return Icon(Icons.calendar_today_rounded, color: color, size: 18);
    return Text(k, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color));
  }

  void _showWalletPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(height: 4, width: 40,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Pilih Dompet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._wallets.map((w) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: widget.themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: widget.themeColor, size: 20),
              ),
              title: Text(w, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: _selectedWallet == w
                  ? Icon(Icons.check_circle_rounded, color: widget.themeColor)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                setState(() => _selectedWallet = w);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

