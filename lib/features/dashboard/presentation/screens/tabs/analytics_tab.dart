import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';

class AnalyticsTab extends ConsumerStatefulWidget {
  const AnalyticsTab({super.key});

  @override
  ConsumerState<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<AnalyticsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _animation;

  String _filterType = 'Bulan Ini';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _filters = [
    'Semua', 'Hari Ini', 'Kemarin', 'Minggu Ini', 'Minggu Lalu', 
    'Bulan Ini', 'Bulan Lalu', 'Tahun Ini', 'Tahun Lalu', 
    '7 Hari Terakhir', '30 Hari Terakhir', '90 Hari Terakhir', 'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    
    _setFilter(_filterType);
    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _setFilter(String type) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (type) {
      case 'Semua':
        start = null;
        end = null;
        break;
      case 'Hari Ini':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Kemarin':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'Minggu Ini':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = now;
        break;
      case 'Minggu Lalu':
        final lastMon = now.subtract(Duration(days: now.weekday + 6));
        start = DateTime(lastMon.year, lastMon.month, lastMon.day);
        final lastSun = start.add(const Duration(days: 6));
        end = DateTime(lastSun.year, lastSun.month, lastSun.day, 23, 59, 59);
        break;
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'Bulan Lalu':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'Tahun Ini':
        start = DateTime(now.year, 1, 1);
        end = now;
        break;
      case 'Tahun Lalu':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case '7 Hari Terakhir':
        start = now.subtract(const Duration(days: 6));
        start = DateTime(start.year, start.month, start.day);
        end = now;
        break;
      case '30 Hari Terakhir':
        start = now.subtract(const Duration(days: 29));
        start = DateTime(start.year, start.month, start.day);
        end = now;
        break;
      case '90 Hari Terakhir':
        start = now.subtract(const Duration(days: 89));
        start = DateTime(start.year, start.month, start.day);
        end = now;
        break;
      case 'Custom':
        return; // Don't fetch yet, wait for picker
    }

    setState(() {
      _filterType = type;
      _startDate = start;
      _endDate = end;
    });
    _fetchData();
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _filterType = 'Custom';
        _startDate = range.start;
        _endDate = range.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      });
      _fetchData();
    }
  }

  void _fetchData() {
    final activeBook = ref.read(bookProvider).activeBook;
    if (activeBook != null) {
      ref.read(transactionProvider.notifier).fetchTransactions(
            activeBook.id,
            startDate: _startDate,
            endDate: _endDate,
          );
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transState = ref.watch(transactionProvider);
    final catState = ref.watch(categoryProvider);
    final wallets = ref.watch(walletProvider).value ?? [];
    final List<TransactionModel> transactions = transState.transactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab('expense', transactions, catState),
                _buildOverviewTab('income', transactions, catState),
                _buildBudgetTab(transactions, catState),
                _buildTrendTab(transactions),
                _buildAssetTab(wallets),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Analitik',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: _fetchData,
                  ),
                  // Date Filter Dropdown
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'Custom') {
                        _pickCustomRange();
                      } else {
                        _setFilter(val);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _filterType,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => _filters.map((f) => PopupMenuItem(
                      value: f,
                      child: Text(f, style: const TextStyle(fontSize: 14)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            // Custom Animated Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final isSelected = _tabController.index == i;
                    final icons = [
                      Icons.trending_down_rounded,
                      Icons.trending_up_rounded,
                      Icons.account_balance_wallet_rounded,
                      Icons.show_chart_rounded,
                      Icons.pie_chart_rounded,
                    ];
                    final labels = ['Pengeluaran', 'Pemasukan', 'Anggaran', 'Tren', 'Aset'];

                    return GestureDetector(
                      onTap: () {
                        _tabController.animateTo(i);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icons[i],
                              color: isSelected ? AppColors.primary : Colors.white70,
                              size: 20,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Text(
                                labels[i],
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TABS ───────────────────────────────────────────────────────────

  Widget _buildOverviewTab(String type, List<TransactionModel> transactions, CategoryState catState) {
    final filtered = transactions.where((t) => t.type == type).toList();
    if (filtered.isEmpty) return _buildEmptyState();

    double total = filtered.fold(0.0, (sum, t) => sum + t.amount);
    
    // Group by category
    final Map<String, double> catTotals = {};
    for (var t in filtered) {
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
    }
    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildBigSummaryCard(total, type),
              const SizedBox(height: 20),
              _buildDonutChart(sorted, catState, total, type),
              const SizedBox(height: 20),
              _buildTopCategories(sorted, catState, total),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetTab(List<TransactionModel> transactions, CategoryState catState) {
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    final Map<String, double> catTotals = {};
    for (var t in expenses) {
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
    }

    final expenseCats = catState.allParents.where((c) => c.type == 'expense').toList();
    if (expenseCats.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenseCats.length,
      itemBuilder: (context, i) {
        final cat = expenseCats[i];
        final actual = catTotals[cat.id] ?? 0.0;
        final budget = 1000000.0; // Placeholder Default Budget
        final ratio = (actual / budget).clamp(0.0, 1.0);
        final isOverflow = actual > budget;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(cat.icon, color: cat.color, size: 20),
                  const SizedBox(width: 8),
                  Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Text(
                    '${formatRp(actual)} / ${formatRp(budget)}',
                    style: TextStyle(
                      fontSize: 12, 
                      color: isOverflow ? Colors.red : Colors.grey,
                      fontWeight: isOverflow ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(isOverflow ? Colors.red : cat.color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOverflow ? 'Melebihi anggaran!' : '${(ratio * 100).toStringAsFixed(1)}% terpakai',
                style: TextStyle(fontSize: 10, color: isOverflow ? Colors.red : Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendTab(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return _buildEmptyState();
    
    // Group by date
    final Map<int, double> dailyExp = {};
    final Map<int, double> dailyInc = {};
    int maxDay = 30; // Default fallback

    if (_startDate != null && _endDate != null) {
      maxDay = _endDate!.difference(_startDate!).inDays + 1;
      for (var t in transactions) {
        final dayIndex = t.date.difference(_startDate!).inDays + 1;
        if (t.type == 'expense') dailyExp[dayIndex] = (dailyExp[dayIndex] ?? 0) + t.amount;
        else dailyInc[dayIndex] = (dailyInc[dayIndex] ?? 0) + t.amount;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSpendingTrendChart(dailyExp, dailyInc, maxDay),
          const SizedBox(height: 20),
          _buildInsightsSummary(transactions),
        ],
      ),
    );
  }

  Widget _buildAssetTab(List wallets) {
    if (wallets.isEmpty) return _buildEmptyState();
    
    double totalAset = wallets.fold(0.0, (sum, w) => sum + w.balance);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildBigSummaryCard(totalAset, 'aset'),
          const SizedBox(height: 20),
          _buildWalletDistribution(wallets, totalAset),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: wallets.map((w) => _buildWalletRow(w)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGETS ────────────────────────────────────────────────────────

  Widget _buildBigSummaryCard(double amount, String type) {
    String label = type == 'expense' ? 'Total Pengeluaran' : (type == 'income' ? 'Total Pemasukan' : 'Total Aset');
    Color color = type == 'expense' ? AppColors.expense : (type == 'income' ? AppColors.income : AppColors.primary);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            formatRp(amount),
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 12),
            Text(
              '${DateFormat('d MMM').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonutChart(List<MapEntry<String, double>> sorted, CategoryState catState, double total, String type) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribusi Kategori', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: sorted.map((e) {
                  final cat = catState.allParents.firstWhere((c) => c.id == e.key, orElse: () => catState.allParents.first);
                  return PieChartSectionData(
                    color: cat.color,
                    value: e.value,
                    radius: 30,
                    title: '',
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(List<MapEntry<String, double>> sorted, CategoryState catState, double total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...sorted.take(5).map((e) {
            final cat = catState.allParents.firstWhere((c) => c.id == e.key, orElse: () => catState.allParents.first);
            final pct = (e.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(cat.icon, color: cat.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatRp(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('$pct%', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWalletDistribution(List wallets, double total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text('Distribusi Dompet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: wallets.map((w) {
                  final color = AppColors.walletGradients[w.type]?.first ?? AppColors.primary;
                  return PieChartSectionData(color: color, value: max(0, w.balance), radius: 20, title: '');
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletRow(wallet) {
    final color = AppColors.walletGradients[wallet.type]?.first ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(formatRp(wallet.balance), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightsSummary(List<TransactionModel> transactions) {
     // Reuse logic from current Insights card but adapted
     double totalExp = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
     int days = _startDate != null && _endDate != null ? _endDate!.difference(_startDate!).inDays + 1 : 30;
     double avg = totalExp / max(1, days);

     return _buildInsightsCard(avg, 0, 0, 'Insight');
  }

  Widget _buildSpendingTrendChart(Map<int, double> dailyExp, Map<int, double> dailyInc, int maxDay) {
    final expSpots = dailyExp.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()..sort((a,b) => a.x.compareTo(b.x));
    final incSpots = dailyInc.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()..sort((a,b) => a.x.compareTo(b.x));

    double maxY = 0;
    for (var s in expSpots) if (s.y > maxY) maxY = s.y;
    for (var s in incSpots) if (s.y > maxY) maxY = s.y;
    if (maxY == 0) maxY = 100000;
    maxY *= 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grafik Tren', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY/5),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text(_formatCompact(v), style: const TextStyle(fontSize: 9)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: max(1, maxDay/5), getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                  topTitles: const AxisTitles(), rightTitles: const AxisTitles()
                ),
                borderData: FlBorderData(show: false),
                minX: 1, maxX: maxDay.toDouble(), minY: 0, maxY: maxY,
                lineBarsData: [
                  LineChartBarData(spots: expSpots, isCurved: true, color: AppColors.expense, barWidth: 3, dotData: const FlDotData(show: false)),
                  LineChartBarData(spots: incSpots, isCurved: true, color: AppColors.income, barWidth: 3, dotData: const FlDotData(show: false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tidak ada data', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(double avg, int highDay, double highAmt, String topCat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _insightRow(Icons.calendar_today, 'Rata-rata harian', formatRp(avg)),
          const SizedBox(height: 12),
          _insightRow(Icons.category, 'Status', topCat),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}rb';
    return value.toStringAsFixed(0);
  }
}
