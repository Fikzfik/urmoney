import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/transactions/data/models/category_item_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _viewType = 'detail';
  DateTime? _selectedDay;

  void _prevMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _refreshData();
  }

  void _nextMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    _refreshData();
  }

  String get _monthLabel => DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshData());
  }

  void _refreshData() {
    final activeBook = ref.read(bookProvider).activeBook;
    if (activeBook != null) {
      ref.read(transactionProvider.notifier).fetchTransactions(activeBook.id, month: _selectedMonth);
      // Check for interest payouts
      ref.read(transactionProvider.notifier).checkAndApplyInterest();
    }
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    int tempYear = _selectedMonth.year;
    int tempMonth = _selectedMonth.month;
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setLocal(() => tempYear--)),
              Text('$tempYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setLocal(() => tempYear++)),
            ],
          ),
          content: SizedBox(
            width: 280,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: List.generate(12, (i) {
                final isSelected = i + 1 == tempMonth;
                return GestureDetector(
                  onTap: () => setLocal(() => tempMonth = i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        months[i],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _selectedMonth = DateTime(tempYear, tempMonth));
                _refreshData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Pilih', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manualRefresh() async {
    await ref.read(bookProvider.notifier).fetchBooks();
    _refreshData();
  }

  String _formatCurrency(double amount) => formatRp(amount);

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookProvider);
    final activeBook = bookState.activeBook;
    final transState = ref.watch(transactionProvider);
    final walletsAsync = ref.watch(walletProvider);
    final totalBalance = walletsAsync.whenOrNull(data: (ws) => ws.fold(0.0, (s, w) => s + w.balance)) ?? 0.0;
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] ?? user?.email?.split('@')[0] ?? 'Pengguna';

    ref.listen(bookProvider.select((s) => s.activeBook?.id), (prev, next) {
      if (next != null && next != prev) _refreshData();
    });

    if (activeBook != null && !transState.hasFetched && !transState.isLoading) {
      Future.microtask(() => _refreshData());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Header ────────────────────────────────────────────────────
          _buildHeader(bookState, activeBook, totalBalance, userName),

          // ─── Body ──────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _manualRefresh,
              child: Column(
                children: [
                  if (_viewType == 'detail') _buildSummaryCard(transState.transactions),
                  Expanded(
                    child: _viewType == 'detail'
                        ? _buildTransactionList(context, transState)
                        : _buildCalendarView(context, transState),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BookState bookState, dynamic activeBook, double totalBalance, String userName) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + view toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, 👋', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                          Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        _ToggleBtn(label: 'Detail', isActive: _viewType == 'detail', onTap: () => setState(() => _viewType = 'detail')),
                        _ToggleBtn(label: 'Kalender', isActive: _viewType == 'calendar', onTap: () => setState(() => _viewType = 'calendar'), isRight: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Saldo', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: totalBalance),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutExpo,
                          builder: (context, value, child) {
                            return Text(formatRp(value),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32, letterSpacing: -0.5));
                          },
                        ),
                      ],
                    ),
                  ),
                  // Animated Illustration Area
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Lottie.network(
                      'https://assets9.lottiefiles.com/packages/lf20_ghp9o9pc.json', // A cute wealth/money animation
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.auto_graph_rounded, color: Colors.white.withOpacity(0.2), size: 60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Book pills
              SizedBox(
                height: 36,
                child: bookState.books.isEmpty
                    ? GestureDetector(
                        onTap: () => _showAddBookDialog(context, ref),
                        child: const _BookPill(label: '+ Buku Baru', isActive: false),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: bookState.books.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == bookState.books.length) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _showAddBookDialog(ctx, ref),
                                child: const _BookPill(label: '+ Buku', isActive: false),
                              ),
                            );
                          }
                          final b = bookState.books[i];
                          final isActive = activeBook?.id == b.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => ref.read(bookProvider.notifier).setActiveBook(b),
                              child: _BookPill(label: b.name, isActive: isActive),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SUMMARY CARD ───────────────────────────────────────────────────────────
  Widget _buildSummaryCard(List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == 'income') income += t.amount;
      else if (t.type == 'expense') expense += t.amount;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Month navigator
          Row(
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthYearPicker(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_monthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.income.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
                        const SizedBox(width: 4),
                        const Text('Pemasukan', style: TextStyle(color: AppColors.income, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 4),
                      Text(_formatCurrency(income), style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.expense.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                        const SizedBox(width: 4),
                        const Text('Pengeluaran', style: TextStyle(color: AppColors.expense, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 4),
                      Text(_formatCurrency(expense), style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TRANSACTION LIST ───────────────────────────────────────────────────────
  Widget _buildTransactionList(BuildContext context, TransactionState transState, {bool shrinkWrap = false, ScrollPhysics? physics}) {
    if (transState.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    final List<dynamic> allMovements = [
      ...transState.transactions,
      ...transState.transfers,
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (_viewType == 'calendar' && _selectedDay != null) {
      allMovements.removeWhere((m) {
        final d = m.date;
        return d.year != _selectedDay!.year || d.month != _selectedDay!.month || d.day != _selectedDay!.day;
      });
    }

    if (allMovements.isEmpty) return _buildEmptyTransactions();

    final grouped = <DateTime, List<dynamic>>{};
    for (var m in allMovements) {
      final date = DateTime(m.date.year, m.date.month, m.date.day);
      grouped.putIfAbsent(date, () => []).add(m);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: 120),
        itemCount: sortedDates.length,
        itemBuilder: (context, i) {
          final date = sortedDates[i];
          final dayMovements = grouped[date]!;
          final dayLabel = DateFormat('EEE, d/M', 'id_ID').format(date);

          return AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 500),
            child: FadeInAnimation(
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 12),
                      child: Row(
                        children: [
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(dayLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    ...dayMovements.map((m) {
                      if (m is TransactionModel) return _buildTransactionCard(context, m);
                      if (m is TransferModel) return _buildTransferCard(context, m);
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    final catState = ref.watch(categoryProvider);
    final wallets = ref.watch(walletProvider).value ?? [];
    final wallet = wallets.firstWhere((w) => w.id == t.walletId, orElse: () => WalletModel(id: '', userId: '', name: 'Wallet?', type: '', balance: 0, createdAt: DateTime.now()));

    IconData icon = Icons.help_outline;
    Color color = Colors.grey;
    String label = 'Unknown';
    String subLabel = '';

    if (t.categoryItemId != null) {
      final item = catState.expenseItems.firstWhere(
        (i) => i.id == t.categoryItemId,
        orElse: () => catState.incomeItems.firstWhere(
          (i) => i.id == t.categoryItemId,
          orElse: () => CategoryItemModel(id: '', categoryId: '', name: '', icon: Icons.help_outline),
        ),
      );
      if (item.id.isNotEmpty) {
        icon = item.icon;
        label = item.name;
        final parent = catState.allParents.firstWhere((p) => p.id == item.categoryId, orElse: () => catState.allParents.first);
        color = parent.color;
        subLabel = parent.name;
      }
    } else {
      if (catState.allParents.isNotEmpty) {
        final parent = catState.allParents.firstWhere((p) => p.id == t.categoryId, orElse: () => catState.allParents.first);
        icon = parent.icon;
        label = parent.name;
        color = parent.color;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => TransactionDetailScreen(transaction: t))),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            Text(
              wallet.name,
              style: TextStyle(fontSize: 10, color: AppColors.primary.withOpacity(0.6), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Text(
          t.note?.isNotEmpty == true ? t.note! : (subLabel.isNotEmpty ? subLabel : 'Tanpa catatan'),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          '${t.type == 'expense' ? '-' : '+'}${_formatCurrency(t.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: t.type == 'expense' ? AppColors.expense : AppColors.income,
          ),
        ),
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, TransferModel t) {
    final wallets = ref.watch(walletProvider).value ?? [];
    final from = wallets.firstWhere((w) => w.id == t.fromWalletId, orElse: () => WalletModel(id: '', userId: '', name: '?', type: '', balance: 0, createdAt: DateTime.now()));
    final to = wallets.firstWhere((w) => w.id == t.toWalletId, orElse: () => WalletModel(id: '', userId: '', name: '?', type: '', balance: 0, createdAt: DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => TransactionDetailScreen(transfer: t))),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.swap_horiz_rounded, color: Colors.blue, size: 24),
        ),
        title: const Text('Transfer Saldo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '${from.name} → ${to.name}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          _formatCurrency(t.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Center(child: Text('😄', style: TextStyle(fontSize: 38))),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada catatan dalam periode ini!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── CALENDAR VIEW ──────────────────────────────────────────────────────────
  Widget _buildCalendarView(BuildContext context, TransactionState transState) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;
    final offset = (firstWeekday % 7);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Month nav
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => _showMonthYearPicker(context),
                      child: Text(_monthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    ),
                    IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                // Day headers
                Row(
                  children: ['Min','Sen','Sel','Rab','Kam','Jum','Sab'].map((d) => Expanded(
                    child: Center(child: Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                // Day grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                  itemCount: offset + daysInMonth,
                  itemBuilder: (ctx, index) {
                    if (index < offset) return const SizedBox.shrink();
                    final day = index - offset + 1;
                    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                    final dayTrans = transState.transactions.where((t) =>
                      t.date.year == date.year && t.date.month == date.month && t.date.day == date.day).toList();
                    final hasExpense = dayTrans.any((t) => t.type == 'expense');
                    final hasIncome = dayTrans.any((t) => t.type == 'income');
                    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
                    final isSelected = _selectedDay != null && date.year == _selectedDay!.year && date.month == _selectedDay!.month && date.day == _selectedDay!.day;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDay = null;
                          } else {
                            _selectedDay = date;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : (isToday ? AppColors.primary : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 1) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.white : AppColors.textPrimary)),
                            if (hasIncome || hasExpense) Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasIncome) Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 2), decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle)),
                                if (hasExpense) Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.expense, shape: BoxShape.circle)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Summary for the month
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCalendarSummary(transState),
          ),
          const SizedBox(height: 24),
          // Full transaction list
          _buildTransactionList(context, transState, shrinkWrap: true, physics: const NeverScrollableScrollPhysics()),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCalendarSummary(TransactionState transState) {
    double income = 0, expense = 0;
    for (var t in transState.transactions) {
      if (t.type == 'income') income += t.amount;
      else if (t.type == 'expense') expense += t.amount;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Pemasukan', amount: _formatCurrency(income), color: AppColors.income),
          Container(height: 32, width: 1, color: Colors.black12),
          _SummaryItem(label: 'Net', amount: _formatCurrency(income - expense), color: AppColors.primary),
          Container(height: 32, width: 1, color: Colors.black12),
          _SummaryItem(label: 'Pengeluaran', amount: _formatCurrency(expense), color: AppColors.expense),
        ],
      ),
    );
  }

  // ─── DIALOGS ────────────────────────────────────────────────────────────────
  void _showAddBookDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buat Buku Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Nama Buku (Pribadi, Usaha...)',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(bookProvider.notifier).addBook(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ─── BOOK PILL ───────────────────────────────────────────────────────────────
class _BookPill extends StatelessWidget {
  final String label;
  final bool isActive;
  const _BookPill({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.white : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.primary : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── TOGGLE BUTTON ───────────────────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isRight;

  const _ToggleBtn({required this.label, required this.isActive, required this.onTap, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── SUMMARY ITEM ────────────────────────────────────────────────────────────
class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  const _SummaryItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
