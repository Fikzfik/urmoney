import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';

class AddEditWalletScreen extends ConsumerStatefulWidget {
  final WalletModel? wallet;
  const AddEditWalletScreen({super.key, this.wallet});

  @override
  ConsumerState<AddEditWalletScreen> createState() => _AddEditWalletScreenState();
}

class _AddEditWalletScreenState extends ConsumerState<AddEditWalletScreen> {
  late String selectedType;
  late TextEditingController nameCtrl;
  late TextEditingController taxAmountCtrl;
  late TextEditingController taxDayCtrl;
  late TextEditingController interestRateCtrl;
  late TextEditingController payoutDayCtrl;
  late String payoutSchedule;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    selectedType = w?.type ?? 'ewallet';
    nameCtrl = TextEditingController(text: w?.name ?? '');
    taxAmountCtrl = TextEditingController(text: w?.taxRate?.toStringAsFixed(0) ?? '');
    taxDayCtrl = TextEditingController(text: w?.taxDay?.toString() ?? '');
    interestRateCtrl = TextEditingController(text: w?.interestRate?.toString() ?? '');
    payoutDayCtrl = TextEditingController(text: w?.payoutDay?.toString() ?? '');
    payoutSchedule = w?.payoutSchedule ?? 'harian';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    taxAmountCtrl.dispose();
    taxDayCtrl.dispose();
    interestRateCtrl.dispose();
    payoutDayCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (nameCtrl.text.trim().isEmpty) return;
    final notifier = ref.read(walletProvider.notifier);
    if (widget.wallet == null) {
      notifier.addWallet(
        nameCtrl.text.trim(),
        selectedType,
        0.0, // Balance starts at 0 — use transactions to fund
        taxRate: selectedType == 'bankmobile' ? double.tryParse(taxAmountCtrl.text) : null,
        taxDay: selectedType == 'bankmobile' ? int.tryParse(taxDayCtrl.text) : null,
        interestRate: selectedType == 'digitalbank' ? double.tryParse(interestRateCtrl.text) : null,
        payoutSchedule: selectedType == 'digitalbank' ? payoutSchedule : null,
        payoutDay: selectedType == 'digitalbank' && payoutSchedule == 'bulanan' ? int.tryParse(payoutDayCtrl.text) : null,
      );
    } else {
      notifier.updateWallet(
        widget.wallet!.id,
        name: nameCtrl.text.trim(),
        type: selectedType,
        taxRate: selectedType == 'bankmobile' ? double.tryParse(taxAmountCtrl.text) : null,
        taxDay: selectedType == 'bankmobile' ? int.tryParse(taxDayCtrl.text) : null,
        interestRate: selectedType == 'digitalbank' ? double.tryParse(interestRateCtrl.text) : null,
        payoutSchedule: selectedType == 'digitalbank' ? payoutSchedule : null,
        payoutDay: selectedType == 'digitalbank' && payoutSchedule == 'bulanan' ? int.tryParse(payoutDayCtrl.text) : null,
      );
    }
    Navigator.pop(context);
  }

  static const _types = [
    {'key': 'bankmobile', 'name': 'Bank Mobile', 'icon': Icons.account_balance_rounded},
    {'key': 'digitalbank', 'name': 'Digital Bank', 'icon': Icons.phonelink_ring_rounded},
    {'key': 'ewallet', 'name': 'e-Wallet', 'icon': Icons.wallet_rounded},
    {'key': 'cash', 'name': 'Tunai', 'icon': Icons.money_rounded},
    {'key': 'debt', 'name': 'Utang', 'icon': Icons.credit_card_rounded},
    {'key': 'receivable', 'name': 'Piutang', 'icon': Icons.front_hand_rounded},
  ];

  static const _suggestions = {
    'bankmobile': ['BNI', 'BCA', 'Mandiri', 'BRI', 'BTN', 'CIMB Niaga', 'Permata'],
    'digitalbank': ['SeaBank', 'Bank Jago', 'Blu', 'Line Bank', 'Allo Bank', 'Neobank'],
    'ewallet': ['GoPay', 'OVO', 'Dana', 'LinkAja', 'ShopeePay'],
    'cash': ['Dompet', 'Celengan', 'Kas'],
    'debt': ['Kartu Kredit', 'Pinjaman Teman', 'Paylater'],
    'receivable': ['Pinjaman ke Teman', 'Piutang Dagang'],
  };

  @override
  Widget build(BuildContext context) {
    final gradColors = AppColors.walletGradients[selectedType] ?? [AppColors.primary, AppColors.accent];
    final typeData = _types.firstWhere((t) => t['key'] == selectedType);

    return Scaffold(
      body: Column(
        children: [
          // ─── Premium gradient header ─────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 36),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.wallet == null ? 'Tambah Dompet' : 'Edit Dompet',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Icon(typeData['icon'] as IconData, color: Colors.white.withOpacity(0.9), size: 48),
                    const SizedBox(height: 8),
                    Text(
                      nameCtrl.text.isEmpty ? 'Dompet Baru' : nameCtrl.text,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(typeData['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    if (widget.wallet == null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.white70, size: 14),
                            SizedBox(width: 6),
                            Text('Saldo diisi lewat transaksi Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ─── Body ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Type selector (floating pill selector)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: _types.map((t) {
                          final isSelected = selectedType == t['key'];
                          final tGrad = AppColors.walletGradients[t['key']] ?? [AppColors.primary, AppColors.accent];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedType = t['key'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? LinearGradient(colors: tGrad) : null,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Icon(t['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey.shade400, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      (t['name'] as String).split(' ').first,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? Colors.white : Colors.grey.shade500,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Nama Dompet'),
                        const SizedBox(height: 8),
                        _buildSuggestions(),
                        const SizedBox(height: 12),
                        _buildField('Nama Dompet', nameCtrl, Icons.edit_note_rounded, gradColors.first,
                            onChanged: (_) => setState(() {})),

                        if (selectedType == 'bankmobile') ...[
                          const SizedBox(height: 24),
                          _sectionTitle('Pengaturan Pajak', icon: Icons.receipt_long_rounded, color: gradColors.first),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: gradColors.first.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: gradColors.first.withOpacity(0.15)),
                            ),
                            child: Column(
                              children: [
                                _buildField('Jumlah Pajak (Rp)', taxAmountCtrl, Icons.money_off_rounded, gradColors.first,
                                    keyboardType: TextInputType.number),
                                const SizedBox(height: 12),
                                _buildField('Tgl Pemotongan (1-31)', taxDayCtrl, Icons.calendar_month_rounded, gradColors.first,
                                    keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],

                        if (selectedType == 'digitalbank') ...[
                          const SizedBox(height: 24),
                          _sectionTitle('Pengaturan Deposito', icon: Icons.trending_up_rounded, color: gradColors.first),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: gradColors.first.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: gradColors.first.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildField('Bunga / Deposito (%)', interestRateCtrl, Icons.percent_rounded, gradColors.first,
                                    keyboardType: TextInputType.number),
                                const SizedBox(height: 16),
                                Text('Jadwal Pencairan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _radioCard('harian', 'Harian', Icons.wb_sunny_rounded, gradColors.first)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _radioCard('bulanan', 'Bulanan', Icons.calendar_month_rounded, gradColors.first)),
                                  ],
                                ),
                                if (payoutSchedule == 'bulanan') ...[
                                  const SizedBox(height: 12),
                                  _buildField('Tgl Pencairan (1-31)', payoutDayCtrl, Icons.calendar_today_rounded, gradColors.first,
                                      keyboardType: TextInputType.number),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 36),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradColors),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: gradColors.last.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('SIMPAN DOMPET',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: Colors.white)),
                          ),
                        ),
                      ],
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

  Widget _buildSuggestions() {
    final list = _suggestions[selectedType] ?? [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: list.map((s) {
          final isSelected = nameCtrl.text == s;
          final color = AppColors.walletGradients[selectedType]?.first ?? AppColors.primary;
          return GestureDetector(
            onTap: () {
              setState(() {
                nameCtrl.text = s;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? color : Colors.grey.shade200),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? color : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title, {IconData? icon, Color? color}) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 16, color: color ?? AppColors.primary), const SizedBox(width: 6)],
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, Color color,
      {TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color, size: 20),
          hintText: label,
          labelText: label,
          labelStyle: TextStyle(color: color.withOpacity(0.7), fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _radioCard(String value, String label, IconData icon, Color color) {
    final isSelected = payoutSchedule == value;
    return GestureDetector(
      onTap: () => setState(() => payoutSchedule = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
