import 'dart:async';

import 'package:cocoshibaweb/models/user_chat_models.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/services/user_chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class UserChatThreadPage extends StatefulWidget {
  const UserChatThreadPage({
    super.key,
    required this.threadId,
    this.initialThread,
  });

  final String threadId;
  final UserChatThread? initialThread;

  @override
  State<UserChatThreadPage> createState() => _UserChatThreadPageState();
}

class _UserChatThreadPageState extends State<UserChatThreadPage> {
  final UserChatService _chatService = UserChatService();
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;
  String? _lastSeenMessageId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(threadId: widget.threadId, text: text);
      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージの送信に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _markReadIfNeeded(List<UserChatMessage> messages) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    if (messages.isEmpty) return;

    final latestId = messages.last.id;
    if (latestId == _lastSeenMessageId) return;
    _lastSeenMessageId = latestId;

    scheduleMicrotask(() {
      _chatService.markThreadAsRead(threadId: widget.threadId, viewerId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('ログインが必要です'));
    }

    final headerTitle = widget.initialThread?.userName ?? 'チャット';

    return Column(
      children: [
        AdminPageHeader(title: headerTitle),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<UserChatMessage>>(
            stream: _chatService.watchMessages(widget.threadId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('メッセージを読み込めませんでした'));
              }

              final messages = snapshot.data ?? const [];
              _markReadIfNeeded(messages);

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'まだメッセージがありません',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message.senderId == currentUserId;
                  final bubbleColor = isMine
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant;
                  final textColor = isMine
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant;

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMine)
                            Text(
                              message.senderName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          Text(
                            message.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '返信を入力...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
