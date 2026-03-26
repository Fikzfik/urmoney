import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final bool hasFetched;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasFetched = false,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    bool? hasFetched,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
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
      
      var query = supabase
          .from('transactions')
          .select()
          .eq('book_id', bookId);

      if (month != null) {
        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
        query = query
            .gte('date', startOfMonth.toIso8601String())
            .lte('date', endOfMonth.toIso8601String());
      }

      final List<dynamic> data = await query.order('date', ascending: false);
      final transactions = data.map((json) => TransactionModel.fromJson(json)).toList();
      state = state.copyWith(transactions: transactions, isLoading: false, hasFetched: true);
    } catch (e) {
      print('Error fetching transactions: $e');
      state = state.copyWith(isLoading: false, hasFetched: true);
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
      // Refresh wallet balances (DB trigger auto-recalculates them)
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
}

final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(() {
  return TransactionNotifier();
});
