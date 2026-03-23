import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A single category item (e.g. "Diet", "Bensin")
class CategoryItem {
  final String id;
  final String label;
  final IconData icon;
  final String parentId; // which parent category this belongs to

  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.parentId,
  });

  CategoryItem copyWith({String? label, IconData? icon, String? parentId}) {
    return CategoryItem(
      id: id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
    );
  }
}

// A parent category (e.g. "Makanan", "Transportasi")
class ParentCategory {
  final String id;
  final String label;
  final IconData icon;
  final bool isRecommended; // Direkomendasikan is special, not deletable
  final bool isSystem; // true means not deletable

  const ParentCategory({
    required this.id,
    required this.label,
    required this.icon,
    this.isRecommended = false,
    this.isSystem = false,
  });

  ParentCategory copyWith({String? label, IconData? icon}) {
    return ParentCategory(
      id: id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      isRecommended: isRecommended,
      isSystem: isSystem,
    );
  }
}

class CategoryState {
  final List<ParentCategory> expenseParents;
  final List<CategoryItem> expenseItems;
  final List<ParentCategory> incomeParents;
  final List<CategoryItem> incomeItems;

  const CategoryState({
    required this.expenseParents,
    required this.expenseItems,
    required this.incomeParents,
    required this.incomeItems,
  });

  /// Returns all items for a specific parent (or all items for "Direkomendasikan")
  List<CategoryItem> itemsFor(String parentId, bool isExpense) {
    final items = isExpense ? expenseItems : incomeItems;
    final parents = isExpense ? expenseParents : incomeParents;
    final parent = parents.firstWhere((p) => p.id == parentId, orElse: () => parents.first);
    if (parent.isRecommended) return items;
    return items.where((item) => item.parentId == parentId).toList();
  }

  CategoryState copyWith({
    List<ParentCategory>? expenseParents,
    List<CategoryItem>? expenseItems,
    List<ParentCategory>? incomeParents,
    List<CategoryItem>? incomeItems,
  }) {
    return CategoryState(
      expenseParents: expenseParents ?? this.expenseParents,
      expenseItems: expenseItems ?? this.expenseItems,
      incomeParents: incomeParents ?? this.incomeParents,
      incomeItems: incomeItems ?? this.incomeItems,
    );
  }
}

class CategoryNotifier extends Notifier<CategoryState> {
  @override
  CategoryState build() => const CategoryState(
    expenseParents: _defaultExpenseParents,
    expenseItems: _defaultExpenseItems,
    incomeParents: _defaultIncomeParents,
    incomeItems: _defaultIncomeItems,
  );

  // ── Parent CRUD ──────────────────────────────────────────────────────────────

  void addParent(bool isExpense, String label, IconData icon) {
    final id = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final cat = ParentCategory(id: id, label: label, icon: icon);
    if (isExpense) {
      state = state.copyWith(expenseParents: [...state.expenseParents, cat]);
    } else {
      state = state.copyWith(incomeParents: [...state.incomeParents, cat]);
    }
  }

  void renameParent(bool isExpense, String parentId, String newLabel) {
    if (isExpense) {
      state = state.copyWith(
        expenseParents: state.expenseParents.map((p) =>
          p.id == parentId ? p.copyWith(label: newLabel) : p).toList(),
      );
    } else {
      state = state.copyWith(
        incomeParents: state.incomeParents.map((p) =>
          p.id == parentId ? p.copyWith(label: newLabel) : p).toList(),
      );
    }
  }

  void deleteParent(bool isExpense, String parentId) {
    if (isExpense) {
      state = state.copyWith(
        expenseParents: state.expenseParents.where((p) => p.id != parentId).toList(),
        expenseItems: state.expenseItems.where((i) => i.parentId != parentId).toList(),
      );
    } else {
      state = state.copyWith(
        incomeParents: state.incomeParents.where((p) => p.id != parentId).toList(),
        incomeItems: state.incomeItems.where((i) => i.parentId != parentId).toList(),
      );
    }
  }

  // ── Item CRUD ────────────────────────────────────────────────────────────────

  void addItem(bool isExpense, String label, IconData icon, String parentId) {
    final item = CategoryItem(
      id: 'i_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      icon: icon,
      parentId: parentId,
    );
    if (isExpense) {
      state = state.copyWith(expenseItems: [...state.expenseItems, item]);
    } else {
      state = state.copyWith(incomeItems: [...state.incomeItems, item]);
    }
  }

