class BookModel {
  final String id;
  final String userId;
  final String name;
  final String? icon;

  BookModel({required this.id, required this.userId, required this.name, this.icon});

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      // id and user_id are handled by Supabase default and auth context
    };
  }
}
