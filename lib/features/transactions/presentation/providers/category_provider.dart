import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/providers/supabase_provider.dart';
import 'package:urmoney/features/books/presentation/providers/book_provider.dart';
import 'package:urmoney/features/transactions/data/models/category_model.dart';
import 'package:urmoney/features/transactions/data/models/category_item_model.dart';

class CategoryState {
  final bool isLoading;
  final List<CategoryModel> expenseParents;
  final List<CategoryItemModel> expenseItems;
  final List<CategoryModel> incomeParents;
  final List<CategoryItemModel> incomeItems;
  final String? error;

  CategoryState({
    this.isLoading = false,
    this.expenseParents = const [],
    this.expenseItems = const [],
    this.incomeParents = const [],
    this.incomeItems = const [],
    this.error,
  });

  /// The virtual "Direkomendasikan" parent category for Expense
  CategoryModel get recommendedExpenseParent => CategoryModel(
    id: 'rec_exp',
    userId: '',
    name: 'Direkomendasikan',
    type: 'expense',
    icon: Icons.star_rounded,
    isDefault: true,
  );

  /// The virtual "Direkomendasikan" parent category for Income
  CategoryModel get recommendedIncomeParent => CategoryModel(
    id: 'rec_inc',
    userId: '',
    name: 'Direkomendasikan',
    type: 'income',
    icon: Icons.star_rounded,
    isDefault: true,
  );

  /// Returns all items for a specific parent (or all items for "Direkomendasikan")
  List<CategoryItemModel> itemsFor(String parentId, bool isExpense) {
    final items = isExpense ? expenseItems : incomeItems;
    if (parentId == 'rec_exp' || parentId == 'rec_inc') {
      return items;
    }
    return items.where((item) => item.categoryId == parentId).toList();
  }

  List<CategoryModel> get allParents => [...expenseParents, ...incomeParents];

  CategoryState copyWith({
    bool? isLoading,
    List<CategoryModel>? expenseParents,
    List<CategoryItemModel>? expenseItems,
    List<CategoryModel>? incomeParents,
    List<CategoryItemModel>? incomeItems,
    String? error,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      expenseParents: expenseParents ?? this.expenseParents,
      expenseItems: expenseItems ?? this.expenseItems,
      incomeParents: incomeParents ?? this.incomeParents,
      incomeItems: incomeItems ?? this.incomeItems,
      error: error ?? this.error,
    );
  }
}

class CategoryNotifier extends Notifier<CategoryState> {
  @override
  CategoryState build() {
    final activeBookId = ref.watch(bookProvider.select((s) => s.activeBook?.id));
    
    if (activeBookId == null) {
      return CategoryState();
    }
    
    Future.microtask(() => fetchCategories(activeBookId));
    return CategoryState(isLoading: true);
  }

