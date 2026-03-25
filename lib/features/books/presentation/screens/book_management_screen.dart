import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';

class BookManagementScreen extends ConsumerWidget {
  const BookManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Books'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
      ),
      body: bookState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookState.books.length,
              itemBuilder: (context, index) {
                final book = bookState.books[index];
                final isActive = book.id == bookState.activeBook?.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        book.icon != null ? IconData(int.parse(book.icon!), fontFamily: 'MaterialIcons') : Icons.book,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      book.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: isActive ? const Text('Active Book', style: TextStyle(color: AppColors.primary, fontSize: 12)) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: () => _showEditBookDialog(context, ref, book),
                        ),
                        if (bookState.books.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, ref, book),
                          ),
                      ],
                    ),
                    onTap: () {
                      ref.read(bookProvider.notifier).setActiveBook(book);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book?'),
        content: Text('Are you sure you want to delete "${book.name}"? All wallets and transactions in this book will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(bookProvider.notifier).deleteBook(book.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditBookDialog(BuildContext context, WidgetRef ref, dynamic book) {
    final ctrl = TextEditingController(text: book.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Book'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter book name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(bookProvider.notifier).updateBook(book.id, ctrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Book'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter book name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(bookProvider.notifier).addBook(ctrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
