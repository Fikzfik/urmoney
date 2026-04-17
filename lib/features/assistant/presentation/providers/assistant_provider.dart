import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/core/services/ai_service.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/transaction_model.dart';
import 'package:urmoney/features/transactions/data/models/transfer_model.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:urmoney/features/wallets/presentation/providers/wallet_provider.dart';

class AssistantState {
  final List<Map<String, String>> messages;
  final bool isThinking;

  AssistantState({
    this.messages = const [],
    this.isThinking = false,
  });

  AssistantState copyWith({
    List<Map<String, String>>? messages,
    bool? isThinking,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

class AssistantNotifier extends Notifier<AssistantState> {
  @override
  AssistantState build() {
    return AssistantState(
      messages: [
        {'role': 'assistant', 'text': 'Halo! Saya asisten Urmoney. Ada yang bisa saya bantu?'}
      ],
    );
  }

  void addMessage(String text, bool isUser) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        {'role': isUser ? 'user' : 'assistant', 'text': text}
      ],
    );
  }

  Future<void> processVoice(String text) async {
    addMessage(text, true);
    state = state.copyWith(isThinking: true);

    try {
      final ai = ref.read(aiServiceProvider);
      final wallets = ref.read(walletProvider).value ?? [];
      final categories = ref.read(categoryProvider).allParents;

      final result = await ai.processCommand(
        text,
        walletNames: wallets.map((w) => w.name).toList(),
        categoryNames: categories.map((c) => c.name).toList(),
      );

      if (result == null || result['action'] == 'unknown') {
        addMessage(result?['reply'] ?? "Maaf, saya tidak mengerti. Bisa diulangi?", false);
      } else {
        await _executeAction(result);
        addMessage(result['reply'], false);
      }
    } catch (e) {
      addMessage("Waduh, ada kendala teknis nih. Coba lagi ya!", false);
    } finally {
      state = state.copyWith(isThinking: false);
    }
  }

  Future<void> _executeAction(Map<String, dynamic> result) async {
    final action = result['action'];
    final data = result['data'];
    final user = ref.read(currentUserProvider);
    final book = ref.read(bookProvider).activeBook;

    if (user == null || book == null) return;

    if (action == 'add_transaction') {
      // 1. Resolve Wallet
      final walletName = data['walletName'] as String;
      final wallets = ref.read(walletProvider).value ?? [];
      final wallet = wallets.firstWhere(
        (w) => w.name.toLowerCase().contains(walletName.toLowerCase()),
        orElse: () => wallets.first,
      );

      // 2. Resolve/Create Category with Icon
      final catName = data['categoryName'] as String;
      final type = data['type'] ?? 'expense';
      final iconPath = data['iconPath'] as String?;
      
      final catId = await ref.read(categoryProvider.notifier).findOrCreateCategory(
        catName, 
        type: type,
        iconPath: iconPath,
      );

      // 3. Create Transaction
      final trans = TransactionModel(
        id: '',
        userId: user.id,
        bookId: book.id,
        walletId: wallet.id,
        categoryId: catId,
        amount: (data['amount'] as num).toDouble(),
        type: type,
        note: '[AI] ${data['note']}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(transactionProvider.notifier).addTransaction(trans);
      
    } else if (action == 'transfer') {
      final fromName = data['fromWallet'] as String;
      final toName = data['toWallet'] as String;
      final wallets = ref.read(walletProvider).value ?? [];
      
      final from = wallets.firstWhere((w) => w.name.toLowerCase().contains(fromName.toLowerCase()));
      final to = wallets.firstWhere((w) => w.name.toLowerCase().contains(toName.toLowerCase()));

      final transfer = TransferModel(
        id: '',
        userId: user.id,
        bookId: book.id,
        fromWalletId: from.id,
        toWalletId: to.id,
        amount: (data['amount'] as num).toDouble(),
        fee: 0,
        note: '[AI] ${data['note']}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(transactionProvider.notifier).addTransfer(transfer);
    }
  }
}

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(() {
  return AssistantNotifier();
});
