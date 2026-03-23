class WalletModel {
  final String id;
  final String userId;
  final String? bookId;
  final String name;
  final String type;
  final double balance;
  final String? icon;

  WalletModel({
    required this.id,
    required this.userId,
    this.bookId,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      if (bookId != null) 'book_id': bookId,
    };
  }
}
