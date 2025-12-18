import 'package:cocoshibaweb/models/user_chat_models.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/user_chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserChatSupportPage extends StatelessWidget {
  UserChatSupportPage({super.key});

  final UserChatService _chatService = UserChatService();

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('ログインが必要です'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminPageHeader(title: 'ユーザーチャットサポート'),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<UserChatThread>>(
            stream: _chatService.watchAllThreads(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: const Text('読み込みに失敗しました'),
                  ),
                );
              }

              final threads = snapshot.data ?? const [];
              if (threads.isEmpty) {
                return Center(
                  child: Text(
                    'ユーザーからのチャットはまだありません',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: threads.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return StreamBuilder<DateTime?>(
                    stream: _chatService.watchLastReadAt(
                      threadId: thread.id,
                      viewerId: currentUserId,
                    ),
                    builder: (context, readSnapshot) {
                      final readAt = readSnapshot.data;
                      final hasUnread = thread.updatedAt != null &&
                          (readAt == null || readAt.isBefore(thread.updatedAt!)) &&
                          thread.lastMessageSenderId != currentUserId;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundImage: thread.avatarUrl.isNotEmpty
                              ? NetworkImage(thread.avatarUrl)
                              : null,
                          child: thread.avatarUrl.isEmpty
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        title: Text(
                          thread.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          thread.lastMessage.isEmpty ? 'メッセージなし' : thread.lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: hasUnread
                            ? Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push(
                            '${CocoshibaPaths.adminChat}/${
                                Uri.encodeComponent(thread.id)
                            }',
                            extra: thread,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
