import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/core/theme/app_colors.dart';
import 'package:urmoney/features/transactions/presentation/providers/category_provider.dart';
import 'package:urmoney/features/transactions/presentation/widgets/category_icon_picker.dart';

class CategorySettingsScreen extends ConsumerStatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  ConsumerState<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends ConsumerState<CategorySettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 56),
              title: const Text(
                'Pengaturan Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan')],
                onTap: (_) => setState(() {}),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _CategoryList(isExpense: true),
            _CategoryList(isExpense: false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Kategori Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddParentDialog(context, _tabController.index == 0),
      ),
    );
  }

  Future<void> _showAddParentDialog(BuildContext context, bool isExpense) async {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;
    final color = isExpense ? Colors.redAccent : Colors.teal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(height: 4, width: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Tambah Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final icon = await showIconPicker(ctx, current: selectedIcon, themeColor: color);
                        if (icon != null) setSheetState(() => selectedIcon = icon);
                      },
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Icon(selectedIcon, color: color, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nama kategori...',
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          ref.read(categoryProvider.notifier).addParent(isExpense, nameCtrl.text.trim(), selectedIcon);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category list for one tab (expense or income)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryList extends ConsumerWidget {
  final bool isExpense;
  const _CategoryList({required this.isExpense});

  Color get _color => isExpense ? Colors.redAccent : Colors.teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryProvider);
    final parents = isExpense ? state.expenseParents : state.incomeParents;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: parents.length,
      itemBuilder: (context, index) {
        final parent = parents[index];
        return _ParentCategoryCard(parent: parent, isExpense: isExpense, themeColor: _color);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium card for one parent category
// ─────────────────────────────────────────────────────────────────────────────

class _ParentCategoryCard extends ConsumerStatefulWidget {
  final ParentCategory parent;
  final bool isExpense;
  final Color themeColor;

  const _ParentCategoryCard({
    required this.parent,
    required this.isExpense,
    required this.themeColor,
  });

  @override
  ConsumerState<_ParentCategoryCard> createState() => _ParentCategoryCardState();
}

class _ParentCategoryCardState extends ConsumerState<_ParentCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProvider);
    final items = state.itemsFor(widget.parent.id, widget.isExpense)
        .where((i) => !widget.parent.isRecommended ? i.parentId == widget.parent.id : true)
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_expanded) _buildItemList(items),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.parent.isRecommended
                      ? [const Color(0xFFFFC300), const Color(0xFFFF9500)]
                      : [widget.themeColor.withOpacity(0.7), widget.themeColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.parent.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.parent.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (widget.parent.isRecommended)
                    Text('Default • tidak bisa dihapus',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                ],
              ),
            ),
            if (!widget.parent.isSystem) ...[
              _iconBtn(Icons.edit_rounded, () => _showRenameDialog()),
              _iconBtn(Icons.delete_outline_rounded, () => _confirmDelete(), color: Colors.redAccent),
            ],
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<CategoryItem> items) {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey.shade100),
        ...items.map((item) => _ItemRow(item: item, isExpense: widget.isExpense, themeColor: widget.themeColor)),
        if (!widget.parent.isRecommended)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GestureDetector(
              onTap: () => _showAddItemDialog(),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: widget.themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: widget.themeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Tambah item', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(icon, size: 20, color: color ?? Colors.grey.shade400),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori?'),
        content: Text('Semua item dalam "${widget.parent.label}" juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(categoryProvider.notifier).deleteParent(widget.isExpense, widget.parent.id);
    }
  }

  Future<void> _showRenameDialog() async {
    final ctrl = TextEditingController(text: widget.parent.label);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Nama'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(categoryProvider.notifier).renameParent(widget.isExpense, widget.parent.id, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    final ctrl = TextEditingController();
    IconData selectedIcon = Icons.label_rounded;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(height: 4, width: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Tambah Item ke "${widget.parent.label}"',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final icon = await showIconPicker(ctx, current: selectedIcon, themeColor: widget.themeColor);
                        if (icon != null) setSheetState(() => selectedIcon = icon);
                      },
                      child: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: widget.themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                        ),
                        child: Icon(selectedIcon, color: widget.themeColor, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Nama item...',
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (ctrl.text.trim().isEmpty) return;
                          ref.read(categoryProvider.notifier)
                            .addItem(widget.isExpense, ctrl.text.trim(), selectedIcon, widget.parent.id);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A single item row inside a parent card
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends ConsumerWidget {
  final CategoryItem item;
  final bool isExpense;
  final Color themeColor;
  const _ItemRow({required this.item, required this.isExpense, required this.themeColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: themeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () => _showEditDialog(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.edit_rounded, size: 18, color: Colors.grey.shade400),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Item?'),
        content: Text('Hapus "${item.label}" secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(categoryProvider.notifier).deleteItem(isExpense, item.id);
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: item.label);
    IconData selectedIcon = item.icon;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(height: 4, width: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Edit Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final icon = await showIconPicker(ctx, current: selectedIcon, themeColor: themeColor);
                        if (icon != null) setSheetState(() => selectedIcon = icon);
                      },
                      child: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: themeColor.withOpacity(0.3)),
                        ),
                        child: Icon(selectedIcon, color: themeColor, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Nama item...',
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(categoryProvider.notifier).editItem(
                        isExpense, item.id,
                        label: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
                        icon: selectedIcon,
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
