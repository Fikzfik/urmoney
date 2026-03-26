import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:intl/intl.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final List<TransferModel> transfers;
  final bool isLoading;
  final bool hasFetched;

  TransactionState({
    this.transactions = const [],
    this.transfers = const [],
    this.isLoading = false,
    this.hasFetched = false,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    List<TransferModel>? transfers,
    bool? isLoading,
    bool? hasFetched,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
    );
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  @override
  TransactionState build() {
    return TransactionState();
  }

  Future<void> fetchTransactions(String bookId, {DateTime? month}) async {
    state = state.copyWith(isLoading: true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // 1. Fetch Transactions
      var transQuery = supabase.from('transactions').select().eq('book_id', bookId);

      // 2. Fetch Transfers
      var transferQuery = supabase.from('transfer_transactions').select().eq('book_id', bookId);

      if (month != null) {
        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
        
        transQuery = transQuery
            .gte('date', startOfMonth.toIso8601String())
            .lte('date', endOfMonth.toIso8601String());
            
        transferQuery = transferQuery
            .gte('date', startOfMonth.toIso8601String())
            .lte('date', endOfMonth.toIso8601String());
      }

      final responses = await Future.wait([
        transQuery.order('date', ascending: false),
        transferQuery.order('date', ascending: false),
      ]);

      final transactions = (responses[0] as List).map((json) => TransactionModel.fromJson(json)).toList();
      final transfers = (responses[1] as List).map((json) => TransferModel.fromJson(json)).toList();

      state = state.copyWith(
        transactions: transactions,
        transfers: transfers,
        isLoading: false,
        hasFetched: true,
      );
    } catch (e) {
      print('Error fetching transactions: $e');
      state = state.copyWith(isLoading: false, hasFetched: true);
    }
  }

  Future<void> checkAndApplyInterest() async {
    final walletsAsync = ref.read(walletProvider);
    if (walletsAsync.value == null) return;

    final supabase = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    for (var wallet in walletsAsync.value!) {
      if ((wallet.interestRate ?? 0) <= 0 || wallet.payoutSchedule == null) continue;

      final lastPayout = wallet.lastInterestPayout ?? wallet.createdAt;
      final now = DateTime.now();
      
      List<DateTime> payoutDates = [];
      
      if (wallet.payoutSchedule == 'harian') {
        var next = DateTime(lastPayout.year, lastPayout.month, lastPayout.day).add(const Duration(days: 1));
        while (next.isBefore(now) || (next.year == now.year && next.month == now.month && next.day == now.day)) {
          payoutDates.add(next);
          next = next.add(const Duration(days: 1));
        }
      } else if (wallet.payoutSchedule == 'bulanan') {
        final payoutDay = wallet.payoutDay ?? 1;
        var next = DateTime(lastPayout.year, lastPayout.month, payoutDay);
        if (next.isBefore(lastPayout) || (next.year == lastPayout.year && next.month == lastPayout.month && next.day == lastPayout.day)) {
          next = DateTime(next.year, next.month + 1, payoutDay);
        }
        while (next.isBefore(now)) {
          payoutDates.add(next);
          next = DateTime(next.year, next.month + 1, payoutDay);
        }
      }

      if (payoutDates.isNotEmpty) {
        print('Applying ${payoutDates.length} interest payouts for wallet ${wallet.name}');
        
        // Find or create "Bunga" category
        final catState = ref.read(categoryProvider);
        var bungaCat = catState.incomeParents.firstWhere((c) => c.name.toLowerCase().contains('bunga'), 
            orElse: () => catState.incomeParents.first);

        for (var date in payoutDates) {
          // Interest calculation: (Rate / 100) / (365 or 12) * current balance
          // Note: SEAbank uses daily calculation based on balance.
          double interest;
          if (wallet.payoutSchedule == 'harian') {
            interest = (wallet.balance * (wallet.interestRate! / 100)) / 365;
          } else {
            interest = (wallet.balance * (wallet.interestRate! / 100)) / 12;
          }
          
          // Round to 2 decimals or 0 for RP
          interest = interest.roundToDouble();

          if (interest < 1) continue; // Skip if too small

          final trans = TransactionModel(
            id: '',
            userId: user.id,
            bookId: wallet.bookId ?? '',
            walletId: wallet.id,
            categoryId: bungaCat.id,
            amount: interest,
            type: 'income',
            note: 'Bunga ${wallet.payoutSchedule} - ${DateFormat('d/M/y').format(date)}',
            date: date,
            createdAt: DateTime.now(),
          );
          
          await supabase.from('transactions').insert(trans.toJson());
        }

        // Update last_interest_payout
        await supabase.from('wallets').update({
          'last_interest_payout': payoutDates.last.toIso8601String(),
        }).eq('id', wallet.id);

        // Refresh to see new transactions and updated balance
        final activeBook = ref.read(bookProvider).activeBook;
        if (activeBook != null) {
          await fetchTransactions(activeBook.id);
        }
        await ref.read(walletProvider.notifier).refreshWallets();
      }
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('transactions').insert(transaction.toJson());
      
      final activeBook = ref.read(bookProvider).activeBook;
      if (activeBook != null) {
        await fetchTransactions(activeBook.id);
      }
      await ref.read(walletProvider.notifier).refreshWallets();
    } catch (e) {
      print('Error adding transaction: $e');
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('transactions').update(transaction.toJson()).eq('id', transaction.id);
      
      final activeBook = ref.read(bookProvider).activeBook;
      if (activeBook != null) {
        await fetchTransactions(activeBook.id);
      }
      await ref.read(walletProvider.notifier).refreshWallets();
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('transactions').delete().eq('id', id);
      
      final activeBook = ref.read(bookProvider).activeBook;
      if (activeBook != null) {
        await fetchTransactions(activeBook.id);
      }
      await ref.read(walletProvider.notifier).refreshWallets();
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  Future<void> addTransfer(TransferModel transfer) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('transfer_transactions').insert(transfer.toJson());
      
      final activeBook = ref.read(bookProvider).activeBook;
      if (activeBook != null) {
        await fetchTransactions(activeBook.id);
      }
      await ref.read(walletProvider.notifier).refreshWallets();
    } catch (e) {
      print('Error adding transfer: $e');
    }
  }

  Future<void> updateTransfer(TransferModel transfer) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('transfer_transactions').update(transfer.toJson()).eq('id', transfer.id);
      
      final activeBook = ref.read(bookProvider).activeBook;
      if (activeBook != null) {
        await fetchTransactions(activeBook.id);
      }
      await ref.read(walletProvider.notifier).refreshWallets();
    } catch (e) {
      print('Error updating transfer: $e');
    }
  }

  Future<void> deleteTransfer(String id) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('transfer_transactions').delete().eq('id', id);
      
      final activeBook = ref.read(bookProvider).activeBook;
      if (activeBook != null) {
        await fetchTransactions(activeBook.id);
      }
      await ref.read(walletProvider.notifier).refreshWallets();
    } catch (e) {
      print('Error deleting transfer: $e');
    }
  }
}

final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(() {
  return TransactionNotifier();
});
