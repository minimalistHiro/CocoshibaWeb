import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class CocoshibaNetworkImage extends StatefulWidget {
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
  State<CocoshibaNetworkImage> createState() => _CocoshibaNetworkImageState();
}

class _CocoshibaNetworkImageState extends State<CocoshibaNetworkImage> {
  static bool _styleInjected = false;

  late final String _viewType;
  late final html.ImageElement _img;
  late final html.DivElement _container;

  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _ensurePointerPassthroughStyle();

    _viewType = 'cocoshiba-img-${identityHashCode(this)}';
    _img = html.ImageElement();
    _container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'hidden'
      ..style.pointerEvents = 'none';

    _applyStyles();
    _bindImage(widget.url);

    _container.children.add(_img);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      return _container;
    });
  }

  @override
  void didUpdateWidget(covariant CocoshibaNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bindImage(widget.url);
    }
    if (oldWidget.fit != widget.fit ||
        oldWidget.borderRadius != widget.borderRadius) {
      _applyStyles();
    }
  }

  void _applyStyles() {
    _img
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _objectFit(widget.fit);

    final radius = widget.borderRadius;
    _container.style.borderRadius =
        radius == null ? '' : _cssBorderRadius(radius);
  }

  void _bindImage(String url) {
    _loaded = false;
    _failed = false;

    _img.onLoad.first.then((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    });
    _img.onError.first.then((_) {
      if (!mounted) return;
      setState(() => _failed = true);
    });

    _img.src = url;
  }

  void _ensurePointerPassthroughStyle() {
    if (_styleInjected) return;
    _styleInjected = true;

    final style = html.StyleElement()
      ..innerHtml = 'flt-platform-view { pointer-events: none; }';
    html.document.head?.append(style);
  }

  String _objectFit(BoxFit fit) {
    return switch (fit) {
      BoxFit.cover => 'cover',
      BoxFit.contain => 'contain',
      BoxFit.fill => 'fill',
      BoxFit.none => 'none',
      BoxFit.fitHeight => 'contain',
      BoxFit.fitWidth => 'contain',
      BoxFit.scaleDown => 'scale-down',
    };
  }

  String _cssBorderRadius(BorderRadius radius) {
    String r(Radius v) => '${v.x}px';
    return '${r(radius.topLeft)} ${r(radius.topRight)} ${r(radius.bottomRight)} ${r(radius.bottomLeft)}';
  }

  @override
  Widget build(BuildContext context) {
    final placeholder =
        widget.placeholder ?? const Center(child: CircularProgressIndicator());

    final view = SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );

    if (_failed) return placeholder;
    if (_loaded) return view;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        placeholder,
        Opacity(opacity: 0.01, child: view),
      ],
    );
  }
}
