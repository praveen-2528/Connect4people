import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(chatProvider.notifier).fetchConversations();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final conversations = chatState.conversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: SafeArea(
        child: chatState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Chats open automatically once a booking request is made.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(chatProvider.notifier).fetchConversations(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final otherUser = conv.otherUser;
                        final otherName = otherUser['name']?.toString() ?? 'User';
                        final otherId = otherUser['id']?.toString() ?? '';
                        final lastMsg = conv.lastMessage?.content ?? 'Conversation started';
                        final timeStr = conv.lastMessageAt != null
                            ? DateFormat('hh:mm a').format(conv.lastMessageAt!)
                            : '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              otherName.isNotEmpty ? otherName[0] : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ],
                          ),
                          subtitle: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: conv.id,
                                  otherUserName: otherName,
                                  otherUserId: otherId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
