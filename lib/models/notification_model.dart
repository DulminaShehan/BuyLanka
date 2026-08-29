class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'order', 'promo', 'system'
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'order',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'order',
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : {},
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
