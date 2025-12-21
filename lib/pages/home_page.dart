import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _controller = ScrollController();

  final List<_StorySection> _sections = const [
    _StorySection(
      title: '人をつなぐ街のブックカフェ',
      subtitle: 'Antenna Books & Cafe ココシバ',
      body:
          '本棚の間を抜けると、静かな時間が流れます。\n'
          '偶然の一冊や、ふとした会話が生まれる場所。',
      imageAsset: 'assets/images/IMG_0038.jpeg',
      isHero: true,
    ),
    _StorySection(
      title: '静かな没頭の時間',
      subtitle: 'ふらっと立ち寄れる読書席',
      body:
          '店内の本は自由に手に取り、席でゆっくり読めます。\n'
          '読書の合間にコーヒーを。',
      imageAsset: 'assets/images/IMG_1682.jpeg',
      layout: _StoryLayout.quietHighlight,
    ),
    _StorySection(
      title: 'イベントがつなぐ緑',
      subtitle: 'ボードゲーム会やLIVE',
      body:
          '人と人が交わる夜。\n'
          '小さな挑戦を後押しするイベントを開催しています。',
      imageAsset: 'assets/images/event_connecting_green.jpeg',
      layout: _StoryLayout.eventHighlight,
    ),
    _StorySection(
      title: '手仕事と物語',
      subtitle: 'ハンドメイド・スローマーケット',
      body:
          'つくる人の想いと、選ぶ人の感性が出会います。\n'
          '街の小さなマーケット。',
      imageAsset: 'assets/images/IMG_1680.png',
      layout: _StoryLayout.handmadeHighlight,
    ),
    _StorySection(
      title: 'アートとやさしい時間',
      subtitle: '音・言葉・表現',
      body:
          'アーティストの表現が、日常に彩りを添えます。\n'
          '気軽に立ち寄れる文化の場所。',
      imageAsset: 'assets/images/IMG_1385.jpeg',
      hasImageRadius: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final section in _sections) {
      precacheImage(AssetImage(section.imageAsset), context);
      }
      precacheImage(const AssetImage('assets/images/IMG_1385.jpeg'), context);
      precacheImage(const AssetImage('assets/images/IMG_3803.jpeg'), context);
      precacheImage(const AssetImage('assets/images/IMG_1681.jpeg'), context);
      precacheImage(const AssetImage('assets/images/IMG_1683.jpeg'), context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _StoryScrollBehavior(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight =
              constraints.hasBoundedHeight && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height;

          return ListView.builder(
            controller: _controller,
            itemCount: _sections.length + 1,
            itemExtent: viewportHeight,
            itemBuilder: (context, index) {
              final isStoreInfo = index == _sections.length;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final hasOffset = _controller.hasClients &&
                      _controller.position.hasContentDimensions;
                  final page = hasOffset
                      ? (_controller.offset / viewportHeight)
                      : 0.0;
                  final delta = (page - index).abs();
                  final opacity = (1 - delta).clamp(0.0, 1.0);
                  final easedOpacity = Curves.easeOut.transform(opacity);
                  final translateY = 40 * delta;

                  return Opacity(
                    opacity: easedOpacity,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: child,
                    ),
                  );
                },
                child: RepaintBoundary(
                  child: isStoreInfo
                      ? const _StoreInfoSectionView()
                      : _StorySectionView(section: _sections[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

@immutable
class _StorySection {
  const _StorySection({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.imageAsset,
    this.isHero = false,
    this.layout = _StoryLayout.standard,
    this.hasImageRadius = true,
  });

  final String title;
  final String subtitle;
  final String body;
  final String imageAsset;
  final bool isHero;
  final _StoryLayout layout;
  final bool hasImageRadius;
}

enum _StoryLayout {
  standard,
  eventHighlight,
  handmadeHighlight,
  quietHighlight,
}

class _StorySectionView extends StatelessWidget {
  const _StorySectionView({required this.section});

  final _StorySection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = section.isHero ? Colors.white : theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (section.isHero) {
          return SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  section.imageAsset,
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black.withOpacity(0.2),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            section.subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            section.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            section.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (section.layout == _StoryLayout.eventHighlight) {
          return _EventHighlightSectionView(section: section);
        }

        if (section.layout == _StoryLayout.handmadeHighlight) {
          return _HandmadeHighlightSectionView(section: section);
        }

        if (section.layout == _StoryLayout.quietHighlight) {
          return _QuietHighlightSectionView(section: section);
        }

        final isWide = constraints.maxWidth >= 880;
        final sectionPadding = isWide
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
        final imageWidth = isWide
            ? constraints.maxWidth * 0.52
            : constraints.maxWidth - sectionPadding.horizontal;
        final imageHeight = isWide
            ? (constraints.maxHeight * 0.7).clamp(320.0, 520.0)
            : (imageWidth * 0.62).clamp(260.0, 520.0);

        final textBlock = Column(
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              section.subtitle,
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              section.title,
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              section.body,
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                height: 1.8,
              ),
            ),
          ],
        );

        return SizedBox.expand(
          child: Padding(
            padding: sectionPadding,
            child: isWide
                ? Row(
                    children: [
                      Expanded(child: textBlock),
                      const SizedBox(width: 32),
                      _StoryImage(
                        imageAsset: section.imageAsset,
                        width: imageWidth,
                        height: imageHeight,
                        hasRadius: section.hasImageRadius,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StoryImage(
                        imageAsset: section.imageAsset,
                        width: imageWidth,
                        height: imageHeight,
                        hasRadius: section.hasImageRadius,
                      ),
                      const SizedBox(height: 24),
                      textBlock,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EventHighlightSectionView extends StatefulWidget {
  const _EventHighlightSectionView({required this.section});

  final _StorySection section;

  @override
  State<_EventHighlightSectionView> createState() =>
      _EventHighlightSectionViewState();
}

class _EventHighlightSectionViewState extends State<_EventHighlightSectionView> {
  _CollageLayout _layout = _CollageLayout.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _layout = _createCollageLayout();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;
        final collageHeight = isWide
            ? (constraints.maxHeight * 0.62).clamp(320.0, 520.0)
            : (constraints.maxWidth * 0.7).clamp(260.0, 460.0);
        final collageWidth = isWide
            ? (constraints.maxWidth * 0.78).clamp(520.0, 860.0)
            : constraints.maxWidth * 0.92;
        final sectionPadding = isWide
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

        final textBlock = _EventBodyText(
          section: widget.section,
          textColor: textColor,
          maxWidth: isWide ? constraints.maxWidth * 0.7 : constraints.maxWidth,
        );

        return SizedBox.expand(
          child: Padding(
            padding: sectionPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: collageWidth,
                    height: collageHeight,
                    child: _EventCollage(
                      layout: _layout,
                      isWide: isWide,
                      title: widget.section.title,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(0, -115),
                    child: textBlock,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HandmadeHighlightSectionView extends StatefulWidget {
  const _HandmadeHighlightSectionView({required this.section});

  final _StorySection section;

  @override
  State<_HandmadeHighlightSectionView> createState() =>
      _HandmadeHighlightSectionViewState();
}

class _HandmadeHighlightSectionViewState
    extends State<_HandmadeHighlightSectionView> {
  _CollageLayout _layout = _CollageLayout.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _layout = _createHandmadeLayout();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;
        final collageHeight = isWide
            ? (constraints.maxHeight * 0.6).clamp(300.0, 520.0)
            : (constraints.maxWidth * 0.78).clamp(260.0, 460.0);
        final collageWidth = isWide
            ? (constraints.maxWidth * 0.84).clamp(560.0, 920.0)
            : constraints.maxWidth * 0.94;
        final sectionPadding = isWide
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

        final textBlock = _EventBodyText(
          section: widget.section,
          textColor: textColor,
          maxWidth: isWide ? constraints.maxWidth * 0.42 : constraints.maxWidth,
        );

        return SizedBox.expand(
          child: Padding(
            padding: sectionPadding,
          child: isWide
              ? Center(
                  child: SizedBox(
                    width: collageWidth,
                    height: collageHeight,
                    child: _HandmadeCollage(
                      layout: _layout,
                      textBlock: Align(
                        alignment: Alignment.bottomRight,
                        child: Transform.translate(
                          offset: const Offset(8, 4),
                          child: textBlock,
                        ),
                      ),
                    ),
                  ),
                )
              : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: collageWidth,
                          height: collageHeight,
                          child: _HandmadeCollage(
                            layout: _layout,
                            textBlock: const SizedBox.shrink(),
                            textAreaWidthFactor: 0,
                            imageAreaPaddingFactor: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: const Offset(0, -70),
                          child: textBlock,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _QuietHighlightSectionView extends StatefulWidget {
  const _QuietHighlightSectionView({required this.section});

  final _StorySection section;

  @override
  State<_QuietHighlightSectionView> createState() =>
      _QuietHighlightSectionViewState();
}

class _QuietHighlightSectionViewState
    extends State<_QuietHighlightSectionView> {
  _CollageLayout _layout = _CollageLayout.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _layout = _createQuietLayout();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;
        final collageHeight = isWide
            ? (constraints.maxHeight * 0.58).clamp(300.0, 520.0)
            : (constraints.maxWidth * 0.76).clamp(260.0, 460.0);
        final collageWidth = isWide
            ? (constraints.maxWidth * 0.82).clamp(560.0, 920.0)
            : constraints.maxWidth * 0.94;

        final textBlock = _EventBodyText(
          section: widget.section,
          textColor: textColor,
          maxWidth: isWide ? constraints.maxWidth * 0.4 : constraints.maxWidth,
          scaleWithWidth: !isWide,
        );

        final sectionPadding = isWide
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

        return SizedBox.expand(
          child: Padding(
            padding: sectionPadding,
            child: isWide
                ? Center(
                    child: SizedBox(
                      width: collageWidth,
                      height: collageHeight,
                      child: _QuietCollage(
                        layout: _layout,
                        textBlock: Align(
                          alignment: Alignment.topRight,
                          child: textBlock,
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: collageWidth,
                          height: collageHeight,
                          child: _QuietCollage(
                            layout: _layout,
                            textBlock: const SizedBox.shrink(),
                            textAreaWidthFactor: 0,
                            imageAreaPaddingFactor: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: const Offset(0, -32),
                          child: textBlock,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EventBodyText extends StatelessWidget {
  const _EventBodyText({
    required this.section,
    required this.textColor,
    required this.maxWidth,
    this.scaleWithWidth = true,
  });

  final _StorySection section;
  final Color textColor;
  final double? maxWidth;
  final bool scaleWithWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuietSubtitle = section.subtitle == 'ふらっと立ち寄れる読書席';
    final baseSubtitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final baseMaxWidth = maxWidth ?? availableWidth;
        final textScale = isQuietSubtitle && scaleWithWidth
            ? (availableWidth / 600).clamp(0.64, 1.0)
            : 1.0;
        final scaledMaxWidth =
            isQuietSubtitle ? baseMaxWidth * textScale : baseMaxWidth;
        final titleStyle = theme.textTheme.headlineSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1.3,
        );
        final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
          color: textColor,
          height: 1.8,
        );

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: scaledMaxWidth),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    section.subtitle,
                    textAlign: TextAlign.left,
                    style: baseSubtitleStyle?.copyWith(
                      fontSize: baseSubtitleStyle.fontSize != null
                          ? baseSubtitleStyle.fontSize! * textScale
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    section.title,
                    textAlign: TextAlign.left,
                    style: titleStyle?.copyWith(
                      fontSize: titleStyle.fontSize != null
                          ? titleStyle.fontSize! * textScale
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    section.body,
                    textAlign: TextAlign.left,
                    style: bodyStyle?.copyWith(
                      fontSize: bodyStyle.fontSize != null
                          ? bodyStyle.fontSize! * textScale
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HandmadeCollage extends StatelessWidget {
  const _HandmadeCollage({
    required this.layout,
    required this.textBlock,
    this.textAreaWidthFactor = 0.34,
    this.imageAreaPaddingFactor = 0.9,
  });

  final _CollageLayout layout;
  final Widget textBlock;
  final double textAreaWidthFactor;
  final double imageAreaPaddingFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textAreaWidth = constraints.maxWidth * textAreaWidthFactor;
        final imageAreaWidth = constraints.maxWidth - textAreaWidth;
        final imageAreaHeight = constraints.maxHeight;

        final primarySize = Size(
          imageAreaWidth * 0.76,
          imageAreaHeight * 0.76,
        );
        final secondarySize = Size(
          imageAreaWidth * 0.65,
          imageAreaHeight * 0.68,
        );

        final primaryOffset = Offset(
          imageAreaWidth * -0.04,
          imageAreaHeight * 0.38,
        );
        final secondaryOffset = Offset(
          imageAreaWidth * 0.46,
          imageAreaHeight * -0.1,
        );

        final imageWidgets = <_CollageImageSpec>[
          _CollageImageSpec(
            asset: 'assets/images/IMG_1680.png',
            size: primarySize,
            baseOffset: primaryOffset,
            layout: layout.first,
          ),
          _CollageImageSpec(
            asset: 'assets/images/IMG_1681.jpeg',
            size: secondarySize,
            baseOffset: secondaryOffset,
            layout: layout.second,
          ),
        ]..sort((a, b) => a.layout.zIndex.compareTo(b.layout.zIndex));

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding:
                    EdgeInsets.only(right: textAreaWidth * imageAreaPaddingFactor),
                child: Stack(
                  children: imageWidgets
                      .map(
                        (spec) => _CollageImage(
                          asset: spec.asset,
                          size: spec.size,
                          baseOffset: spec.baseOffset,
                          layout: spec.layout,
                          alignment: spec.alignment,
                          fit: spec.fit,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: textAreaWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: textBlock,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuietCollage extends StatelessWidget {
  const _QuietCollage({
    required this.layout,
    required this.textBlock,
    this.textAreaWidthFactor = 0.36,
    this.imageAreaPaddingFactor = 0.95,
  });

  final _CollageLayout layout;
  final Widget textBlock;
  final double textAreaWidthFactor;
  final double imageAreaPaddingFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textAreaWidth = constraints.maxWidth * textAreaWidthFactor;
        final imageAreaWidth = constraints.maxWidth - textAreaWidth;
        final imageAreaHeight = constraints.maxHeight;

        final primarySize = Size(
          imageAreaWidth * 0.76,
          imageAreaHeight * 0.78,
        );
        final secondarySize = Size(
          imageAreaWidth * 0.7,
          imageAreaHeight * 0.72,
        );

        final primaryOffset = Offset(
          imageAreaWidth * 0.5,
          imageAreaHeight * 0.5,
        );
        final secondaryOffset = Offset(
          imageAreaWidth * 0.02,
          imageAreaHeight * 0.02,
        );

        final imageWidgets = <_CollageImageSpec>[
          _CollageImageSpec(
            asset: 'assets/images/IMG_1683.jpeg',
            size: secondarySize,
            baseOffset: secondaryOffset,
            layout: layout.second,
          ),
          _CollageImageSpec(
            asset: 'assets/images/IMG_1682.jpeg',
            size: primarySize,
            baseOffset: primaryOffset,
            layout: layout.first,
          ),
        ]..sort((a, b) => a.layout.zIndex.compareTo(b.layout.zIndex));

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding:
                    EdgeInsets.only(right: textAreaWidth * imageAreaPaddingFactor),
                child: Stack(
                  children: imageWidgets
                      .map(
                        (spec) => _CollageImage(
                          asset: spec.asset,
                          size: spec.size,
                          baseOffset: spec.baseOffset,
                          layout: spec.layout,
                          alignment: spec.alignment,
                          fit: spec.fit,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: textAreaWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: textBlock,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventCollage extends StatelessWidget {
  const _EventCollage({
    required this.layout,
    required this.isWide,
    required this.title,
  });

  final _CollageLayout layout;
  final bool isWide;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleInset = const EdgeInsets.only(left: 24, bottom: 24);
        final imageAreaWidth = constraints.maxWidth - titleInset.left;
        final imageAreaHeight = constraints.maxHeight - titleInset.bottom;
        final imageAreaSize = Size(imageAreaWidth, imageAreaHeight);

        final primarySize = Size(
          imageAreaWidth * 0.7,
          imageAreaHeight * 0.7,
        );
        const img3803AspectRatio = 2983 / 2237;
        final secondarySize = _containSize(
          img3803AspectRatio,
          imageAreaWidth * 0.68,
          imageAreaHeight * 0.68,
        );

        final primaryOffset = Offset(
          imageAreaWidth * -0.08,
          imageAreaHeight * -0.06,
        );
        final rawSecondaryOffset = Offset(
          imageAreaWidth * 0.54,
          imageAreaHeight * 0.38,
        );

        final secondaryOffset =
            isWide
                ? rawSecondaryOffset
                : _clampOffsetWithin(
                    imageAreaSize,
                    secondarySize,
                    rawSecondaryOffset,
                  );
        final secondaryLayout = isWide
            ? layout.second
            : _CollageImageLayout(
                offset: Offset.zero,
                rotation: 0,
                zIndex: layout.second.zIndex,
              );

        final imageWidgets = <_CollageImageSpec>[
          _CollageImageSpec(
            asset: 'assets/images/event_connecting_green.jpeg',
            size: primarySize,
            baseOffset: primaryOffset,
            layout: layout.first,
          ),
          _CollageImageSpec(
            asset: 'assets/images/IMG_3803.jpeg',
            size: secondarySize,
            baseOffset: secondaryOffset,
            layout: secondaryLayout,
            alignment: Alignment.center,
          ),
        ]..sort((a, b) => a.layout.zIndex.compareTo(b.layout.zIndex));

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: titleInset,
                child: Stack(
                  children: imageWidgets
                      .map(
                        (spec) => _CollageImage(
                          asset: spec.asset,
                          size: spec.size,
                          baseOffset: spec.baseOffset,
                          layout: spec.layout,
                          alignment: spec.alignment,
                          fit: spec.fit,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CollageImageSpec {
  const _CollageImageSpec({
    required this.asset,
    required this.size,
    required this.baseOffset,
    required this.layout,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final Size size;
  final Offset baseOffset;
  final _CollageImageLayout layout;
  final Alignment alignment;
  final BoxFit fit;
}

class _CollageImage extends StatelessWidget {
  const _CollageImage({
    required this.asset,
    required this.size,
    required this.baseOffset,
    required this.layout,
    required this.alignment,
    required this.fit,
  });

  final String asset;
  final Size size;
  final Offset baseOffset;
  final _CollageImageLayout layout;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: baseOffset.dx,
      top: baseOffset.dy,
      child: Transform.translate(
        offset: layout.offset,
        child: _CollageImageFrame(
          asset: asset,
          size: size,
          alignment: alignment,
          fit: fit,
        ),
      ),
    );
  }
}

class _CollageImageFrame extends StatelessWidget {
  const _CollageImageFrame({
    required this.asset,
    required this.size,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final Size size;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        asset,
        width: size.width,
        height: size.height,
        fit: fit,
        alignment: alignment,
      ),
    );
  }
}

class _CollageImageLayout {
  const _CollageImageLayout({
    required this.offset,
    required this.rotation,
    required this.zIndex,
  });

  final Offset offset;
  final double rotation;
  final int zIndex;

  static const zero =
      _CollageImageLayout(offset: Offset.zero, rotation: 0, zIndex: 0);
}

class _CollageLayout {
  const _CollageLayout({
    required this.first,
    required this.second,
  });

  final _CollageImageLayout first;
  final _CollageImageLayout second;

  static const zero =
      _CollageLayout(first: _CollageImageLayout.zero, second: _CollageImageLayout.zero);
}

double _getRandomInRange(Random random, double min, double max) {
  return min + random.nextDouble() * (max - min);
}

Size _containSize(double aspectRatio, double maxWidth, double maxHeight) {
  var width = maxWidth;
  var height = width / aspectRatio;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * aspectRatio;
  }
  return Size(width, height);
}

Offset _clampOffsetWithin(Size areaSize, Size itemSize, Offset desired) {
  final maxX = (areaSize.width - itemSize.width).clamp(0.0, double.infinity);
  final maxY = (areaSize.height - itemSize.height).clamp(0.0, double.infinity);
  final dx = desired.dx.clamp(0.0, maxX).toDouble();
  final dy = desired.dy.clamp(0.0, maxY).toDouble();
  return Offset(dx, dy);
}

_CollageLayout _createCollageLayout() {
  final random = Random();
  final isFirstOnTop = random.nextBool();

  _CollageImageLayout createLayout(int zIndex) {
    return _CollageImageLayout(
      offset: Offset(
        _getRandomInRange(random, -18, 18),
        _getRandomInRange(random, -18, 18),
      ),
      rotation: 0,
      zIndex: zIndex,
    );
  }

  return _CollageLayout(
    first: createLayout(isFirstOnTop ? 2 : 1),
    second: createLayout(isFirstOnTop ? 1 : 2),
  );
}

_CollageLayout _createHandmadeLayout() {
  final random = Random();
  final isFirstOnTop = random.nextBool();

  _CollageImageLayout createLayout(int zIndex) {
    return _CollageImageLayout(
      offset: Offset(
        _getRandomInRange(random, -22, 22),
        _getRandomInRange(random, -14, 14),
      ),
      rotation: 0,
      zIndex: zIndex,
    );
  }

  return _CollageLayout(
    first: createLayout(isFirstOnTop ? 2 : 1),
    second: createLayout(isFirstOnTop ? 1 : 2),
  );
}

_CollageLayout _createQuietLayout() {
  final random = Random();
  final isFirstOnTop = random.nextBool();

  _CollageImageLayout createLayout(int zIndex) {
    return _CollageImageLayout(
      offset: Offset(
        _getRandomInRange(random, -16, 16),
        _getRandomInRange(random, -20, 14),
      ),
      rotation: 0,
      zIndex: zIndex,
    );
  }

  return _CollageLayout(
    first: createLayout(isFirstOnTop ? 2 : 1),
    second: createLayout(isFirstOnTop ? 1 : 2),
  );
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({
    required this.imageAsset,
    this.width,
    this.height,
    this.hasRadius = true,
  });

  final String imageAsset;
  final double? width;
  final double? height;
  final bool hasRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      imageAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );

    if (!hasRadius) {
      return image;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: image,
    );
  }
}

class _StoreInfoSectionView extends StatelessWidget {
  const _StoreInfoSectionView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onPrimary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 860;

        final storeInfo = _StoreInfoPlain(theme: theme);

        return DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.primary),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('店舗情報', style: titleStyle),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: storeInfo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoreInfoPlain extends StatelessWidget {
  const _StoreInfoPlain({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.8,
      color: theme.colorScheme.onPrimary,
    );
    final subStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Antenna Books & Cafe ココシバ',
          style: subStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text('住所：$storeAddress', style: textStyle, textAlign: TextAlign.center),
        Text(
          '営業時間：$storeBusinessHours',
          style: textStyle,
          textAlign: TextAlign.center,
        ),
        Text('TEL：$storePhoneNumber', style: textStyle, textAlign: TextAlign.center),
        Text(
          'MAIL：$storeEmailAddress',
          style: textStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => launchUrl(
                storeInstagramUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(
                Icons.camera_alt_outlined,
                color: theme.colorScheme.onPrimary,
              ),
              tooltip: 'Instagram',
            ),
            IconButton(
              onPressed: () => launchUrl(
                storeFacebookUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(
                Icons.facebook_outlined,
                color: theme.colorScheme.onPrimary,
              ),
              tooltip: 'Facebook',
            ),
            IconButton(
              onPressed: () => launchUrl(
                storeXUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(
                Icons.alternate_email,
                color: theme.colorScheme.onPrimary,
              ),
              tooltip: 'X',
            ),
          ],
        ),
      ],
    );
  }
}

class _StoryScrollBehavior extends MaterialScrollBehavior {
  const _StoryScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
      };
}