  Future<void> fetchCategories(String bookId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Fetch parents
      final parentsRes = await client.from('categories').select().eq('book_id', bookId).order('created_at');
      final parents = (parentsRes as List).map((j) => CategoryModel.fromJson(j)).toList();
      
      final expenseParents = parents.where((p) => p.type == 'expense').toList();
      final incomeParents = parents.where((p) => p.type == 'income').toList();
      
      // Fetch items
      final parentIds = parents.map((p) => p.id).toList();
      List<CategoryItemModel> items = [];
      if (parentIds.isNotEmpty) {
        final itemsRes = await client.from('category_items').select().filter('category_id', 'in', parentIds);
        items = (itemsRes as List).map((j) => CategoryItemModel.fromJson(j)).toList();
      }
      
      final expenseItems = items.where((i) => expenseParents.any((p) => p.id == i.categoryId)).toList();
      final incomeItems = items.where((i) => incomeParents.any((p) => p.id == i.categoryId)).toList();
      
      // Seed defaults if empty
      if (expenseParents.isEmpty && incomeParents.isEmpty) {
        await _seedDefaultCategories(bookId);
        return; // seed will re-trigger fetch
      }

      state = CategoryState(
        isLoading: false,
        expenseParents: expenseParents,
        incomeParents: incomeParents,
        expenseItems: expenseItems,
        incomeItems: incomeItems,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _seedDefaultCategories(String bookId) async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final blue = '0xFF448AFF';
    final teal = '0xFF009688';
    
    // 1. Create Parent Categories
    final parents = [
      {'user_id': user.id, 'book_id': bookId, 'name': 'Kebutuhan', 'type': 'expense', 'icon': Icons.home_repair_service.codePoint.toString(), 'is_default': true, 'color': blue},
      {'user_id': user.id, 'book_id': bookId, 'name': 'Makan & Minum', 'type': 'expense', 'icon': Icons.fastfood.codePoint.toString(), 'is_default': true, 'color': blue},
      {'user_id': user.id, 'book_id': bookId, 'name': 'Transportasi', 'type': 'expense', 'icon': Icons.directions_car.codePoint.toString(), 'is_default': true, 'color': blue},
      {'user_id': user.id, 'book_id': bookId, 'name': 'Hiburan', 'type': 'expense', 'icon': Icons.movie.codePoint.toString(), 'is_default': true, 'color': blue},
      {'user_id': user.id, 'book_id': bookId, 'name': 'Transfer', 'type': 'expense', 'icon': Icons.swap_horiz.codePoint.toString(), 'is_default': true, 'color': blue},
      {'user_id': user.id, 'book_id': bookId, 'name': 'Pendapatan', 'type': 'income', 'icon': Icons.monetization_on.codePoint.toString(), 'is_default': true, 'color': teal},
    ];

    print('Seeding default categories...');
    final parentRes = await client.from('categories').insert(parents).select();
    final seededParents = (parentRes as List).map((j) => CategoryModel.fromJson(j)).toList();

    // 2. Create Items for some parents
    final items = [];
    for (var parent in seededParents) {
      if (parent.name == 'Kebutuhan') {
        items.add({'category_id': parent.id, 'name': 'Listrik', 'icon': Icons.electric_bolt.codePoint.toString()});
        items.add({'category_id': parent.id, 'name': 'Air', 'icon': Icons.water_drop.codePoint.toString()});
        items.add({'category_id': parent.id, 'name': 'Internet', 'icon': Icons.wifi.codePoint.toString()});
      } else if (parent.name == 'Makan & Minum') {
        items.add({'category_id': parent.id, 'name': 'Sarapan', 'icon': Icons.coffee.codePoint.toString()});
        items.add({'category_id': parent.id, 'name': 'Makan Siang', 'icon': Icons.lunch_dining.codePoint.toString()});
        items.add({'category_id': parent.id, 'name': 'Makan Malam', 'icon': Icons.restaurant.codePoint.toString()});
      } else if (parent.name == 'Pendapatan') {
        items.add({'category_id': parent.id, 'name': 'Gaji', 'icon': Icons.payments.codePoint.toString()});
        items.add({'category_id': parent.id, 'name': 'Bonus', 'icon': Icons.card_giftcard.codePoint.toString()});
      }
    }

    if (items.isNotEmpty) {
      print('Seeding category items...');
      await client.from('category_items').insert(items);
    }

    await fetchCategories(bookId);
  }

  // ── Parent CRUD ──────────────────────────────────────────────────────────────

  Future<void> addParent(bool isExpense, String label, IconData icon) async {
    final bookId = ref.read(bookProvider).activeBook?.id;
    final user = ref.read(currentUserProvider);
    if (bookId == null || user == null) return;

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('categories').insert({
        'user_id': user.id,
        'book_id': bookId,
        'name': label,
        'type': isExpense ? 'expense' : 'income',
        'icon': icon.codePoint.toString(),
        'color': isExpense ? '0xFF448AFF' : '0xFF009688',
      });
      await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  Future<void> renameParent(String parentId, String newLabel) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('categories').update({'name': newLabel}).eq('id', parentId);
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteParent(String parentId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('categories').delete().eq('id', parentId);
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  // ── Item CRUD ────────────────────────────────────────────────────────────────

  Future<void> addItem(String label, IconData? icon, String parentId, {String? iconPath}) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('category_items').insert({
        'category_id': parentId,
        'name': label,
        'icon': iconPath ?? icon?.codePoint.toString(),
      });
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  Future<void> editItem(String itemId, String newName, int? newIconCode, {String? iconPath}) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('category_items').update({
        'name': newName,
        'icon': iconPath ?? newIconCode?.toString(),
      }).eq('id', itemId);
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print('Error editing item: $e');
    }
  }

  Future<void> renameItem(String itemId, String newLabel) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('category_items').update({'name': newLabel}).eq('id', itemId);
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  Future<void> moveItem(String itemId, String newParentId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('category_items').update({'category_id': newParentId}).eq('id', itemId);
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('category_items').delete().eq('id', itemId);
      final bookId = ref.read(bookProvider).activeBook?.id;
      if (bookId != null) await fetchCategories(bookId);
    } catch (e) {
      print(e);
    }
  }

