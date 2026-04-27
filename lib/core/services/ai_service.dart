import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
  String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<AIReceiptResult?> processReceipt(
    Uint8List imageBytes, {
    List<String> existingCategories = const [],
    List<String> existingCategoryItems = const [],
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API Key belum diatur di file .env');
    }

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

    final receiptModels = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro-vision',
    ];

    for (final modelName in receiptModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        );

        final response = await model.generateContent(content);
        final text = response.text;
        if (text == null) continue;

        final data = jsonDecode(text);
        return AIReceiptResult.fromJson(data);
      } catch (e) {
        print('AI Receipt Error ($modelName): $e');
        
        if (modelName == receiptModels.last) {
          // FINAL FALLBACK TO GROQ VISION
          if (_groqApiKey.isNotEmpty && _groqApiKey != 'YOUR_GROQ_API_KEY_HERE') {
            try {
              print("[AIService] Falling back to Groq Vision...");
              return await _processReceiptWithGroq(imageBytes, existingCategories, existingCategoryItems);
            } catch (ge) {
              print("[AIService] Groq Vision also failed: $ge");
              rethrow;
            }
          }
          rethrow;
        }
        
        // Small delay before next model to avoid rate limits
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return null;
  }

  Future<AIReceiptResult?> _processReceiptWithGroq(
    Uint8List imageBytes,
    List<String> existingCategories,
    List<String> existingCategoryItems,
  ) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final base64Image = base64Encode(imageBytes);

    final prompt = '''
Analisis gambar struk belanja ini dan kembalikan JSON:
{
  "storeName": "Nama Toko",
  "date": "YYYY-MM-DD",
  "items": [{"name": "Item", "price": 1000, "quantity": 1, "subtotal": 1000, "suggestedCategory": "Cat", "suggestedCategoryItem": "Sub"}],
  "subtotal": 1000, "tax": 0, "total": 1000, "paymentMethod": "CASH"
}
''';

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.2-11b-vision-preview', // Vision model
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          }
        ],
        'response_format': {'type': 'json_object'}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return AIReceiptResult.fromJson(jsonDecode(content));
    }
    throw Exception('Groq Vision failed: ${response.body}');
  }

  // ========== VOICE ASSISTANT ENGINE ==========

  Future<Map<String, dynamic>?> processCommand(
    String text, {
    required List<String> walletNames,
    required List<String> categoryNames,
    required List<String> categoryItemNames,
  }) async {
    if (_apiKey.isEmpty) return null;

    final modelsToTry = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    String lastError = "";

    for (var modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        );

        final prompt = '''
(Context: April 2026)
Kamu adalah Urmoney, asisten keuangan otomatis.
Tugas: Ubah input user menjadi JSON untuk database.

Database:
- Dompet: ${walletNames.join(", ")}
- Kategori Utama: ${categoryNames.join(", ")}
- Item Terdaftar: ${categoryItemNames.take(20).join(", ")}

Data User:
$text

ATURAN MUTLAK:
1. Jika ada Angka/Nominal (misal: 30rb, 30.000) dan Keperluan (misal: makan, bensin), gunakan aksi "add_transaction".
2. JANGAN BERTANYA jika nominal sudah ada. Jika kategori tidak ada di daftar, BUAT kategori baru yang pas.
3. "categoryItemName" HARUS diisi nama benda spesifik (misal: "Iuran Tisl").
4. Dompet default: "${walletNames.isNotEmpty ? walletNames.first : 'Cash'}".

JSON:
{
  "action": "add_transaction",
  "data": {
    "type": "expense",
    "amount": 30000,
    "note": "Keterangan",
    "walletName": "Cash",
    "categoryName": "Kategori",
    "categoryItemName": "Item",
    "iconPath": "assets/images/categories/makanan/food_1.png"
  },
  "reply": "Keterangan dicatat ke Cash."
}
''';

        final response = await model.generateContent([Content.text(prompt)]);
        String? resultText = response.text;
        
        if (resultText == null || resultText.isEmpty) continue;

        if (resultText.contains('```json')) {
          resultText = resultText.split('```json')[1].split('```')[0].trim();
        } else if (resultText.contains('```')) {
          resultText = resultText.split('```')[1].split('```')[0].trim();
        }

        return jsonDecode(resultText);
      } catch (e) {
        lastError = e.toString();
        print("[AIService] Gemini $modelName GAGAL: $e");
        await Future.delayed(Duration(milliseconds: 300));
      }
    }

    // FALLBACK KE GROQ (PENTING)
    if (_groqApiKey.isNotEmpty && _groqApiKey != 'YOUR_GROQ_API_KEY_HERE') {
      try {
        print("[AIService] ⚠️ Gemini Limit/Error. Mencoba CADANGAN (Groq)...");
        final groqResult = await _processWithGroq(text, walletNames, categoryNames, categoryItemNames);
        if (groqResult != null) {
          print("[AIService] ✅ Berhasil menggunakan Groq!");
          return groqResult;
        }
      } catch (e) {
        print("[AIService] ❌ Groq juga gagal: $e");
        lastError = "Semua provider gagal. Terakhir: $e";
      }
    }

    // If all models failed
    return {
      'action': 'error',
      'reply': 'Semua model Gemini sibuk/gagal. Terakhir: $lastError',
      'data': {'raw_error': lastError}
    };
  }

  Future<Map<String, dynamic>?> _processWithGroq(
    String text,
    List<String> walletNames,
    List<String> categoryNames,
    List<String> categoryItemNames,
  ) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final prompt = '''
(Context: April 2026)
Kamu adalah Urmoney, asisten keuangan otomatis.
Ubah input user menjadi JSON.
Database:
- Dompet: ${walletNames.join(", ")}
- Kategori: ${categoryNames.join(", ")}
Input: "$text"

JSON:
{
  "action": "add_transaction",
  "data": {
    "type": "expense",
    "amount": 30000,
    "note": "Keterangan",
    "walletName": "Cash",
    "categoryName": "Kategori",
    "categoryItemName": "Item",
    "iconPath": "assets/images/categories/makanan/food_1.png"
  },
  "reply": "Keterangan dicatat."
}
''';

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'response_format': {'type': 'json_object'}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    }
    throw Exception('Groq API failed: ${response.body}');
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
