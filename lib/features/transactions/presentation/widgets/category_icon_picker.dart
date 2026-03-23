import 'package:flutter/material.dart';

// Curated list of icons users can choose for their category items
const List<Map<String, dynamic>> kAvailableIcons = [
  // Food & Drink
  {'icon': Icons.fastfood_rounded, 'label': 'Fast Food'},
  {'icon': Icons.rice_bowl_rounded, 'label': 'Nasi'},
  {'icon': Icons.dinner_dining_rounded, 'label': 'Dinner'},
  {'icon': Icons.eco_rounded, 'label': 'Diet'},
  {'icon': Icons.icecream_rounded, 'label': 'Cemilan'},
  {'icon': Icons.local_cafe_rounded, 'label': 'Kopi'},
  {'icon': Icons.restaurant_rounded, 'label': 'Restoran'},
  {'icon': Icons.local_pizza_rounded, 'label': 'Pizza'},
  // Transport
  {'icon': Icons.directions_bus_rounded, 'label': 'Bus'},
  {'icon': Icons.local_gas_station_rounded, 'label': 'Bensin'},
  {'icon': Icons.local_parking_rounded, 'label': 'Parkir'},
  {'icon': Icons.directions_car_rounded, 'label': 'Mobil'},
  {'icon': Icons.two_wheeler_rounded, 'label': 'Motor'},
  {'icon': Icons.build_rounded, 'label': 'Servis'},
  {'icon': Icons.train_rounded, 'label': 'Kereta'},
  {'icon': Icons.flight_rounded, 'label': 'Pesawat'},
  // Home
  {'icon': Icons.home_rounded, 'label': 'Rumah'},
  {'icon': Icons.house_rounded, 'label': 'Sewa'},
  {'icon': Icons.bolt_rounded, 'label': 'Listrik'},
  {'icon': Icons.water_drop_rounded, 'label': 'Air'},
  {'icon': Icons.wifi_rounded, 'label': 'Internet'},
  {'icon': Icons.tv_rounded, 'label': 'TV'},
  // Entertainment
  {'icon': Icons.sports_esports_rounded, 'label': 'Game'},
  {'icon': Icons.movie_rounded, 'label': 'Film'},
  {'icon': Icons.palette_rounded, 'label': 'Seni'},
  {'icon': Icons.attractions_rounded, 'label': 'Rekreasi'},
  {'icon': Icons.music_note_rounded, 'label': 'Musik'},
  {'icon': Icons.book_rounded, 'label': 'Buku'},
  // Shopping
  {'icon': Icons.shopping_cart_rounded, 'label': 'Belanja'},
  {'icon': Icons.shopping_bag_rounded, 'label': 'Tas'},
  {'icon': Icons.checkroom_rounded, 'label': 'Pakaian'},
  {'icon': Icons.face_retouching_natural_rounded, 'label': 'Kosmetik'},
  {'icon': Icons.devices_rounded, 'label': 'Elektronik'},
  // Health
  {'icon': Icons.medical_services_rounded, 'label': 'Medis'},
  {'icon': Icons.medication_rounded, 'label': 'Obat'},
  {'icon': Icons.local_hospital_rounded, 'label': 'RS'},
  {'icon': Icons.fitness_center_rounded, 'label': 'Gym'},
  {'icon': Icons.health_and_safety_rounded, 'label': 'Asuransi'},
  // Social
  {'icon': Icons.people_alt_rounded, 'label': 'Sosial'},
  {'icon': Icons.card_giftcard_rounded, 'label': 'Hadiah'},
  {'icon': Icons.volunteer_activism_rounded, 'label': 'Donasi'},
  {'icon': Icons.favorite_rounded, 'label': 'Pernikahan'},
  // Finance
  {'icon': Icons.account_balance_rounded, 'label': 'Bank'},
  {'icon': Icons.receipt_long_rounded, 'label': 'Tagihan'},
  {'icon': Icons.savings_rounded, 'label': 'Tabungan'},
  {'icon': Icons.trending_up_rounded, 'label': 'Investasi'},
  {'icon': Icons.percent_rounded, 'label': 'Komisi'},
  {'icon': Icons.payments_rounded, 'label': 'Bayar'},
  {'icon': Icons.store_rounded, 'label': 'Toko'},
];

/// Bottom sheet that lets the user pick an icon from [kAvailableIcons].
/// Returns the selected [IconData] via [Navigator.pop].
class CategoryIconPicker extends StatefulWidget {
  final IconData? currentIcon;
  final Color themeColor;

  const CategoryIconPicker({
    super.key,
    this.currentIcon,
    required this.themeColor,
  });

  @override
  State<CategoryIconPicker> createState() => _CategoryIconPickerState();
}

class _CategoryIconPickerState extends State<CategoryIconPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = kAvailableIcons
        .where((m) => (m['label'] as String).toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Pilih Icon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari icon...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final entry = filtered[index];
                final icon = entry['icon'] as IconData;
                final isSelected = icon == widget.currentIcon;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, icon),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? widget.themeColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? widget.themeColor : Colors.grey.shade200),
                        ),
                        child: Icon(icon, size: 26, color: isSelected ? Colors.white : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: isSelected ? widget.themeColor : Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience helper to show the icon picker and await the result.
Future<IconData?> showIconPicker(BuildContext context, {IconData? current, required Color themeColor}) {
  return showModalBottomSheet<IconData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryIconPicker(currentIcon: current, themeColor: themeColor),
  );
}
