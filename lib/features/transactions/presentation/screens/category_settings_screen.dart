import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urmoney/features/transactions/data/models/category_item_model.dart';
import 'package:urmoney/features/transactions/data/models/category_model.dart';
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
                        final result = await showIconPicker(ctx, current: selectedIcon, themeColor: color);
                        if (result != null) {
                          setSheetState(() {
                            if (result['icon'] != null) selectedIcon = result['icon'];
                            // For parent categories, we currently only support Material Icons 
                            // as they are primarily used for broad categories.
                            // If we want to support image icons for parents, we'd need to update CategoryModel.
                          });
                        }
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

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: parents.length,
      onReorder: (oldIndex, newIndex) {
        // Current implementation doesn't persist order in DB yet, 
        // but we can update the local state for now.
        // In a real app, you'd call ref.read(categoryProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final parent = parents[index];
        return _ParentCategoryCard(
          key: ValueKey(parent.id),
          parent: parent, 
          isExpense: isExpense, 
          themeColor: _color,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium card for one parent category
// ─────────────────────────────────────────────────────────────────────────────

class _ParentCategoryCard extends ConsumerStatefulWidget {
  final CategoryModel parent;
  final bool isExpense;
  final Color themeColor;

  const _ParentCategoryCard({
    super.key,
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
        .where((i) => !widget.parent.isDefault ? i.categoryId == widget.parent.id : true)
        .toList();

    return DragTarget<CategoryItemModel>(
      onWillAccept: (data) => data != null && data.categoryId != widget.parent.id,
      onAccept: (data) {
        ref.read(categoryProvider.notifier).moveItem(data.id, widget.parent.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pindahkan ${data.name} ke ${widget.parent.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isOver ? widget.themeColor.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isOver ? Border.all(color: widget.themeColor, width: 2) : null,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildHeader(),
              if (_expanded || isOver) _buildItemList(items),
            ],
          ),
        );
      },
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
                  colors: widget.parent.isDefault && (widget.parent.id == 'rec_exp' || widget.parent.id == 'rec_inc')
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
                  Text(widget.parent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (widget.parent.isDefault)
                    Text('Default • tidak bisa dihapus',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                ],
              ),
            ),
            if (!widget.parent.isDefault) ...[
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

  Widget _buildItemList(List<CategoryItemModel> items) {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey.shade100),
        ...items.map((item) => _ItemRow(item: item, isExpense: widget.isExpense, themeColor: widget.themeColor)),
        if (!(widget.parent.isDefault && (widget.parent.id == 'rec_exp' || widget.parent.id == 'rec_inc')))
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
        content: Text('Semua item dalam "${widget.parent.name}" juga akan dihapus.'),
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
      ref.read(categoryProvider.notifier).deleteParent(widget.parent.id);
    }
  }

  Future<void> _showRenameDialog() async {
    final ctrl = TextEditingController(text: widget.parent.name);
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
                ref.read(categoryProvider.notifier).renameParent(widget.parent.id, ctrl.text.trim());
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
    IconData? selectedIcon = Icons.label_rounded;
    String? selectedIconPath;
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
                Text('Tambah Item ke "${widget.parent.name}"',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await showIconPicker(ctx, current: selectedIcon, themeColor: widget.themeColor);
                        if (result != null) {
                          setSheetState(() {
                            if (result['icon'] != null) {
                              selectedIcon = result['icon'];
                              selectedIconPath = null;
                            } else if (result['path'] != null) {
                              selectedIconPath = result['path'];
                              selectedIcon = null;
                            }
                          });
                        }
                      },
                      child: Container(
                        width: 56, height: 56,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                        ),
                        child: selectedIconPath != null
                            ? Image.asset(selectedIconPath!, fit: BoxFit.contain)
                            : Icon(selectedIcon ?? Icons.category_rounded, color: widget.themeColor, size: 28),
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
                          ref.read(categoryProvider.notifier).addItem(
                            ctrl.text.trim(),
                            selectedIcon,
                            widget.parent.id,
                            iconPath: selectedIconPath,
                          );
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

class _ItemRow extends ConsumerStatefulWidget {
  final CategoryItemModel item;
  final bool isExpense;
  final Color themeColor;
  const _ItemRow({required this.item, required this.isExpense, required this.themeColor});

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  Timer? _scrollTimer;

  void _stopScrollTimer() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  void _startScrollTimer(ScrollableState scrollable, double scrollDirection) {
    if (_scrollTimer != null) return;
    
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final pos = scrollable.position;
      final newOffset = (pos.pixels + (scrollDirection * 15)).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      pos.jumpTo(newOffset);
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final scrollable = Scrollable.of(context);
    final renderBox = scrollable.context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollOffset = renderBox.localToGlobal(Offset.zero);
    final scrollHeight = renderBox.size.height;
    final dy = details.globalPosition.dy;

    // Trigger scrolling when within 15% of the top or bottom of the scrollable area
    const thresholdPercent = 0.15;
    final edgeHeight = scrollHeight * thresholdPercent;

    if (dy < scrollOffset.dy + edgeHeight) {
      // Scroll Up
      _startScrollTimer(scrollable, -1.0);
    } else if (dy > scrollOffset.dy + scrollHeight - edgeHeight) {
      // Scroll Down
      _startScrollTimer(scrollable, 1.0);
    } else {
      _stopScrollTimer();
    }
  }

  @override
  void dispose() {
    _stopScrollTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<CategoryItemModel>(
      data: widget.item,
      axis: Axis.vertical,
      onDragUpdate: _handleDragUpdate,
      onDragEnd: (_) => _stopScrollTimer(),
      onDraggableCanceled: (_, __) => _stopScrollTimer(),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: widget.themeColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              widget.item.iconPath != null 
                  ? Image.asset(widget.item.iconPath!, width: 20, height: 20)
                  : Icon(widget.item.icon ?? Icons.help_outline, color: widget.themeColor),
              const SizedBox(width: 14),
              Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemContent(context, ref),
      ),
      child: _buildItemContent(context, ref),
    );
  }

  Widget _buildItemContent(BuildContext context, WidgetRef ref) {
    final item = widget.item;
    final themeColor = widget.themeColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            child: item.iconPath != null
                ? Image.asset(item.iconPath!, width: 24, height: 24)
                : Icon(item.icon ?? Icons.help_outline, color: themeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
        content: Text('Hapus "${widget.item.name}" secara permanen?'),
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
      ref.read(categoryProvider.notifier).deleteItem(widget.item.id);
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final item = widget.item;
    final themeColor = widget.themeColor;
    final ctrl = TextEditingController(text: item.name);
    IconData? selectedIcon = item.icon;
    String? selectedIconPath = item.iconPath;

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
                        final result = await showIconPicker(ctx, 
                          current: selectedIcon, 
                          currentPath: selectedIconPath,
                          themeColor: themeColor
                        );
                        if (result != null) {
                          setSheetState(() {
                            if (result['icon'] != null) {
                              selectedIcon = result['icon'];
                              selectedIconPath = null;
                            } else if (result['path'] != null) {
                              selectedIconPath = result['path'];
                              selectedIcon = null;
                            }
                          });
                        }
                      },
                      child: Container(
                        width: 56, height: 56,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: themeColor.withOpacity(0.3)),
                        ),
                        child: selectedIconPath != null
                            ? Image.asset(selectedIconPath!, fit: BoxFit.contain)
                            : Icon(selectedIcon ?? Icons.category_rounded, color: themeColor, size: 28),
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
                        item.id,
                        ctrl.text.trim().isEmpty ? item.name : ctrl.text.trim(),
                        selectedIcon?.codePoint,
                        iconPath: selectedIconPath,
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
