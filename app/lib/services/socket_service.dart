import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';
import 'storage_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool get isConnected => _socket?.connected == true;

  static void init() {
    final token = StorageService.getToken();
    if (token == null) return;

    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('[Socket] Connected to server successfully');
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected from server');
    });

    _socket!.onConnectError((err) {
      print('[Socket] Connect error: $err');
    });
  }

  static void joinConversation(String conversationId) {
    if (_socket == null) init();
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  static void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  static void sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    Function(dynamic)? onAck,
  }) {
    if (_socket == null) init();
    _socket?.emitWithAck(
      'send_message',
      {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType,
      },
      ack: onAck,
    );
  }

  static void emitTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  static void emitStopTyping(String conversationId) {
    _socket?.emit('stop_typing', {'conversationId': conversationId});
  }

  static void markRead(String conversationId) {
    _socket?.emit('mark_read', {'conversationId': conversationId});
  }

  static void onNewMessage(Function(dynamic) callback) {
    _socket?.off('new_message');
    _socket?.on('new_message', callback);
  }

  static void onUserTyping(Function(dynamic) callback) {
    _socket?.off('user_typing');
    _socket?.on('user_typing', callback);
  }

  static void onUserStopTyping(Function(dynamic) callback) {
    _socket?.off('user_stop_typing');
    _socket?.on('user_stop_typing', callback);
  }

  static void onMessagesRead(Function(dynamic) callback) {
    _socket?.off('messages_read');
    _socket?.on('messages_read', callback);
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
