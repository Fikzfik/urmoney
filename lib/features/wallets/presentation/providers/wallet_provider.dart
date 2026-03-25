import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/wallets/data/models/wallet_model.dart';

class WalletNotifier extends Notifier<AsyncValue<List<WalletModel>>> {
  @override
  AsyncValue<List<WalletModel>> build() {
    // Watch active book ID to refetch when it changes
    final activeBookId = ref.watch(bookProvider.select((s) => s.activeBook?.id));
    
    if (activeBookId == null) {
      return const AsyncValue.data([]);
    }

    // Trigger fetch and return loading state
    Future.microtask(() => fetchWallets(activeBookId));
    return const AsyncValue.loading();
  }

  Future<void> fetchWallets(String bookId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client
          .from('wallets')
          .select()
          .eq('book_id', bookId)
          .order('created_at');
          
      final wallets = (response as List).map((json) => WalletModel.fromJson(json)).toList();
      state = AsyncValue.data(wallets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWallet(String name, String type, double balance, {String? icon}) async {
    final bookId = ref.read(bookProvider).activeBook?.id;
    final user = ref.read(currentUserProvider);
    if (bookId == null || user == null) return;
    
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client.from('wallets').insert({
        'user_id': user.id,
        'book_id': bookId,
        'name': name,
        'type': type,
        'balance': balance,
        'icon': icon,
      }).select().single();
      
      final newWallet = WalletModel.fromJson(res);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newWallet]);
      }
    } catch (e) {
      print('Error adding wallet: $e');
    }
  }
}

final walletProvider = NotifierProvider<WalletNotifier, AsyncValue<List<WalletModel>>>(() {
  return WalletNotifier();
});
