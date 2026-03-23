import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/data/models/book_model.dart';

class BookState {
  final bool isLoading;
  final List<BookModel> books;
  final BookModel? activeBook;
  final String? error;

  BookState({
    this.isLoading = false,
    this.books = const [],
    this.activeBook,
    this.error,
  });

  BookState copyWith({
    bool? isLoading,
    List<BookModel>? books,
    BookModel? activeBook,
    String? error,
  }) {
    return BookState(
      isLoading: isLoading ?? this.isLoading,
      books: books ?? this.books,
      activeBook: activeBook ?? this.activeBook,
      error: error ?? this.error,
    );
  }
}

class BookNotifier extends Notifier<BookState> {
  @override
  BookState build() {
    // Listen to current user changes
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        fetchBooks();
      } else if (next == null) {
        state = BookState(); // clear state on logout
      }
    }, fireImmediately: true);
    
    return BookState();
  }

  Future<void> fetchBooks() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client
          .from('books')
          .select()
          .eq('user_id', user.id)
          .order('created_at');

      final books = (response as List).map((json) => BookModel.fromJson(json)).toList();
      BookModel? active = books.isNotEmpty ? books.first : null;

      // Maintain active book if it still exists
      if (state.activeBook != null && books.any((b) => b.id == state.activeBook!.id)) {
        active = books.firstWhere((b) => b.id == state.activeBook!.id);
      }

      state = state.copyWith(isLoading: false, books: books, activeBook: active);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addBook(String name, {String? icon}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final newBookRes = await client.from('books').insert({
        'user_id': user.id,
        'name': name,
        'icon': icon,
      }).select().single();

      final newBook = BookModel.fromJson(newBookRes);
      
      final updatedBooks = [...state.books, newBook];
      state = state.copyWith(
        books: updatedBooks,
        activeBook: state.activeBook ?? newBook,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setActiveBook(BookModel book) {
    state = state.copyWith(activeBook: book);
  }
}

final bookProvider = NotifierProvider<BookNotifier, BookState>(() {
  return BookNotifier();
});
