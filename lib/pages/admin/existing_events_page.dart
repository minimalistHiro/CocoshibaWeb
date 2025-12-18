import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/services/existing_events_admin_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExistingEventsPage extends StatefulWidget {
  const ExistingEventsPage({super.key});

  @override
  State<ExistingEventsPage> createState() => _ExistingEventsPageState();
}

class _ExistingEventsPageState extends State<ExistingEventsPage> {
  final ExistingEventsAdminService _service = ExistingEventsAdminService();

  Future<void> _confirmDelete(CalendarEvent event) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認'),
            content: Text('${event.name.isEmpty ? 'このイベント' : event.name} を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('削除する', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !shouldDelete) return;
    try {
      await _service.deleteExistingEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('既存イベントを削除しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
    }
  }

  Widget _buildEventCard(CalendarEvent event) {
    final title = event.name.isEmpty ? '無題のイベント' : event.name;
    final organizer =
        event.organizer.isEmpty ? '主催者未設定' : '主催: ${event.organizer}';
    final capacity = event.capacity > 0 ? '定員: ${event.capacity}人' : '定員未設定';
    final subtitle = '$organizer / $capacity';
    final imageUrl = event.imageUrls.isNotEmpty ? event.imageUrls.first : null;

    return Card(
      child: ListTile(
        onTap: () => context.push('${CocoshibaPaths.adminExistingEvents}/edit/${event.id}'),
        leading: _ExistingEventThumbnail(imageUrl: imageUrl, color: event.color),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<_ExistingEventAction>(
          onSelected: (action) {
            switch (action) {
              case _ExistingEventAction.edit:
                context.push('${CocoshibaPaths.adminExistingEvents}/edit/${event.id}');
                break;
              case _ExistingEventAction.delete:
                _confirmDelete(event);
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _ExistingEventAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('編集'),
              ),
            ),
            PopupMenuItem(
              value: _ExistingEventAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('削除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(
          title: '既存イベント編集',
          trailing: [
            IconButton(
              tooltip: '既存イベントを追加',
              onPressed: () => context.push('${CocoshibaPaths.adminExistingEvents}/new'),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<CalendarEvent>>(
            stream: _service.watchExistingEvents(descending: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('読み込みに失敗しました。再試行'),
                  ),
                );
              }

              final events = snapshot.data ?? const <CalendarEvent>[];
              if (events.isEmpty) {
                return const Center(child: Text('登録されている既存イベントがありません'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildEventCard(events[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExistingEventThumbnail extends StatelessWidget {
  const _ExistingEventThumbnail({this.imageUrl, required this.color});

  final String? imageUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: AspectRatio(
          aspectRatio: 1,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Container(
                  color: color.withOpacity(0.15),
                  child: Icon(Icons.event_note, color: color),
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withOpacity(0.15),
                    child: Icon(Icons.broken_image_outlined, color: color),
                  ),
                ),
        ),
      ),
    );
  }
}

enum _ExistingEventAction { edit, delete }
