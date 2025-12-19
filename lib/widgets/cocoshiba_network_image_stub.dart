import 'package:flutter/material.dart';

class CocoshibaNetworkImage extends StatelessWidget {
  const CocoshibaNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    Widget child = Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
      loadingBuilder: (context, loaded, progress) {
        if (progress == null) return loaded;
        return placeholder ?? const Center(child: CircularProgressIndicator());
      },
    );

    final radius = borderRadius;
    if (radius != null) {
      child = ClipRRect(borderRadius: radius, child: child);
    }

    return child;
  }
}
