class TransferModel {
  final String id;
  final String userId;
  final String bookId;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final double fee;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  TransferModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.fee = 0.0,
    this.note,
    required this.date,
    required this.createdAt,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      fromWalletId: json['from_wallet_id'],
      toWalletId: json['to_wallet_id'],
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      note: json['note'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'book_id': bookId,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'fee': fee,
      'note': note,
      'date': date.toIso8601String(),
    };
  }
}
