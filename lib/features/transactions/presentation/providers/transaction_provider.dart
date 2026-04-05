import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/category_model.dart';
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
  Timer? _midnightTimer;

  @override
  TransactionState build() {
    // Schedule a check for the next midnight and run once on start
    Future.microtask(() {
      checkAndApplyInterest();
      _startMidnightTimer();
    });
    ref.onDispose(() => _midnightTimer?.cancel());
    
    return TransactionState();
  }

  void _startMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    // Calculate next midnight
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);
    
    print('[Interest] Scheduling next midnight check in ${duration.inHours}h ${duration.inMinutes % 60}m');
    
    _midnightTimer = Timer(duration, () async {
      print('[Interest] Midnight check running...');
      await checkAndApplyInterest();
      _startMidnightTimer(); // Repeat for next day
    });
  }

  Future<void> fetchTransactions(String bookId, {DateTime? month, DateTime? startDate, DateTime? endDate}) async {
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
      } else if (startDate != null && endDate != null) {
        transQuery = transQuery
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
            
        transferQuery = transferQuery
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
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
    // Wait for wallets to be loaded
    final walletsAsync = ref.read(walletProvider);
    if (walletsAsync.value == null) {
      if (walletsAsync.isLoading) {
        print('[Interest] Wallets loading, waiting...');
        await Future.delayed(const Duration(seconds: 2));
        return checkAndApplyInterest(); // Retry once
      }
      print('[Interest] Wallets not loaded yet');
      return;
    }

    final supabase = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    for (var wallet in walletsAsync.value!) {
      if ((wallet.interestRate ?? 0) <= 0 || wallet.payoutSchedule == null) {
        continue;
      }

      print('[Interest] Checking wallet: ${wallet.name} (Balance: ${wallet.balance}, Rate: ${wallet.interestRate}%)');

      final lastPayout = wallet.lastInterestPayout ?? wallet.createdAt;
      final now = DateTime.now();
      
      List<DateTime> payoutDates = [];
      
      if (wallet.payoutSchedule == 'harian') {
        // Start from the day of lastPayout (or createdAt)
        var next = DateTime(lastPayout.year, lastPayout.month, lastPayout.day);
        
        // If we already had a payout, starts from the next day
        if (wallet.lastInterestPayout != null) {
          next = next.add(const Duration(days: 1));
        }

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
        print('[Interest] Found ${payoutDates.length} due payouts for ${wallet.name}');
        
        final catState = ref.read(categoryProvider);
        if (catState.incomeParents.isEmpty) {
          if (catState.isLoading) {
            print('[Interest] Categories still loading, waiting...');
            await Future.delayed(const Duration(seconds: 2));
            // Just return, the next refresh or manual call will handle it
            // or we could retry, but let's avoid infinite loops.
            return;
          }
          print('[Interest] No income categories found yet, skipping');
          return;
        }

        // Find or create "Bunga" category
        final bungaCat = catState.incomeParents.firstWhere(
          (c) => c.name.toLowerCase().contains('bunga'), 
          orElse: () => catState.incomeParents.first
        );

        for (var date in payoutDates) {
          double interest;
          if (wallet.payoutSchedule == 'harian') {
            interest = (wallet.balance * (wallet.interestRate! / 100)) / 365;
          } else {
            interest = (wallet.balance * (wallet.interestRate! / 100)) / 12;
          }
          
          interest = interest.roundToDouble();
          print('[Interest] Calculated: Rp $interest for date ${DateFormat('d/M/y').format(date)}');

          if (interest < 1) {
            print('[Interest] Amount too small, skipping');
            continue;
          }

          final trans = TransactionModel(
            id: '', // Supabase will generate
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
          
          try {
            await supabase.from('transactions').insert(trans.toJson());
          } catch (e) {
            print('[Interest] Error inserting transaction: $e');
          }
        }

        // Update last_interest_payout
        try {
          await supabase.from('wallets').update({
            'last_interest_payout': payoutDates.last.toIso8601String(),
          }).eq('id', wallet.id);
          
          print('[Interest] Updated last_payout to ${payoutDates.last}');
          
          // Refresh to see new transactions and updated balance
          final activeBook = ref.read(bookProvider).activeBook;
          if (activeBook != null) {
            await fetchTransactions(activeBook.id);
          }
          await ref.read(walletProvider.notifier).refreshWallets();
        } catch (e) {
          print('[Interest] Error updating wallet: $e');
        }
      } else {
        print('[Interest] No payouts due for ${wallet.name} (Last: ${DateFormat('d/M/y').format(lastPayout)})');
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
      
      // 1. Insert Transfer
      final response = await supabase.from('transfer_transactions').insert(transfer.toJson()).select().single();
      final savedTransfer = TransferModel.fromJson(response);
      
      // 2. If there is a fee, create a corresponding expense
      if (savedTransfer.fee > 0) {
        await _syncFeeExpense(savedTransfer);
      }
      
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
      
      // 1. Update Transfer
      await supabase.from('transfer_transactions').update(transfer.toJson()).eq('id', transfer.id);
      
      // 2. Sync Fee Expense
      await _syncFeeExpense(transfer);
      
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
      
      // 1. Delete linked expense first
      await supabase.from('transactions').delete().ilike('note', '%[FEE] Transfer: $id%');
      
      // 2. Delete Transfer
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

  Future<void> _syncFeeExpense(TransferModel transfer) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final feeTag = '[FEE] Transfer: ${transfer.id}';
      
      // Search for existing fee
      final existing = await supabase.from('transactions')
          .select()
          .eq('book_id', transfer.bookId)
          .ilike('note', '%$feeTag%');
      
      if (transfer.fee > 0) {
        final catState = ref.read(categoryProvider);
        final feeCat = catState.expenseParents.firstWhere(
          (c) => c.name.toLowerCase().contains('biaya') || c.name.toLowerCase().contains('admin'),
          orElse: () => catState.expenseParents.isNotEmpty ? catState.expenseParents.first : CategoryModel(id: 'other', userId: '', name: 'Lainnya', type: 'expense', icon: Icons.more_horiz, isDefault: true),
        );

        final feeTrans = TransactionModel(
          id: existing.isNotEmpty ? existing[0]['id'] : '',
          userId: transfer.userId,
          bookId: transfer.bookId,
          walletId: transfer.fromWalletId,
          categoryId: feeCat.id,
          amount: transfer.fee,
          type: 'expense',
          note: '$feeTag | ${transfer.note ?? "Tanpa Catatan"}',
          date: transfer.date,
          createdAt: DateTime.now(),
        );

        if (existing.isNotEmpty) {
          await supabase.from('transactions').update(feeTrans.toJson()).eq('id', feeTrans.id);
        } else {
          await supabase.from('transactions').insert(feeTrans.toJson());
        }
      } else if (existing.isNotEmpty) {
        // Fee was removed
        await supabase.from('transactions').delete().eq('id', existing[0]['id']);
      }
    } catch (e) {
      print('Error syncing fee expense: $e');
    }
  }
}

final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(() {
  return TransactionNotifier();
});
