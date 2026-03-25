import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'tabs/home_tab.dart';
import 'tabs/wallets_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/settings_tab.dart';
import 'package:urmoney/features/transactions/presentation/screens/receipt_scanner_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tabIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    WalletsTab(),
    AnalyticsTab(),
    SettingsTab(),
  ];

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // Allow body to expand behind the floating navbar
      body: IndexedStack(
        index: _tabIndex,
        children: _pages,
      ),
      floatingActionButton: _tabIndex != 3
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet_rounded, 'label': 'Dompet'},
      {'icon': Icons.qr_code_scanner_rounded, 'activeIcon': Icons.qr_code_scanner_rounded, 'label': 'Scan'},
      {'icon': Icons.bar_chart_outlined, 'activeIcon': Icons.bar_chart_rounded, 'label': 'Analitik'},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      height: 90, // Fixed height for consistency
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final item = items[i];
            int? tabIdx;
            if (i == 0) tabIdx = 0;
            else if (i == 1) tabIdx = 1;
            else if (i == 2) tabIdx = null; // scanner
            else if (i == 3) tabIdx = 2;
            else tabIdx = 3;

            final isActive = tabIdx != null && _tabIndex == tabIdx;
            final isCenter = i == 2;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (i == 2) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()));
                  } else {
                    setState(() => _tabIndex = tabIdx!);
                  }
                },
                borderRadius: BorderRadius.circular(28),
                child: isCenter
                    ? Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(item['icon'] as IconData, color: Colors.white, size: 24),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                            color: isActive ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
