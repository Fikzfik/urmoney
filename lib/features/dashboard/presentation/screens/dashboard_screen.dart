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
import 'package:urmoney/features/assistant/presentation/screens/assistant_overlay.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tabIndex = 0;
  bool _isAnalyzing = false;
  OverlayEntry? _overlayEntry;
  int _hoveredIndex = -1;
  final GlobalKey _centerBtnKey = GlobalKey();

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
              child: isCenter
                  ? GestureDetector(
                      key: _centerBtnKey,
                      onTap: _openAddTransaction, // simple tap opens manual add
                      onLongPressStart: (details) => _showHoldMenu(),
                      onLongPressMoveUpdate: (details) => _updateHoldMenu(details),
                      onLongPressEnd: (details) => _endHoldMenu(),
                      onLongPressCancel: () => _endHoldMenu(isCancel: true),
                      child: Center(
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
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        setState(() => _tabIndex = tabIdx!);
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Column(
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

  void _showHoldMenu() {
    if (_overlayEntry != null) return;
    
    RenderBox? renderBox = _centerBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final centerPos = renderBox.localToGlobal(renderBox.size.center(Offset.zero));

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateOverlay) {
            return Positioned.fill(
              child: Stack(
                children: [
                  // Barrier to dim background
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, val, child) => Container(color: Colors.black.withOpacity(0.5 * val)),
                    ),
                  ),
                  // Bubbles
                  ...List.generate(3, (index) {
                    final isHovered = _hoveredIndex == index;
                    Offset pos;
                    String label;
                    IconData icon;
                    if (index == 0) { pos = const Offset(-80, -90); label = 'Manual'; icon = Icons.edit_rounded; }
                    else if (index == 1) { pos = const Offset(0, -110); label = 'Scan'; icon = Icons.qr_code_scanner_rounded; }
                    else { pos = const Offset(80, -90); label = 'Suara'; icon = Icons.mic_rounded; }
                    
                    return Positioned(
                      left: centerPos.dx + pos.dx - 30, // 30 is half of 60 size
                      top: centerPos.dy + pos.dy - 30,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: isHovered ? 1.15 : 1.0),
                        duration: const Duration(milliseconds: 150),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    color: isHovered ? AppColors.accent : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: isHovered ? AppColors.accent.withOpacity(0.6) : Colors.black26, 
                                        blurRadius: 12, spreadRadius: isHovered ? 2 : 0)
                                    ],
                                  ),
                                  child: Icon(icon, color: isHovered ? Colors.white : AppColors.primary, size: 30),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label, 
                                  style: TextStyle(
                                    color: isHovered ? AppColors.accent : Colors.white, 
                                    fontWeight: FontWeight.bold, fontSize: 13,
                                    decoration: TextDecoration.none,
                                    shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]
                                  )
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    );
                  }),
                ],
              ),
            );
          }
        );
      }
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateHoldMenu(LongPressMoveUpdateDetails details) {
    if (_overlayEntry == null) return;
    
    RenderBox? renderBox = _centerBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final finger = details.globalPosition;
    final centerPos = renderBox.localToGlobal(renderBox.size.center(Offset.zero));

    final offsets = [
      centerPos + const Offset(-80, -90),
      centerPos + const Offset(0, -110),
      centerPos + const Offset(80, -90),
    ];

    int newHovered = -1;
    for (int i = 0; i < offsets.length; i++) {
      if ((finger - offsets[i]).distance < 50) {
        newHovered = i;
        break;
      }
    }

    if (_hoveredIndex != newHovered) {
      _hoveredIndex = newHovered;
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _endHoldMenu({bool isCancel = false}) {
    if (_overlayEntry != null) {
      final selected = isCancel ? -1 : _hoveredIndex;
      _overlayEntry?.remove();
      _overlayEntry = null;
      _hoveredIndex = -1;

      if (selected == 0) _openAddTransaction();
      else if (selected == 1) _startScan();
      else if (selected == 2) _startVoiceAssistant();
    }
  }

  void _startVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AssistantOverlay(),
    );
  }
}
