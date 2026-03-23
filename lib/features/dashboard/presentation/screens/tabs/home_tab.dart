import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/category_model.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
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

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  String get _monthLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
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
                    // Summary Card
                    _buildSummaryCard(context, transState.transactions),
                    // Transaction list or empty state
                    Expanded(child: _buildTransactionList(context, transState)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: bookState.books.isEmpty
                        ? GestureDetector(
                            onTap: () => _showAddBookDialog(context, ref),
                            child: const Text(
                              'Buat Buku Baru +',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: activeBook?.id,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              dropdownColor: const Color(0xFF5A4DFF),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              items: bookState.books.map((b) {
                                return DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.name, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final book = bookState.books.firstWhere((b) => b.id == val);
                                  ref.read(bookProvider.notifier).setActiveBook(book);
                                }
                              },
                            ),
                          ),
                  ),
                  // Detail button
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 18),
                    label: const Text('Detail', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
  Widget _buildTransactionList(BuildContext context, TransactionState transState) {
    if (transState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final transactions = transState.transactions;
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final catState = ref.watch(categoryProvider);
        final category = catState.allParents.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => CategoryModel(
            id: '',
            userId: '',
            name: 'Unknown',
            type: 'expense',
            icon: Icons.help_outline,
            color: Colors.grey,
          ),
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.1),
              child: Icon(category.icon, color: category.color),
            ),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(t.note ?? 'Tanpa catatan', style: const TextStyle(fontSize: 12)),
            trailing: Text(
              '${t.type == 'expense' ? '-' : '+'}${_formatCurrency(t.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: t.type == 'expense' ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
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
