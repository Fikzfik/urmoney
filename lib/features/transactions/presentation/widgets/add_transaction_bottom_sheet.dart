import 'package:flutter/material.dart';
import 'package:urmoney/core/theme/app_colors.dart';

class AddTransactionBottomSheet extends StatelessWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'Pengeluaran'),
                Tab(text: 'Pemasukan'),
                Tab(text: 'Transfer'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFormPlaceholder('Form Pengeluaran (Expense)'),
                  _buildFormPlaceholder('Form Pemasukan (Income)'),
                  _buildFormPlaceholder('Form Transfer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPlaceholder(String title) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
