class WalletModel {
  final String id;
  final String userId;
  final String? bookId;
  final String name;
  final String type;
  final double balance;
  final String? icon;
  final double? taxRate;
  final int? taxDay;
  final double? interestRate;
  final String? payoutSchedule;
  final int? payoutDay;

  WalletModel({
    required this.id,
    required this.userId,
    this.bookId,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
    this.taxRate,
    this.taxDay,
    this.interestRate,
    this.payoutSchedule,
    this.payoutDay,
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
      taxRate: json['tax_rate'] != null ? (json['tax_rate'] as num).toDouble() : null,
      taxDay: json['tax_day'],
      interestRate: json['interest_rate'] != null ? (json['interest_rate'] as num).toDouble() : null,
      payoutSchedule: json['payout_schedule'],
      payoutDay: json['payout_day'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      if (bookId != null) 'book_id': bookId,
      'tax_rate': taxRate,
      'tax_day': taxDay,
      'interest_rate': interestRate,
      'payout_schedule': payoutSchedule,
      'payout_day': payoutDay,
    };
  }
}
