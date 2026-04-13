import 'package:flutter/material.dart';

// Curated list of icons users can choose for their category items
// Curated list of icons users can choose for their category items
const List<Map<String, dynamic>> kAvailableIcons = [
  // Makanan
  {'iconPath': 'assets/images/categories/makanan/food_1.png', 'label': 'Makanan 1', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_2.png', 'label': 'Makanan 2', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_3.png', 'label': 'Makanan 3', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_4.png', 'label': 'Makanan 4', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_5.png', 'label': 'Makanan 5', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_6.png', 'label': 'Makanan 6', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_7.png', 'label': 'Makanan 7', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_8.png', 'label': 'Makanan 8', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_9.png', 'label': 'Makanan 9', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_10.png', 'label': 'Makanan 10', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_11.png', 'label': 'Makanan 11', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_12.png', 'label': 'Makanan 12', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_13.png', 'label': 'Makanan 13', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_14.png', 'label': 'Makanan 14', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_15.png', 'label': 'Makanan 15', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_16.png', 'label': 'Makanan 16', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_17.png', 'label': 'Makanan 17', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_18.png', 'label': 'Makanan 18', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_19.png', 'label': 'Makanan 19', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_20.png', 'label': 'Makanan 20', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_21.png', 'label': 'Makanan 21', 'category': 'Makanan'},
  {'iconPath': 'assets/images/categories/makanan/food_22.png', 'label': 'Makanan 22', 'category': 'Makanan'},
  {'icon': Icons.fastfood_rounded, 'label': 'Fast Food', 'category': 'Makanan'},
  {'icon': Icons.rice_bowl_rounded, 'label': 'Nasi', 'category': 'Makanan'},
  {'icon': Icons.dinner_dining_rounded, 'label': 'Dinner', 'category': 'Makanan'},
  {'icon': Icons.icecream_rounded, 'label': 'Cemilan', 'category': 'Makanan'},
  {'icon': Icons.local_pizza_rounded, 'label': 'Pizza', 'category': 'Makanan'},
  {'icon': Icons.restaurant_rounded, 'label': 'Restoran', 'category': 'Makanan'},

  // Minuman
  {'iconPath': 'assets/images/categories/minuman/drink_1.png', 'label': 'Minuman 1', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_2.png', 'label': 'Minuman 2', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_3.png', 'label': 'Minuman 3', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_4.png', 'label': 'Minuman 4', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_5.png', 'label': 'Minuman 5', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_6.png', 'label': 'Minuman 6', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_7.png', 'label': 'Minuman 7', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_8.png', 'label': 'Minuman 8', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_9.png', 'label': 'Minuman 9', 'category': 'Minuman'},
  {'iconPath': 'assets/images/categories/minuman/drink_10.png', 'label': 'Minuman 10', 'category': 'Minuman'},
  {'icon': Icons.local_cafe_rounded, 'label': 'Kopi', 'category': 'Minuman'},
  {'icon': Icons.water_drop_rounded, 'label': 'Air', 'category': 'Minuman'},

  // Belanja
  {'iconPath': 'assets/images/categories/belanja/shop_1.png', 'label': 'Belanja 1', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_2.png', 'label': 'Belanja 2', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_3.png', 'label': 'Belanja 3', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_4.png', 'label': 'Belanja 4', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_5.png', 'label': 'Belanja 5', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_6.png', 'label': 'Belanja 6', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_7.png', 'label': 'Belanja 7', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_8.png', 'label': 'Belanja 8', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_9.png', 'label': 'Belanja 9', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_10.png', 'label': 'Belanja 10', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_11.png', 'label': 'Belanja 11', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_12.png', 'label': 'Belanja 12', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_13.png', 'label': 'Belanja 13', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_14.png', 'label': 'Belanja 14', 'category': 'Belanja'},
  {'iconPath': 'assets/images/categories/belanja/shop_15.png', 'label': 'Belanja 15', 'category': 'Belanja'},
  {'icon': Icons.shopping_cart_rounded, 'label': 'Keranjang', 'category': 'Belanja'},
  {'icon': Icons.shopping_bag_rounded, 'label': 'Tas', 'category': 'Belanja'},
  {'icon': Icons.checkroom_rounded, 'label': 'Pakaian', 'category': 'Belanja'},
  {'icon': Icons.face_retouching_natural_rounded, 'label': 'Kosmetik', 'category': 'Belanja'},
  {'icon': Icons.devices_rounded, 'label': 'Elektronik', 'category': 'Belanja'},
  {'icon': Icons.store_rounded, 'label': 'Toko', 'category': 'Belanja'},

  // Transport
  {'icon': Icons.directions_bus_rounded, 'label': 'Bus', 'category': 'Transport'},
  {'icon': Icons.local_gas_station_rounded, 'label': 'Bensin', 'category': 'Transport'},
  {'icon': Icons.local_parking_rounded, 'label': 'Parkir', 'category': 'Transport'},
  {'icon': Icons.directions_car_rounded, 'label': 'Mobil', 'category': 'Transport'},
  {'icon': Icons.two_wheeler_rounded, 'label': 'Motor', 'category': 'Transport'},
  {'icon': Icons.build_rounded, 'label': 'Servis', 'category': 'Transport'},
  {'icon': Icons.train_rounded, 'label': 'Kereta', 'category': 'Transport'},
  {'icon': Icons.flight_rounded, 'label': 'Pesawat', 'category': 'Transport'},

  // Rumah
  {'icon': Icons.home_rounded, 'label': 'Rumah', 'category': 'Rumah'},
  {'icon': Icons.house_rounded, 'label': 'Sewa', 'category': 'Rumah'},
  {'icon': Icons.bolt_rounded, 'label': 'Listrik', 'category': 'Rumah'},
  {'icon': Icons.wifi_rounded, 'label': 'Internet', 'category': 'Rumah'},
  {'icon': Icons.tv_rounded, 'label': 'TV', 'category': 'Rumah'},

  // Hiburan
  {'icon': Icons.sports_esports_rounded, 'label': 'Game', 'category': 'Hiburan'},
  {'icon': Icons.movie_rounded, 'label': 'Film', 'category': 'Hiburan'},
  {'icon': Icons.palette_rounded, 'label': 'Seni', 'category': 'Hiburan'},
  {'icon': Icons.attractions_rounded, 'label': 'Rekreasi', 'category': 'Hiburan'},
  {'icon': Icons.music_note_rounded, 'label': 'Musik', 'category': 'Hiburan'},
  {'icon': Icons.book_rounded, 'label': 'Buku', 'category': 'Hiburan'},

  // Kesehatan
  {'icon': Icons.medical_services_rounded, 'label': 'Medis', 'category': 'Kesehatan'},
  {'icon': Icons.medication_rounded, 'label': 'Obat', 'category': 'Kesehatan'},
  {'icon': Icons.local_hospital_rounded, 'label': 'RS', 'category': 'Kesehatan'},
  {'icon': Icons.fitness_center_rounded, 'label': 'Gym', 'category': 'Kesehatan'},
  {'icon': Icons.health_and_safety_rounded, 'label': 'Asuransi', 'category': 'Kesehatan'},

  // Lainnya
  {'icon': Icons.people_alt_rounded, 'label': 'Sosial', 'category': 'Lainnya'},
  {'icon': Icons.card_giftcard_rounded, 'label': 'Hadiah', 'category': 'Lainnya'},
  {'icon': Icons.volunteer_activism_rounded, 'label': 'Donasi', 'category': 'Lainnya'},
  {'icon': Icons.favorite_rounded, 'label': 'Pernikahan', 'category': 'Lainnya'},
  {'icon': Icons.account_balance_rounded, 'label': 'Bank', 'category': 'Lainnya'},
  {'icon': Icons.receipt_long_rounded, 'label': 'Tagihan', 'category': 'Lainnya'},
  {'icon': Icons.savings_rounded, 'label': 'Tabungan', 'category': 'Lainnya'},
  {'icon': Icons.trending_up_rounded, 'label': 'Investasi', 'category': 'Lainnya'},
  {'icon': Icons.percent_rounded, 'label': 'Komisi', 'category': 'Lainnya'},
  {'icon': Icons.payments_rounded, 'label': 'Bayar', 'category': 'Lainnya'},
  {'icon': Icons.eco_rounded, 'label': 'Diet', 'category': 'Lainnya'},
];

/// Bottom sheet that lets the user pick an icon from [kAvailableIcons].
/// Returns the selected [IconData] via [Navigator.pop].
class CategoryIconPicker extends StatefulWidget {
  final IconData? currentIcon;
  final String? currentIconPath;
  final Color themeColor;

  const CategoryIconPicker({
    super.key,
    this.currentIcon,
    this.currentIconPath,
    required this.themeColor,
  });

  @override
  State<CategoryIconPicker> createState() => _CategoryIconPickerState();
}

class _CategoryIconPickerState extends State<CategoryIconPicker> with SingleTickerProviderStateMixin {
  String _search = '';
  late TabController _tabController;
  final List<String> _categories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Belanja',
    'Transport',
    'Rumah',
    'Hiburan',
    'Kesehatan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Pilih Icon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari icon...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: widget.themeColor,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: widget.themeColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: _categories.map((c) => Tab(text: c)).toList(),
            onTap: (index) => setState(() {}),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final filtered = kAvailableIcons.where((m) {
                  final labelMatch = (m['label'] as String).toLowerCase().contains(_search.toLowerCase());
                  final categoryMatch = category == 'Semua' || m['category'] == category;
                  return labelMatch && categoryMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Tidak ada icon', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final icon = entry['icon'] as IconData?;
                    final path = entry['iconPath'] as String?;
                    
                    final isSelected = path != null 
                        ? path == widget.currentIconPath 
                        : (icon != null && icon == widget.currentIcon);

                    return GestureDetector(
                      onTap: () => Navigator.pop(context, {'icon': icon, 'path': path}),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.themeColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected ? [
                            BoxShadow(color: widget.themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ] : [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                          border: Border.all(color: isSelected ? widget.themeColor : Colors.white, width: 2),
                        ),
                        child: path != null 
                            ? Image.asset(path, fit: BoxFit.contain)
                            : Icon(icon, size: 28, color: isSelected ? Colors.white : Colors.grey.shade700),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience helper to show the icon picker and await the result.
Future<Map<String, dynamic>?> showIconPicker(BuildContext context, {IconData? current, String? currentPath, required Color themeColor}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryIconPicker(currentIcon: current, currentIconPath: currentPath, themeColor: themeColor),
  );
}
