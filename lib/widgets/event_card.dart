import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.imageAspectRatio = 1,
    this.imageCacheWidth,
    this.imageCacheHeight,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;
  final double imageAspectRatio;
  final int? imageCacheWidth;
  final int? imageCacheHeight;

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imageUrls.isNotEmpty;

    Widget buildImage() {
      final placeholder = Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.black38,
        ),
      );

      if (!hasImage) return placeholder;
      if (kIsWeb) {
        return Image.network(
          event.imageUrls.first,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return placeholder;
          },
        );
      }
      return CocoshibaNetworkImage(
        url: event.imageUrls.first,
        fit: BoxFit.cover,
        placeholder: placeholder,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRect(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: imageAspectRatio,
              child: buildImage(),
            ),
          ),
        ),
      ),
    );
  }
}
