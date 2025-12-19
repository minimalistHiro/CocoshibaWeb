import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/models/local_image.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/services/owner_service.dart';
import 'package:cocoshibaweb/utils/platform_image_picker.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EventEditPage extends StatefulWidget {
  const EventEditPage({
    super.key,
    required this.event,
    this.isExistingEvent = false,
  });

  final CalendarEvent event;
  final bool isExistingEvent;

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  static const List<Color> _colorPalette = [
    Color(0xFFEF5350),
    Color(0xFFF06292),
    Color(0xFFAB47BC),
    Color(0xFF7E57C2),
    Color(0xFF5C6BC0),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFFFFA726),
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizerController = TextEditingController();
  final _contentController = TextEditingController();
  final _capacityController = TextEditingController();

  final _eventService = EventService();
  final _ownerService = OwnerService();
  final PlatformImagePicker _imagePicker = createPlatformImagePicker();

  bool _isSaving = false;
  bool _isPickingImages = false;

  late DateTime _startDateTime;
  late DateTime _endDateTime;
  int _selectedColorIndex = 5;
  final List<String> _existingImageUrls = [];
  final List<LocalImage> _newImages = [];

  @override
  void initState() {
    super.initState();
    final event = widget.event;

    _nameController.text = event.name;
    _organizerController.text = event.organizer;
    _contentController.text = event.content;
    _capacityController.text = event.capacity.toString();

    _startDateTime = event.startDateTime;
    _endDateTime = event.endDateTime;

    _existingImageUrls.addAll(event.imageUrls);

    final index =
        _colorPalette.indexWhere((color) => color.value == event.colorValue);
    if (index >= 0) _selectedColorIndex = index;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizerController.dispose();
    _contentController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${dateTime.year}/${two(dateTime.month)}/${two(dateTime.day)} ${two(dateTime.hour)}:${two(dateTime.minute)}';
  }

  DateTime _defaultEndForStart(DateTime start) {
    final proposed = start.add(const Duration(hours: 1));
    if (proposed.year == start.year &&
        proposed.month == start.month &&
        proposed.day == start.day) {
      return proposed;
    }
    return DateTime(start.year, start.month, start.day, 23, 59);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickImages() async {
    if (_isSaving || _isPickingImages) return;
    setState(() => _isPickingImages = true);
    try {
      final picked = await _imagePicker.pickMultiImage();
      if (!mounted || picked.isEmpty) return;
      setState(() => _newImages.addAll(picked));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  void _removeExistingImageUrl(String url) {
    setState(() => _existingImageUrls.remove(url));
  }

  void _removeNewImage(LocalImage image) {
    setState(() => _newImages.remove(image));
  }

  Future<void> _save() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase が初期化されていません。')),
      );
      return;
    }

    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です。')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!_endDateTime.isAfter(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('終了日時は開始日時より後にしてください')),
      );
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    if (capacity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定員は 0 以上で入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedEvent = await _eventService.updateEvent(
        eventId: widget.event.id,
        isExistingEvent: widget.isExistingEvent,
        name: _nameController.text,
        organizer: _organizerController.text,
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
        content: _contentController.text,
        imageUrls: _existingImageUrls,
        colorValue: _colorPalette[_selectedColorIndex].value,
        capacity: capacity,
        images: _newImages,
        isClosedDay: widget.event.isClosedDay,
        existingEventId: widget.event.existingEventId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イベントを更新しました')),
      );
      Navigator.of(context).pop(updatedEvent);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    final user = auth.currentUser;

    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('イベント編集')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'イベント編集',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Firebase が初期化されていません。'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('イベント編集')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'イベント編集',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Text('ログインが必要です。'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('イベント編集')),
      body: StreamBuilder<bool>(
        stream: _ownerService.watchIsOwner(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final isOwner = snapshot.data == true;
          if (!isOwner) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'イベント編集',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text('このページはオーナーのみ利用できます。'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'イベント編集',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'イベント名',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'イベント名を入力してください';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _organizerController,
                            decoration: const InputDecoration(
                              labelText: '主催',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DateTimeField(
                                  label: '開始日時',
                                  value: _formatDateTime(_startDateTime),
                                  onTap: _isSaving
                                      ? null
                                      : () async {
                                          final picked = await _pickDateTime(
                                            _startDateTime,
                                          );
                                          if (picked == null || !mounted) {
                                            return;
                                          }
                                          setState(() {
                                            _startDateTime = picked;
                                            if (!_endDateTime.isAfter(picked)) {
                                              _endDateTime =
                                                  _defaultEndForStart(picked);
                                            }
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateTimeField(
                                  label: '終了日時',
                                  value: _formatDateTime(_endDateTime),
                                  onTap: _isSaving
                                      ? null
                                      : () async {
                                          final picked = await _pickDateTime(
                                            _endDateTime,
                                          );
                                          if (picked == null || !mounted) {
                                            return;
                                          }
                                          setState(() => _endDateTime = picked);
                                        },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ColorSelector(
                            palette: _colorPalette,
                            selectedIndex: _selectedColorIndex,
                            onSelect: _isSaving
                                ? null
                                : (index) => setState(
                                      () => _selectedColorIndex = index,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '定員',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final parsed = int.tryParse((value ?? '').trim());
                              if (parsed == null) return '数字で入力してください';
                              if (parsed < 0) return '0 以上で入力してください';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contentController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: '内容',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return '内容を入力してください';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _EditImagePickerGrid(
                            imageUrls: _existingImageUrls,
                            newImages: _newImages,
                            isBusy: _isSaving || _isPickingImages,
                            onAdd: _pickImages,
                            onRemoveUrl: _removeExistingImageUrl,
                            onRemoveNewImage: _removeNewImage,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                                child: const Text('キャンセル'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: _isSaving ? null : _save,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('更新'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            color: isEnabled
                ? theme.colorScheme.onSurfaceVariant
                : theme.disabledColor,
          ),
        ),
        child: Text(value),
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.palette,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Color> palette;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'イベントカラー',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(palette.length, (index) {
            final color = palette[index];
            final isSelected = index == selectedIndex;
            return GestureDetector(
              onTap: onSelect == null ? null : () => onSelect!(index),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.white,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _EditImagePickerGrid extends StatelessWidget {
  const _EditImagePickerGrid({
    required this.imageUrls,
    required this.newImages,
    required this.isBusy,
    required this.onAdd,
    required this.onRemoveUrl,
    required this.onRemoveNewImage,
  });

  final List<String> imageUrls;
  final List<LocalImage> newImages;
  final bool isBusy;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemoveUrl;
  final ValueChanged<LocalImage> onRemoveNewImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[
      ...imageUrls.map(
        (url) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: CocoshibaNetworkImage(
                  url: url,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: isBusy ? null : () => onRemoveUrl(url),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ...newImages.map(
        (image) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: isBusy ? null : () => onRemoveNewImage(image),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      InkWell(
        onTap: isBusy ? null : onAdd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Center(
            child: isBusy
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  )
                : const Icon(Icons.add_a_photo),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '画像',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final tileSize = (constraints.maxWidth - spacing * 2) / 3;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: children
                  .map(
                    (child) => SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: child,
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}
