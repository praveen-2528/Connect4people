class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sender: json['sender'] is Map<String, dynamic> ? json['sender'] : null,
    );
  }
}

class ConversationModel {
  final String id;
  final Map<String, dynamic> otherUser;
  final MessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final String? bookingId;

  ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    this.bookingId,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      otherUser: json['other_user'] is Map<String, dynamic>
          ? json['other_user']
          : {'name': 'User', 'id': ''},
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      bookingId: json['booking_id']?.toString(),
    );
  }
}
