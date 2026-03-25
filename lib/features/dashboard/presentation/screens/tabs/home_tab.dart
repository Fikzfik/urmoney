import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/category_item_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _viewType = 'detail'; // 'detail' or 'calendar'

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _refreshData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _refreshData();
  }

  String get _monthLabel {
    return DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshData());
  }

  void _refreshData() {
    final activeBook = ref.read(bookProvider).activeBook;
    if (activeBook != null) {
      print('HomeTab: Fetching transactions for book ${activeBook.name}');
      ref.read(transactionProvider.notifier).fetchTransactions(activeBook.id, month: _selectedMonth);
    }
  }

  Future<void> _manualRefresh() async {
    print('HomeTab: Manual Refresh All Data...');
    await ref.read(bookProvider.notifier).fetchBooks();
    _refreshData();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookProvider);
    final activeBook = bookState.activeBook;
    final transState = ref.watch(transactionProvider);

    // Listen for book ID changes to refresh transactions
    ref.listen(bookProvider.select((s) => s.activeBook?.id), (prev, next) {
      if (next != null && next != prev) {
        print('HomeTab: Book changed ($prev -> $next). Refreshing data...');
        _refreshData();
      }
    });

    // Fallback refresh: if we have an active book but haven't fetched yet and not loading, fetch them
    // This handles the initial load where initState might run too early (before activeBook is set)
    if (activeBook != null && !transState.hasFetched && !transState.isLoading) {
      Future.microtask(() => _refreshData());
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ─── App Bar (gradient purple header) ───────────────────────────────
          _buildHeader(context, ref, bookState, activeBook),

          // ─── White body ─────────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: RefreshIndicator(
                onRefresh: _manualRefresh,
                child: Column(
                  children: [
                    // Summary Card (optional: only in detail view or everywhere?)
                    if (_viewType == 'detail') _buildSummaryCard(context, transState.transactions),
                    // Transaction list or Calendar
                    Expanded(
                      child: _viewType == 'detail'
                          ? _buildTransactionList(context, transState)
                          : _buildCalendarView(context, transState),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref, BookState bookState, dynamic activeBook) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Row: search + book + detail + calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Text(
                      activeBook?.name ?? 'Pilih Buku',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        _ToggleBtn(
                          label: 'Detail',
                          isActive: _viewType == 'detail',
                          onTap: () => setState(() => _viewType = 'detail'),
                        ),
                        _ToggleBtn(
                          label: 'Kalender',
                          isActive: _viewType == 'calendar',
                          onTap: () => setState(() => _viewType = 'calendar'),
                          isRight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Book carousel
            SizedBox(
              height: 100,
              child: bookState.books.isEmpty
                  ? Center(
                      child: GestureDetector(
                        onTap: () => _showAddBookDialog(context, ref),
                        child: _BookCard(label: 'Buku Baru', isAdd: true, isActive: false),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: bookState.books.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == bookState.books.length) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _showAddBookDialog(context, ref),
                              child: _BookCard(label: 'Baru B...', isAdd: true, isActive: false),
                            ),
                          );
                        }
                        final b = bookState.books[i];
                        final isActive = activeBook?.id == b.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => ref.read(bookProvider.notifier).setActiveBook(b),
                            child: _BookCard(label: b.name, isAdd: false, isActive: isActive),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── SUMMARY CARD ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard(BuildContext context, List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == 'income') income += t.amount;
      else if (t.type == 'expense') expense += t.amount;
    }
    double total = income - expense;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _prevMonth();
                  _refreshData();
                },
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  // Month picker Dialog placeholder
                },
                child: Row(
                  children: [
                    Text(
                      _monthLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _nextMonth();
                  _refreshData();
                },
                icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              // Extra icons
              _SummaryIconBtn(icon: Icons.mail_outline_rounded, onTap: () {}),
              const SizedBox(width: 8),
              _SummaryIconBtn(icon: Icons.settings_outlined, onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          // Total / Income / Expense row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryAmount(label: 'Total', amount: _formatCurrency(total), icon: Icons.compare_arrows_rounded, color: AppColors.primary),
              Container(height: 40, width: 1, color: Colors.black12),
              _SummaryAmount(label: 'Penghasilan', amount: _formatCurrency(income), icon: Icons.add_circle_outline, color: Colors.green),
              Container(height: 40, width: 1, color: Colors.black12),
              _SummaryAmount(label: 'Pengeluaran', amount: _formatCurrency(expense), icon: Icons.remove_circle_outline, color: Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TRANSACTION LIST / EMPTY STATE ───────────────────────────────────────
  Widget _buildTransactionList(BuildContext context, TransactionState transState, {bool shrinkWrap = false, ScrollPhysics? physics}) {
    if (transState.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    final transactions = transState.transactions;
    if (transactions.isEmpty) {
      return _buildEmptyTransactions();
    }

    // Group transactions by date
    final grouped = <DateTime, List<TransactionModel>>{};
    for (var t in transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(date, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sortedDates.length,
      itemBuilder: (context, i) {
        final date = sortedDates[i];
        final dayTrans = grouped[date]!;
        final dayLabel = DateFormat('EEE, d/M', 'id_ID').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 12),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(dayLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            ...dayTrans.map((t) => _buildTransactionCard(context, t)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    final catState = ref.watch(categoryProvider);
    
    // Find category item icon
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
        // Find parent for color
        final parent = catState.allParents.firstWhere((p) => p.id == item.categoryId, orElse: () => catState.allParents.first);
        color = parent.color;
        subLabel = parent.name;
      }
    } else {
      // Fallback to category
      final parent = catState.allParents.firstWhere((p) => p.id == t.categoryId, orElse: () => catState.allParents.first);
      icon = parent.icon;
      label = parent.name;
      color = parent.color;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _showEditTransactionDialog(context, ref, t),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(t.note?.isNotEmpty == true ? t.note! : (subLabel.isNotEmpty ? subLabel : 'Tanpa catatan'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${t.type == 'expense' ? '-' : '+'}${_formatCurrency(t.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: t.type == 'expense' ? Colors.redAccent : Colors.green,
              ),
            ),
            const Text('akun bawaan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  void _showEditTransactionDialog(BuildContext context, WidgetRef ref, TransactionModel t) {
    final noteCtrl = TextEditingController(text: t.note);
    final amountCtrl = TextEditingController(text: t.amount.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                _confirmDeleteTransaction(context, ref, t.id);
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Jumlah (Rp)',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixText: 'Rp ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: 'Catatan',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountCtrl.text) ?? t.amount;
              final edited = TransactionModel(
                id: t.id,
                userId: t.userId,
                bookId: t.bookId,
                walletId: t.walletId,
                categoryId: t.categoryId,
                categoryItemId: t.categoryItemId,
                amount: newAmount,
                type: t.type,
                note: noteCtrl.text.trim(),
                date: t.date,
                createdAt: t.createdAt,
              );
              ref.read(transactionProvider.notifier).updateTransaction(edited);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(transactionProvider.notifier).deleteTransaction(id);
              Navigator.pop(ctx); // pop confirm
              Navigator.pop(context); // pop edit dialog
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

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
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                    Text(_monthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Month', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DayName(label: 'Min', color: Colors.redAccent),
                    _DayName(label: 'Sen'),
                    _DayName(label: 'Sel'),
                    _DayName(label: 'Rab'),
                    _DayName(label: 'Kam'),
                    _DayName(label: 'Jum'),
                    _DayName(label: 'Sab', color: Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: 42,
                  itemBuilder: (ctx, i) {
                    final dayNum = i - offset + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
                    final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNum);
                    final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
                    final dayTrans = transState.transactions.where((t) => t.date.day == date.day && t.date.month == date.month && t.date.year == date.year).toList();
                    final count = dayTrans.length;
                    return Container(
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text('$dayNum', style: TextStyle(color: (i % 7 == 0 || i % 7 == 6) ? Colors.redAccent : AppColors.textPrimary, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                          if (count > 0)
                            Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8)))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Day Info under calendar
          _buildDaySummary(context, transState.transactions),
          // Transactions for the whole month grouped
          _buildTransactionList(context, transState, shrinkWrap: true, physics: const NeverScrollableScrollPhysics()),
        ],
      ),
    );
  }

  Widget _buildDaySummary(BuildContext context, List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == 'income') income += t.amount;
      else if (t.type == 'expense') expense += t.amount;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryItem(label: 'Total', amount: _formatCurrency(income - expense), color: Colors.redAccent),
          _SummaryItem(label: 'Penghasilan', amount: _formatCurrency(income), color: Colors.green),
          _SummaryItem(label: 'Pengeluaran', amount: _formatCurrency(expense), color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ─── BOOK CARD ───────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final String label;
  final bool isAdd;
  final bool isActive;

  const _BookCard({required this.label, required this.isAdd, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primaryDark : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: isAdd
                ? const Icon(Icons.add_rounded, color: Colors.white, size: 28)
                : const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label.length > 6 ? '${label.substring(0, 6)}...' : label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── SUMMARY AMOUNT ──────────────────────────────────────────────────────────
class _SummaryAmount extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _SummaryAmount({required this.label, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

// ─── SUMMARY ICON BTN ────────────────────────────────────────────────────────
class _SummaryIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isRight;

  const _ToggleBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isRight = false,
  });

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

class _DayName extends StatelessWidget {
  final String label;
  final Color? color;
  const _DayName({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color ?? AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  const _SummaryItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