  void editItem(bool isExpense, String itemId, {String? label, IconData? icon, String? parentId}) {
    if (isExpense) {
      state = state.copyWith(
        expenseItems: state.expenseItems.map((i) =>
          i.id == itemId ? i.copyWith(label: label, icon: icon, parentId: parentId) : i).toList(),
      );
    } else {
      state = state.copyWith(
        incomeItems: state.incomeItems.map((i) =>
          i.id == itemId ? i.copyWith(label: label, icon: icon, parentId: parentId) : i).toList(),
      );
    }
  }

  void deleteItem(bool isExpense, String itemId) {
    if (isExpense) {
      state = state.copyWith(
        expenseItems: state.expenseItems.where((i) => i.id != itemId).toList(),
      );
    } else {
      state = state.copyWith(
        incomeItems: state.incomeItems.where((i) => i.id != itemId).toList(),
      );
    }
  }

  // ─── Defaults ────────────────────────────────────────────────────────────────

  static const _recommended = ParentCategory(
    id: 'direkomendasikan',
    label: 'Direkomendasikan',
    icon: Icons.star_rounded,
    isRecommended: true,
    isSystem: true,
  );

  static const List<ParentCategory> _defaultExpenseParents = [
    _recommended,
    ParentCategory(id: 'makanan', label: 'Makanan', icon: Icons.fastfood_rounded),
    ParentCategory(id: 'transportasi', label: 'Transportasi', icon: Icons.directions_bus_rounded),
    ParentCategory(id: 'perumahan', label: 'Perumahan', icon: Icons.home_rounded),
    ParentCategory(id: 'hiburan', label: 'Hiburan', icon: Icons.sports_esports_rounded),
    ParentCategory(id: 'belanja', label: 'Belanja', icon: Icons.shopping_bag_rounded),
    ParentCategory(id: 'kesehatan', label: 'Kesehatan', icon: Icons.medical_services_rounded),
    ParentCategory(id: 'sosial', label: 'Sosial', icon: Icons.people_alt_rounded),
    ParentCategory(id: 'pajak', label: 'Pajak', icon: Icons.receipt_long_rounded),
  ];

