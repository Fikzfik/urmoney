import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  String suggestedCategory;
  String suggestedCategoryItem;

  AIReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.suggestedCategory,
    required this.suggestedCategoryItem,
  });

  factory AIReceiptItem.fromJson(Map<String, dynamic> json) {
    return AIReceiptItem(
      name: json['name'] as String? ?? 'Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      suggestedCategory: json['suggestedCategory'] as String? ?? 'Kebutuhan',
      suggestedCategoryItem: json['suggestedCategoryItem'] as String? ?? 'Lainnya',
    );
  }
}

class AIReceiptResult {
  final String storeName;
  final DateTime? date;
  final List<AIReceiptItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String? paymentMethod;

  AIReceiptResult({
    required this.storeName,
    this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.paymentMethod,
  });

  factory AIReceiptResult.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((i) => AIReceiptItem.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return AIReceiptResult(
      storeName: json['storeName'] as String? ?? 'Toko',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  /// Generate formatted note with item breakdown
  String toFormattedNote() {
    final buffer = StringBuffer();
    buffer.writeln('🏪 $storeName');
    buffer.writeln('');
    for (var item in items) {
      final qty = item.quantity > 1 ? ' x${item.quantity}' : '';
      buffer.writeln('• ${item.name}$qty — Rp ${_formatNumber(item.subtotal)}');
    }
    if (tax > 0) {
      buffer.writeln('');
      buffer.writeln('PPN: Rp ${_formatNumber(tax)}');
    }
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      buffer.writeln('Bayar: $paymentMethod');
    }
    return buffer.toString().trim();
  }

  static String _formatNumber(double n) {
    final str = n.toStringAsFixed(0);
    final result = StringBuffer();
    final reversed = str.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) result.write('.');
      result.write(reversed[i]);
    }
    return result.toString().split('').reversed.join();
  }
}

class AIService {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<AIReceiptResult?> processReceipt(
    Uint8List imageBytes, {
    List<String> existingCategories = const [],
    List<String> existingCategoryItems = const [],
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API Key belum diatur di file .env');
    }

    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final categoriesHint = existingCategories.isNotEmpty
        ? 'Kategori yang sudah ada di app: ${existingCategories.join(", ")}. '
            'Usahakan gunakan kategori yang sudah ada untuk suggestedCategory. '
        : '';

    final itemsHint = existingCategoryItems.isNotEmpty
        ? 'Item kategori yang sudah ada: ${existingCategoryItems.join(", ")}. '
            'Usahakan gunakan item yang sudah ada untuk suggestedCategoryItem. '
        : '';

    final prompt = TextPart('''
Analisis gambar struk/nota belanja ini dan ekstrak semua detail.
$categoriesHint
$itemsHint
Jika tidak cocok dengan yang sudah ada, buatkan nama kategori/item yang sesuai dalam bahasa Indonesia.

Kembalikan JSON dengan format:
{
  "storeName": "Nama Toko",
  "date": "2026-04-13",
  "items": [
    {
      "name": "Nama Barang",
      "price": 15000,
      "quantity": 2,
      "subtotal": 30000,
      "suggestedCategory": "Makan & Minum",
      "suggestedCategoryItem": "Groceries"
    }
  ],
  "subtotal": 140000,
  "tax": 15400,
  "total": 155400,
  "paymentMethod": "QRIS" 
}

Aturan:
- "items" wajib berisi SEMUA barang yang terlihat di struk
- "price" adalah harga per satuan
- "subtotal" per item = price * quantity  
- "tax" adalah PPN/pajak jika terlihat di struk, 0 jika tidak ada
- "total" adalah total akhir yang dibayarkan (sudah termasuk pajak)
- "paymentMethod" bisa berisi: "CASH", "QRIS", "DEBIT", "KREDIT", "GOPAY", "OVO", "SHOPEEPAY", "DANA", "LINKAJA", atau nama bank seperti "BCA", "BRI", dst. Null jika tidak terlihat.
- "suggestedCategory" harus berupa nama kategori pengeluaran yang logis
- "suggestedCategoryItem" harus berupa nama item spesifik di bawah kategori tersebut
- Jika tanggal tidak jelas, set null
- Semua angka dalam Rupiah tanpa desimal
    ''');

    final content = [
      Content.multi([
        prompt,
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) return null;

      final data = jsonDecode(text);
      return AIReceiptResult.fromJson(data);
    } catch (e) {
      print('AI Error: $e');
      rethrow;
    }
  }
}

final aiServiceProvider = Provider((ref) => AIService());
