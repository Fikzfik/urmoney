import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'package:urmoney/features/transactions/presentation/screens/scan_review_screen.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/wallets_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/settings_tab.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:urmoney/core/services/ai_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tabIndex = 0;
  bool _isAnalyzing = false;

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
      builder: (context) => AddTransactionBottomSheet(),
    );
  }

  Future<void> _startScan() async {
    // 1. Check Permissions
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin kamera dibutuhkan untuk scan struk')),
        );
      }
      return;
    }

    try {
      // 3. Start Document Scanner
      List<String>? pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: true,
      );

      if (pictures != null && pictures.isNotEmpty) {
        final imagePath = pictures.first;
        setState(() => _isAnalyzing = true);

        // 4. Read file and process with AI
        final file = File(imagePath);
        final bytes = await file.readAsBytes();

        // Pass existing categories to AI for better matching
        final catState = ref.read(categoryProvider);
        final catNotifier = ref.read(categoryProvider.notifier);
        final existingCategories = catNotifier.getAllCategoryNames();
        final existingItems = catNotifier.getAllItemNames();
        
        final aiResult = await ref.read(aiServiceProvider).processReceipt(
          bytes,
          existingCategories: existingCategories,
          existingCategoryItems: existingItems,
        );

        setState(() => _isAnalyzing = false);

        if (aiResult != null && mounted) {
          // Navigate to review screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanReviewScreen(result: aiResult),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI gagal menganalisa struk. Coba lagi ya!')),
          );
          _openAddTransaction(); // Fallback to empty form
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // Allow body to expand behind the floating navbar
      body: Stack(
        children: [
          IndexedStack(
            index: _tabIndex,
            children: _pages,
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 3),
                        const SizedBox(height: 24),
                        const Text(
                          'Menganalisa Struk...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI sedang mendeteksi teks',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet_rounded, 'label': 'Dompet'},
      {'icon': Icons.add_rounded, 'activeIcon': Icons.add_rounded, 'label': ''}, // Add center button
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
                    _showAddOptions(context);
                  } else {
                    setState(() => _tabIndex = tabIdx!);
                  }
                },
                onLongPress: () {
                  if (i == 2) {
                    _showAddOptions(context);
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

  void _showAddOptions(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 110),
            child: Material(
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionBubble(context, Icons.edit_rounded, 'Manual', () {
                    Navigator.pop(context);
                    _openAddTransaction();
                  }),
                  const SizedBox(width: 24),
                  _buildOptionBubble(context, Icons.qr_code_scanner_rounded, 'Scan', () {
                    Navigator.pop(context);
                    _startScan();
                  }),
                  const SizedBox(width: 24),
                  _buildOptionBubble(context, Icons.mic_rounded, 'Suara', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur Voice Card segera hadir!')),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  Widget _buildOptionBubble(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            decoration: TextDecoration.none, // Inherit from material correctly
          ),
        ),
      ],
    );
  }
}
