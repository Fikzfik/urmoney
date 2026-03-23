class TransactionModel {
  final String id;
  final String userId;
  final String? bookId;
  final String walletId;
  final String categoryId;
  final String? categoryItemId;
  final double amount;
  final String type; // 'income', 'expense', 'transfer'
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    this.bookId,
    required this.walletId,
    required this.categoryId,
    this.categoryItemId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      walletId: json['wallet_id'],
      categoryId: json['category_id'],
      categoryItemId: json['category_item_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      note: json['note'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'book_id': bookId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'category_item_id': categoryItemId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
    };
  }
}