  static const List<CategoryItem> _defaultExpenseItems = [
    CategoryItem(id: 'e1', label: 'Makanan Harian', icon: Icons.rice_bowl_rounded, parentId: 'makanan'),
    CategoryItem(id: 'e2', label: 'Diet', icon: Icons.eco_rounded, parentId: 'makanan'),
    CategoryItem(id: 'e3', label: 'Makan Malam', icon: Icons.dinner_dining_rounded, parentId: 'makanan'),
    CategoryItem(id: 'e4', label: 'Cemilan', icon: Icons.icecream_rounded, parentId: 'makanan'),
    CategoryItem(id: 'e5', label: 'Bensin', icon: Icons.local_gas_station_rounded, parentId: 'transportasi'),
    CategoryItem(id: 'e6', label: 'Parkir', icon: Icons.local_parking_rounded, parentId: 'transportasi'),
    CategoryItem(id: 'e7', label: 'Trans. Umum', icon: Icons.directions_bus_rounded, parentId: 'transportasi'),
    CategoryItem(id: 'e8', label: 'Servis', icon: Icons.build_rounded, parentId: 'transportasi'),
    CategoryItem(id: 'e9', label: 'Sewa/KPR', icon: Icons.house_rounded, parentId: 'perumahan'),
    CategoryItem(id: 'e10', label: 'Listrik', icon: Icons.bolt_rounded, parentId: 'perumahan'),
    CategoryItem(id: 'e11', label: 'Air', icon: Icons.water_drop_rounded, parentId: 'perumahan'),
    CategoryItem(id: 'e12', label: 'Internet', icon: Icons.wifi_rounded, parentId: 'perumahan'),
    CategoryItem(id: 'e13', label: 'Game', icon: Icons.sports_esports_rounded, parentId: 'hiburan'),
    CategoryItem(id: 'e14', label: 'Film', icon: Icons.movie_rounded, parentId: 'hiburan'),
    CategoryItem(id: 'e15', label: 'Hobi', icon: Icons.palette_rounded, parentId: 'hiburan'),
    CategoryItem(id: 'e16', label: 'Rekreasi', icon: Icons.attractions_rounded, parentId: 'hiburan'),
    CategoryItem(id: 'e17', label: 'Pakaian', icon: Icons.checkroom_rounded, parentId: 'belanja'),
    CategoryItem(id: 'e18', label: 'Kosmetik', icon: Icons.face_retouching_natural_rounded, parentId: 'belanja'),
    CategoryItem(id: 'e19', label: 'Elektronik', icon: Icons.devices_rounded, parentId: 'belanja'),
    CategoryItem(id: 'e20', label: 'Belanjaan', icon: Icons.shopping_cart_rounded, parentId: 'belanja'),
    CategoryItem(id: 'e21', label: 'Obat', icon: Icons.medication_rounded, parentId: 'kesehatan'),
    CategoryItem(id: 'e22', label: 'Dokter', icon: Icons.local_hospital_rounded, parentId: 'kesehatan'),
    CategoryItem(id: 'e23', label: 'Olahraga', icon: Icons.fitness_center_rounded, parentId: 'kesehatan'),
    CategoryItem(id: 'e24', label: 'Asuransi', icon: Icons.health_and_safety_rounded, parentId: 'kesehatan'),
    CategoryItem(id: 'e25', label: 'Hadiah', icon: Icons.card_giftcard_rounded, parentId: 'sosial'),
    CategoryItem(id: 'e26', label: 'Sumbangan', icon: Icons.volunteer_activism_rounded, parentId: 'sosial'),
    CategoryItem(id: 'e27', label: 'Pernikahan', icon: Icons.favorite_rounded, parentId: 'sosial'),
    CategoryItem(id: 'e28', label: 'Traktir', icon: Icons.restaurant_rounded, parentId: 'sosial'),
    CategoryItem(id: 'e29', label: 'Pajak', icon: Icons.account_balance_rounded, parentId: 'pajak'),
    CategoryItem(id: 'e30', label: 'PBB', icon: Icons.location_city_rounded, parentId: 'pajak'),
  ];

  static const List<ParentCategory> _defaultIncomeParents = [
    _recommended,
    ParentCategory(id: 'gaji', label: 'Gaji', icon: Icons.work_rounded),
    ParentCategory(id: 'bonus', label: 'Bonus', icon: Icons.savings_rounded),
    ParentCategory(id: 'investasi', label: 'Investasi', icon: Icons.trending_up_rounded),
    ParentCategory(id: 'lainnya', label: 'Lainnya', icon: Icons.monetization_on_rounded),
  ];

  static const List<CategoryItem> _defaultIncomeItems = [
    CategoryItem(id: 'i1', label: 'Gaji Utama', icon: Icons.payments_rounded, parentId: 'gaji'),
    CategoryItem(id: 'i2', label: 'Lembur', icon: Icons.more_time_rounded, parentId: 'gaji'),
    CategoryItem(id: 'i3', label: 'THR', icon: Icons.celebration_rounded, parentId: 'bonus'),
    CategoryItem(id: 'i4', label: 'Bonus Tahunan', icon: Icons.stars_rounded, parentId: 'bonus'),
    CategoryItem(id: 'i5', label: 'Komisi', icon: Icons.percent_rounded, parentId: 'bonus'),
    CategoryItem(id: 'i6', label: 'Dividen', icon: Icons.stacked_line_chart_rounded, parentId: 'investasi'),
    CategoryItem(id: 'i7', label: 'Capital Gain', icon: Icons.show_chart_rounded, parentId: 'investasi'),
    CategoryItem(id: 'i8', label: 'Bunga', icon: Icons.account_balance_rounded, parentId: 'investasi'),
    CategoryItem(id: 'i9', label: 'Pemberian', icon: Icons.card_giftcard_rounded, parentId: 'lainnya'),
    CategoryItem(id: 'i10', label: 'Jualan', icon: Icons.store_rounded, parentId: 'lainnya'),
    CategoryItem(id: 'i11', label: 'Lain-lain', icon: Icons.more_horiz_rounded, parentId: 'lainnya'),
  ];
}

final categoryProvider = NotifierProvider<CategoryNotifier, CategoryState>(CategoryNotifier.new);
