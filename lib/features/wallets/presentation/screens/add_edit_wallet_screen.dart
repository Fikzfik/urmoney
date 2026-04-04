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
  late PageController _pageController;
  int _currentStep = 0;

  late String selectedType;
  late TextEditingController nameCtrl;
  late TextEditingController taxAmountCtrl;
  late TextEditingController taxDayCtrl;
  late TextEditingController interestRateCtrl;
  late TextEditingController payoutDayCtrl;
  late String payoutSchedule;

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

    _currentStep = w != null ? 2 : 0;
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    nameCtrl.dispose();
    taxAmountCtrl.dispose();
    taxDayCtrl.dispose();
    interestRateCtrl.dispose();
    payoutDayCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    } else {
      Navigator.pop(context);
    }
  }

  void _save() {
    if (nameCtrl.text.trim().isEmpty) return;
    final notifier = ref.read(walletProvider.notifier);
    if (widget.wallet == null) {
      notifier.addWallet(
        nameCtrl.text.trim(),
        selectedType,
        0.0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTypePicker(),
                _buildItemPicker(),
                _buildDetailsForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final gradColors = AppColors.walletGradients[selectedType] ?? [AppColors.primary, AppColors.accent];
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(_currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: _prevStep,
                  ),
                  Expanded(
                    child: Text(
                      widget.wallet == null ? 'Tambah Dompet' : 'Edit Dompet',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              // Progress indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isDone = _currentStep > i;
                  final isCurrent = _currentStep == i;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone || isCurrent ? Colors.white : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STEP 1: TYPE PICKER ───────────────────────────────────────────
  Widget _buildTypePicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Jenis Dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Apa tipe simpanan yang ingin kamu buat?', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _types.length,
            itemBuilder: (context, i) {
              final t = _types[i];
              final tColors = AppColors.walletGradients[t['key']] ?? [AppColors.primary, AppColors.accent];
              return GestureDetector(
                onTap: () {
                  setState(() => selectedType = t['key'] as String);
                  _nextStep();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: tColors.first.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(gradient: LinearGradient(colors: tColors), shape: BoxShape.circle),
                        child: Icon(t['icon'] as IconData, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: ITEM PICKER ───────────────────────────────────────────
  Widget _buildItemPicker() {
    final list = _suggestions[selectedType] ?? [];
    final tColors = AppColors.walletGradients[selectedType] ?? [AppColors.primary, AppColors.accent];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih ${_types.firstWhere((t) => t['key'] == selectedType)['name']}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Tentukan nama penyedia layananmu', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i < list.length) {
                final s = list[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => nameCtrl.text = s);
                    _nextStep();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(s, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: tColors.first),
                          textAlign: TextAlign.center),
                    ),
                  ),
                );
              }
              // Custom option
              return GestureDetector(
                onTap: () => _nextStep(),
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 16, color: Colors.grey),
                        Text('Lainnya', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── STEP 3: DETAILS FORM ──────────────────────────────────────────
  Widget _buildDetailsForm() {
    final gradColors = AppColors.walletGradients[selectedType] ?? [AppColors.primary, AppColors.accent];
    final typeData = _types.firstWhere((t) => t['key'] == selectedType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: gradColors), borderRadius: BorderRadius.circular(12)),
                  child: Icon(typeData['icon'] as IconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nameCtrl.text.isEmpty ? 'Penyedia Layanan' : nameCtrl.text, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(typeData['name'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.grey),
                  onPressed: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Konfigurasi Lengkap'),
          const SizedBox(height: 16),
          _buildField('Nama Dompet', nameCtrl, Icons.edit_note_rounded, gradColors.first),
          
          if (selectedType == 'bankmobile') ...[
            const SizedBox(height: 20),
            _buildField('Jumlah Pajak / Adm (Rp)', taxAmountCtrl, Icons.money_off_rounded, gradColors.first, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildField('Tgl Potong (1-31)', taxDayCtrl, Icons.calendar_month_rounded, gradColors.first, keyboardType: TextInputType.number),
          ],

          if (selectedType == 'digitalbank') ...[
            const SizedBox(height: 20),
            _buildField('Bunga / Tabungan (%)', interestRateCtrl, Icons.percent_rounded, gradColors.first, keyboardType: TextInputType.number),
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
              _buildField('Tgl Pencairan (1-31)', payoutDayCtrl, Icons.calendar_today_rounded, gradColors.first, keyboardType: TextInputType.number),
            ],
          ],

          const SizedBox(height: 48),
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
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary));
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, Color color, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
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
