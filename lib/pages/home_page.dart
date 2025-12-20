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
      imageAsset: 'assets/images/IMG_0038.jpeg',
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
      imageAsset: 'assets/images/IMG_2363.jpeg',
    ),
    _StorySection(
      title: 'アートとやさしい時間',
      subtitle: '音・言葉・表現',
      body:
          'アーティストの表現が、日常に彩りを添えます。\n'
          '気軽に立ち寄れる文化の場所。',
      imageAsset: 'assets/images/IMG_1385.jpeg',
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
  });

  final String title;
  final String subtitle;
  final String body;
  final String imageAsset;
  final bool isHero;
  final _StoryLayout layout;
}

enum _StoryLayout {
  standard,
  eventHighlight,
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

        final isWide = constraints.maxWidth >= 880;
        final imageWidth = isWide ? constraints.maxWidth * 0.52 : null;
        final imageHeight = isWide
            ? (constraints.maxHeight * 0.7).clamp(320.0, 520.0)
            : (constraints.maxWidth * 0.62).clamp(280.0, 520.0);

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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: isWide
                ? Row(
                    children: [
                      Expanded(child: textBlock),
                      const SizedBox(width: 32),
                      _StoryImage(
                        imageAsset: section.imageAsset,
                        width: imageWidth,
                        height: imageHeight,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StoryImage(
                        imageAsset: section.imageAsset,
                        height: imageHeight,
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

        final textBlock = _EventBodyText(
          section: widget.section,
          textColor: textColor,
          maxWidth: isWide ? constraints.maxWidth * 0.7 : constraints.maxWidth,
        );

        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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

class _EventBodyText extends StatelessWidget {
  const _EventBodyText({
    required this.section,
    required this.textColor,
    required this.maxWidth,
  });

  final _StorySection section;
  final Color textColor;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints:
          maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : const BoxConstraints(),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                section.title,
                textAlign: TextAlign.left,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                section.body,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
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

        final primarySize = Size(
          imageAreaWidth * 0.7,
          imageAreaHeight * 0.7,
        );
        final secondarySize = Size(
          imageAreaWidth * 0.68,
          imageAreaHeight * 0.68,
        );

        final primaryOffset = Offset(
          imageAreaWidth * -0.08,
          imageAreaHeight * -0.06,
        );
        final secondaryOffset = Offset(
          imageAreaWidth * 0.54,
          imageAreaHeight * 0.38,
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
            layout: layout.second,
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
  });

  final String asset;
  final Size size;
  final Offset baseOffset;
  final _CollageImageLayout layout;
}

class _CollageImage extends StatelessWidget {
  const _CollageImage({
    required this.asset,
    required this.size,
    required this.baseOffset,
    required this.layout,
  });

  final String asset;
  final Size size;
  final Offset baseOffset;
  final _CollageImageLayout layout;

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
        ),
      ),
    );
  }
}

class _CollageImageFrame extends StatelessWidget {
  const _CollageImageFrame({
    required this.asset,
    required this.size,
  });

  final String asset;
  final Size size;

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
        fit: BoxFit.cover,
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

class _StoryImage extends StatelessWidget {
  const _StoryImage({
    required this.imageAsset,
    this.width,
    this.height,
  });

  final String imageAsset;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        imageAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
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