  // ── AI Auto-create helpers ────────────────────────────────────────────────

  /// Get all category parent names (for AI prompt context)
  List<String> getAllCategoryNames() {
    return [...state.expenseParents, ...state.incomeParents]
        .map((c) => c.name)
        .toList();
  }

  /// Get all category item names (for AI prompt context)
  List<String> getAllItemNames() {
    return [...state.expenseItems, ...state.incomeItems]
        .map((i) => i.name)
        .toList();
  }

  /// Find existing category by fuzzy name match, or create a new one.
  /// Returns the category ID.
  Future<String> findOrCreateCategory(String suggestedName, {String type = 'expense', String? iconPath}) async {
    final parents = type == 'expense' ? state.expenseParents : state.incomeParents;

    // Fuzzy match: lowercase contains
    final match = parents.cast<CategoryModel?>().firstWhere(
      (p) => p!.name.toLowerCase().contains(suggestedName.toLowerCase()) ||
             suggestedName.toLowerCase().contains(p.name.toLowerCase()),
      orElse: () => null,
    );

    if (match != null) return match.id;

    // Not found → create new
    final bookId = ref.read(bookProvider).activeBook?.id;
    final user = ref.read(currentUserProvider);
    if (bookId == null || user == null) {
      return parents.isNotEmpty ? parents.first.id : '';
    }

    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client.from('categories').insert({
        'user_id': user.id,
        'book_id': bookId,
        'name': suggestedName,
        'type': type,
        'icon': iconPath ?? Icons.category_rounded.codePoint.toString(),
        'color': type == 'expense' ? '0xFF448AFF' : '0xFF009688',
      }).select().single();

      final newCat = CategoryModel.fromJson(res);
      
      // Update local state
      if (type == 'expense') {
        state = state.copyWith(expenseParents: [...state.expenseParents, newCat]);
      } else {
        state = state.copyWith(incomeParents: [...state.incomeParents, newCat]);
      }

      return newCat.id;
    } catch (e) {
      print('Error creating category: $e');
      return parents.isNotEmpty ? parents.first.id : '';
    }
  }

  /// Find existing category item by fuzzy name match, or create a new one.
  /// Returns the category item ID.
  Future<String> findOrCreateItem(String categoryId, String suggestedItemName, {String? iconPath}) async {
    final allItems = [...state.expenseItems, ...state.incomeItems];
    
    // Look for existing item in this category
    final itemsInCategory = allItems.where((i) => i.categoryId == categoryId).toList();
    final match = itemsInCategory.cast<CategoryItemModel?>().firstWhere(
      (i) => i!.name.toLowerCase().contains(suggestedItemName.toLowerCase()) ||
             suggestedItemName.toLowerCase().contains(i.name.toLowerCase()),
      orElse: () => null,
    );

    if (match != null) return match.id;

    // Not found → create new
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client.from('category_items').insert({
        'category_id': categoryId,
        'name': suggestedItemName,
        'icon': iconPath ?? Icons.label_rounded.codePoint.toString(),
      }).select().single();

      final newItem = CategoryItemModel.fromJson(res);

      // Update local state
      final isExpense = state.expenseParents.any((p) => p.id == categoryId);
      if (isExpense) {
        state = state.copyWith(expenseItems: [...state.expenseItems, newItem]);
      } else {
        state = state.copyWith(incomeItems: [...state.incomeItems, newItem]);
      }

      return newItem.id;
    } catch (e) {
      print('Error creating category item: $e');
      return '';
    }
  }
}

final categoryProvider = NotifierProvider<CategoryNotifier, CategoryState>(() {
  return CategoryNotifier();
});

