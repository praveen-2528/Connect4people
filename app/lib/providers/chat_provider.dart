import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatState {
  final bool isLoading;
  final List<ConversationModel> conversations;
  final Map<String, List<MessageModel>> messagesByConversation;
  final Set<String> typingUsers;
  final String? errorMessage;

  ChatState({
    required this.isLoading,
    required this.conversations,
    required this.messagesByConversation,
    required this.typingUsers,
    this.errorMessage,
  });

  factory ChatState.initial() => ChatState(
        isLoading: false,
        conversations: [],
        messagesByConversation: {},
        typingUsers: {},
      );

  ChatState copyWith({
    bool? isLoading,
    List<ConversationModel>? conversations,
    Map<String, List<MessageModel>>? messagesByConversation,
    Set<String>? typingUsers,
    String? errorMessage,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      messagesByConversation: messagesByConversation ?? this.messagesByConversation,
      typingUsers: typingUsers ?? this.typingUsers,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api = ApiService();

  ChatNotifier() : super(ChatState.initial()) {
    initListeners();
    fetchConversations();
  }

  void initListeners() {
    SocketService.onNewMessage((data) {
      if (data == null) return;
      final newMsg = MessageModel.fromJson(data);
      final convId = newMsg.conversationId;

      final currentMessages = List<MessageModel>.from(state.messagesByConversation[convId] ?? []);
      // Add message if not duplicate
      if (!currentMessages.any((m) => m.id == newMsg.id)) {
        currentMessages.add(newMsg);
      }

      final updatedMap = Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMap[convId] = currentMessages;

      state = state.copyWith(messagesByConversation: updatedMap);
      fetchConversations(); // update last message preview
    });

    SocketService.onUserTyping((data) {
      if (data != null && data['userId'] != null) {
        final typing = Set<String>.from(state.typingUsers)..add(data['userId']);
        state = state.copyWith(typingUsers: typing);
      }
    });

    SocketService.onUserStopTyping((data) {
      if (data != null && data['userId'] != null) {
        final typing = Set<String>.from(state.typingUsers)..remove(data['userId']);
        state = state.copyWith(typingUsers: typing);
      }
    });
  }

  Future<void> fetchConversations() async {
    final res = await _api.listConversations();
    if (res.success && res.data != null) {
      final List list = res.data;
      final convs = list.map((c) => ConversationModel.fromJson(c)).toList();
      state = state.copyWith(conversations: convs);
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    SocketService.joinConversation(conversationId);
    SocketService.markRead(conversationId);

    final res = await _api.getMessages(conversationId);
    if (res.success && res.data != null) {
      final List list = res.data['messages'] ?? res.data ?? [];
      final msgs = list.map((m) => MessageModel.fromJson(m)).toList();
      // Reverse if received newest first, so they render bottom-up
      final sorted = msgs.reversed.toList();

      final updatedMap = Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMap[conversationId] = sorted;

      state = state.copyWith(messagesByConversation: updatedMap);
    }
  }

  void sendMessage(String conversationId, String content) {
    if (content.trim().isEmpty) return;

    SocketService.sendMessage(
      conversationId: conversationId,
      content: content.trim(),
      onAck: (response) {
        if (response != null && response['success'] == true) {
          fetchMessages(conversationId);
        }
      },
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
