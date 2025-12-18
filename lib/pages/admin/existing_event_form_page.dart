import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/services/existing_events_admin_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExistingEventFormPage extends StatefulWidget {
  const ExistingEventFormPage({super.key, this.eventId});

  final String? eventId;

  @override
  State<ExistingEventFormPage> createState() => _ExistingEventFormPageState();
}

class _ExistingEventFormPageState extends State<ExistingEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ExistingEventsAdminService _service = ExistingEventsAdminService();

  final _nameController = TextEditingController();
  final _organizerController = TextEditingController();
  final _contentController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imageUrlsController = TextEditingController();

  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 2));
  Color _color = Colors.blue;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  bool get _isEdit => widget.eventId != null && widget.eventId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizerController.dispose();
    _contentController.dispose();
    _capacityController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (Firebase.apps.isEmpty) return;
    final id = widget.eventId;
    if (id == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final event = await _service.fetchExistingEvent(id);
      if (!mounted) return;
      if (event == null) {
        setState(() {
          _loadError = '既存イベントが見つかりませんでした。';
          _isLoading = false;
        });
        return;
      }
      _nameController.text = event.name;
      _organizerController.text = event.organizer;
      _contentController.text = event.content;
      _capacityController.text = event.capacity.toString();
      _imageUrlsController.text = event.imageUrls.join('\n');
      _start = event.startDateTime;
      _end = event.endDateTime;
      _color = event.color;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = '読み込みに失敗しました。';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null || !mounted) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
    if (time == null || !mounted) return;
    setState(() {
      _end = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  int _parseCapacity() {
    final raw = _capacityController.text.trim();
    final value = int.tryParse(raw);
    if (value == null || value < 0) return 0;
    return value;
  }

  List<String> _parseImageUrls() {
    return _imageUrlsController.text
        .split(RegExp(r'\\r?\\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    if (Firebase.apps.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text;
      final organizer = _organizerController.text;
      final content = _contentController.text;
      final capacity = _parseCapacity();
      final imageUrls = _parseImageUrls();
      final colorValue = _color.value;

      if (_isEdit) {
        await _service.updateExistingEvent(
          widget.eventId!,
          name: name,
          organizer: organizer,
          startDateTime: _start,
          endDateTime: _end,
          content: content,
          imageUrls: imageUrls,
          colorValue: colorValue,
          capacity: capacity,
        );
      } else {
        await _service.createExistingEvent(
          name: name,
          organizer: organizer,
          startDateTime: _start,
          endDateTime: _end,
          content: content,
          imageUrls: imageUrls,
          colorValue: colorValue,
          capacity: capacity,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '既存イベントを更新しました' : '既存イベントを作成しました')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        children: [
          const AdminPageHeader(title: '既存イベント編集'),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_loadError!))),
        ],
      );
    }

    final theme = Theme.of(context);
    final swatch = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.grey,
    ];

    String fmt(DateTime dt) =>
        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return ListView(
      children: [
        AdminPageHeader(title: _isEdit ? '既存イベントを編集' : '既存イベントを新規作成'),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'イベント名'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'イベント名を入力してください' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _organizerController,
                        decoration: const InputDecoration(labelText: '主催者（任意）'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(labelText: '定員（人 / 任意）'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '開催日時',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStart,
                              icon: const Icon(Icons.schedule),
                              label: Text('開始: ${fmt(_start)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEnd,
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text('終了: ${fmt(_end)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'テーマカラー',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in swatch)
                            InkWell(
                              onTap: () => setState(() => _color = c),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color == c
                                        ? theme.colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(labelText: '内容'),
                        minLines: 3,
                        maxLines: 8,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlsController,
                        decoration: const InputDecoration(
                          labelText: '画像URL（改行区切り / 任意）',
                        ),
                        minLines: 2,
                        maxLines: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isEdit ? '更新する' : '作成する'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
