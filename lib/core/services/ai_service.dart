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
  final String? suggestedIcon;

  AIReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.suggestedCategory,
    required this.suggestedCategoryItem,
    this.suggestedIcon,
  });

  factory AIReceiptItem.fromJson(Map<String, dynamic> json) {
    return AIReceiptItem(
      name: json['name'] as String? ?? 'Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      suggestedCategory: json['suggestedCategory'] as String? ?? 'Kebutuhan',
      suggestedCategoryItem: json['suggestedCategoryItem'] as String? ?? 'Lainnya',
      suggestedIcon: json['suggestedIcon'] as String?,
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
      model: 'gemini-1.5-flash',
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
- "suggestedIcon" pilih salah satu asset path yang paling cocok dari daftar bertema ini:
    * Belanja: assets/images/categories/belanja/shop_1.png s/d shop_15.png
    * Makanan: assets/images/categories/makanan/food_1.png s/d food_22.png
    * Minuman: assets/images/categories/minuman/drink_1.png s/d drink_10.png
  Gunakan null jika tidak ada yang sangat cocok.
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

  // ========== VOICE ASSISTANT ENGINE ==========

  Future<Map<String, dynamic>?> processCommand(
    String text, {
    required List<String> walletNames,
    required List<String> categoryNames,
    required List<String> categoryItemNames,
  }) async {
    if (_apiKey.isEmpty) return null;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // Current stable as of April 2026
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt = '''
Kamu adalah Urmoney, asisten keuangan cerdas. 
Tugasmu: Analisis percakapan user dan ubah menjadi aksi database.

Konteks Database User:
- Daftar Dompet: ${walletNames.join(", ")}
- Daftar Kategori Utama: ${categoryNames.join(", ")}
- Contoh Sub-kategori: ${categoryItemNames.take(15).join(", ")}

Riwayat Percakapan & Input:
$text

ATURAN PENTING:
1. Jika nominal uang dan keperluan sudah jelas, GUNAKAN aksi "add_transaction".
2. Jika kategori/item belum ada di daftar di atas, BUATKAN nama kategori/item yang paling logis dalam Bahasa Indonesia. JANGAN bertanya kecuali nominal uang tidak ada.
3. Untuk dompet, jika user tidak menyebutkan, gunakan dompet pertama: "${walletNames.isNotEmpty ? walletNames.first : 'Cash'}".
4. Selalu pilih "iconPath" yang paling cocok dari daftar di bawah.

Format JSON yang harus dikembalikan:
- Transaksi: {"action": "add_transaction", "data": {"type": "expense", "amount": 50000, "note": "...", "walletName": "...", "categoryName": "...", "categoryItemName": "...", "iconPath": "assets/images/categories/..."}, "reply": "Sip! [Item] sebesar Rp [Nominal] sudah dicatat ke [Dompet]."}
- Transfer: {"action": "transfer", "data": {"fromWallet": "...", "toWallet": "...", "amount": 0, "note": "..."}, "reply": "..."}
- Tanya (hanya jika nominal tidak ada): {"action": "ask_question", "reply": "Boleh tahu berapa nominal yang dikeluarkan?"}

Aturan Ketat Icon:
- Belanja: assets/images/categories/belanja/shop_1.png s/d shop_15.png
- Makanan: assets/images/categories/makanan/food_1.png s/d food_22.png
- Minuman: assets/images/categories/minuman/drink_1.png s/d drink_10.png
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String? resultText = response.text;
      
      if (resultText == null || resultText.isEmpty) {
        return {
          'action': 'unknown',
          'reply': 'Maaf, asisten kehilangan sinyal pikiran. Coba ulangi?'
        };
      }

      // Sometimes models wrap JSON in markdown blocks even with responseMimeType
      if (resultText.contains('```json')) {
        resultText = resultText.split('```json')[1].split('```')[0].trim();
      } else if (resultText.contains('```')) {
        resultText = resultText.split('```')[1].split('```')[0].trim();
      }

      return jsonDecode(resultText);
    } catch (e) {
      print("[AIService] Command Error: $e");
      
      String diagnosticInfo = e.toString();
      try {
        // Try to list models to help the user find the right ID
        final models = await listAvailableModels();
        diagnosticInfo += "\n\nAvailable Models: ${models.join(', ')}";
      } catch (_) {}

      return {
        'action': 'error',
        'reply': 'Gagal akses AI. Detail: $diagnosticInfo',
        'data': {'raw_error': e.toString()}
      };
    }
  }

  Future<List<String>> listAvailableModels() async {
    if (_apiKey.isEmpty) return [];
    // Note: The SDK might not support listModels directly in all versions, 
    // but we can try to use the GenAI API directly or a workaround if needed.
    // For now, let's just return a list of common ones to try.
    return [
      'gemini-3.1-flash', 
      'gemini-3.1-pro', 
      'gemini-2.5-flash', 
      'gemini-2.5-pro'
    ];
  }
}

final aiServiceProvider = Provider((ref) => AIService());
