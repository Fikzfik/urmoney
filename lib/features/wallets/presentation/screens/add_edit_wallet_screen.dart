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
  late TextEditingController balCtrl;
  late TextEditingController taxRateCtrl;
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
    balCtrl = TextEditingController(text: w?.balance.toStringAsFixed(0) ?? '0');
    taxRateCtrl = TextEditingController(text: w?.taxRate?.toString() ?? '');
    taxDayCtrl = TextEditingController(text: w?.taxDay?.toString() ?? '');
    interestRateCtrl = TextEditingController(text: w?.interestRate?.toString() ?? '');
    payoutDayCtrl = TextEditingController(text: w?.payoutDay?.toString() ?? '');
    payoutSchedule = w?.payoutSchedule ?? 'daily';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    balCtrl.dispose();
    taxRateCtrl.dispose();
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
        double.tryParse(balCtrl.text) ?? 0.0,
        taxRate: selectedType == 'bankmobile' ? double.tryParse(taxRateCtrl.text) : null,
        taxDay: selectedType == 'bankmobile' ? int.tryParse(taxDayCtrl.text) : null,
        interestRate: selectedType == 'digitalbank' ? double.tryParse(interestRateCtrl.text) : null,
        payoutSchedule: selectedType == 'digitalbank' ? payoutSchedule : null,
        payoutDay: selectedType == 'digitalbank' && payoutSchedule == 'monthly' ? int.tryParse(payoutDayCtrl.text) : null,
      );
    } else {
      notifier.updateWallet(
        widget.wallet!.id,
        name: nameCtrl.text.trim(),
        type: selectedType,
        balance: double.tryParse(balCtrl.text) ?? 0.0,
        taxRate: selectedType == 'bankmobile' ? double.tryParse(taxRateCtrl.text) : null,
        taxDay: selectedType == 'bankmobile' ? int.tryParse(taxDayCtrl.text) : null,
        interestRate: selectedType == 'digitalbank' ? double.tryParse(interestRateCtrl.text) : null,
        payoutSchedule: selectedType == 'digitalbank' ? payoutSchedule : null,
        payoutDay: selectedType == 'digitalbank' && payoutSchedule == 'monthly' ? int.tryParse(payoutDayCtrl.text) : null,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final types = {
      'bankmobile': {'name': 'Bank Mobile', 'icon': Icons.account_balance, 'color': Colors.blue},
      'digitalbank': {'name': 'Digital Bank', 'icon': Icons.phonelink_ring_rounded, 'color': Colors.purple},
      'ewallet': {'name': 'e-Wallet', 'icon': Icons.wallet_rounded, 'color': Colors.orange},
      'cash': {'name': 'Tunai', 'icon': Icons.money_rounded, 'color': Colors.green},
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.wallet == null ? 'Tambah Dompet' : 'Edit Dompet',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Tipe Dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: types.entries.map((e) {
                final isSelected = selectedType == e.key;
                final data = e.value as Map<String, dynamic>;
                return InkWell(
                  onTap: () => setState(() => selectedType = e.key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 60) / 2,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? data['color'].withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? data['color'] : Colors.transparent, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(data['icon'], color: isSelected ? data['color'] : AppColors.textSecondary, size: 32),
                        const SizedBox(height: 8),
                        Text(data['name'],
                            style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? data['color'] : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildField('Nama Dompet', nameCtrl, Icons.edit_note_rounded),
            const SizedBox(height: 16),
            _buildField('Saldo (Rp)', balCtrl, Icons.payments_rounded, keyboardType: TextInputType.number),

            if (selectedType == 'bankmobile') ...[
              const SizedBox(height: 24),
              const Text('Pengaturan Pajak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Pajak (%)', taxRateCtrl, Icons.percent_rounded, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('Tgl Potongan (1-31)', taxDayCtrl, Icons.calendar_month_rounded, keyboardType: TextInputType.number)),
                ],
              ),
            ],

            if (selectedType == 'digitalbank') ...[
              const SizedBox(height: 24),
              const Text('Pengaturan Deposito/Bunga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildField('Bunga (%)', interestRateCtrl, Icons.trending_up_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Jadwal Pencairan', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Row(
                children: [
                  _radioTile('daily', 'Harian'),
                  const SizedBox(width: 16),
                  _radioTile('monthly', 'Bulanan'),
                ],
              ),
              if (payoutSchedule == 'monthly') ...[
                const SizedBox(height: 8),
                _buildField('Tgl Pencairan (1-31)', payoutDayCtrl, Icons.calendar_today_rounded, keyboardType: TextInputType.number),
              ],
            ],

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                ),
                child: const Text('SIMPAN DOMPET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          hintText: label,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _radioTile(String value, String label) {
    final isSelected = payoutSchedule == value;
    return InkWell(
      onTap: () => setState(() => payoutSchedule = value),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: payoutSchedule,
            onChanged: (v) => setState(() => payoutSchedule = v!),
            activeColor: AppColors.primary,
          ),
          Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
