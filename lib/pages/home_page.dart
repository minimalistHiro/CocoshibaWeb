import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cocoshibaweb/app.dart';
import 'package:cocoshibaweb/models/calendar_event.dart';
import 'package:cocoshibaweb/services/event_service.dart';
import 'package:cocoshibaweb/widgets/cocoshiba_network_image.dart';
import 'package:cocoshibaweb/widgets/store_info_card.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cocoshibaweb/router.dart';
import 'package:cocoshibaweb/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  late final AnimationController _introController;
  late final Animation<double> _introOpacity;
  late final Animation<double> _introScale;
  OverlayEntry? _introOverlay;
  EventService? _eventService;
  late Stream<List<CalendarEvent>> _recentEventsStream;
  late bool _firebaseReady;

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
          '人と人が交わる時間。\n'
          '小さな挑戦を後押しするイベントを開催しています。',
      imageAsset: 'assets/images/IMG_5959.jpeg',
      layout: _StoryLayout.eventHighlight,
    ),
    _StorySection(
      title: '直近のイベント',
      subtitle: 'Upcoming Events',
      body: '近日開催のイベントをご紹介します。',
      imageAsset: 'assets/images/IMG_1385.jpeg',
      layout: _StoryLayout.recentEvents,
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
      title: '本 × イベント × カフェ',
      subtitle: '日常に彩りを添える場所',
      body:
          '人々の交流が日常に彩りを添えます。\n'
          '気軽に立ち寄れる文化の場所。',
      imageAsset: 'assets/images/IMG_1385.jpeg',
      hasImageRadius: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _firebaseReady = Firebase.apps.isNotEmpty;
    _recentEventsStream = _createRecentEventsStream();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    );
    _introOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 2000,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 600,
      ),
    ]).animate(_introController);
    _introScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 1000,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 600,
      ),
    ]).animate(_introController);
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeIntroOverlay();
      }
    });
    _introController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroOverlay();
      precacheImage(
        const AssetImage('assets/images/ココシバロゴ_w.PNG'),
        context,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _introController.dispose();
    _removeIntroOverlay();
    super.dispose();
  }

  void _showIntroOverlay() {
    if (_introOverlay != null || !mounted) {
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _introOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: _IntroSplash(
            opacity: _introOpacity,
            scale: _introScale,
          ),
        ),
      ),
    );
    overlay.insert(_introOverlay!);
  }

  void _removeIntroOverlay() {
    _introOverlay?.remove();
    _introOverlay = null;
  }

  Stream<List<CalendarEvent>> _createRecentEventsStream() {
    if (!_firebaseReady) {
      return Stream.value(const <CalendarEvent>[]);
    }
    _eventService ??= EventService();
    return _eventService!.watchUpcomingActiveEvents(limit: 30).map(
          (events) => events.take(7).toList(growable: false),
        );
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
                      : _StorySectionView(
                          section: _sections[index],
                          recentEventsStream: _recentEventsStream,
                          firebaseReady: _firebaseReady,
                          eventService: _eventService ?? EventService(),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _IntroSplash extends StatelessWidget {
  const _IntroSplash({
    required this.opacity,
    required this.scale,
  });

  final Animation<double> opacity;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: cocoshibaMainColor),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWidth =
                (constraints.maxWidth * 0.45).clamp(160.0, 280.0);
            final textWidth =
                (constraints.maxWidth * 0.8).clamp(240.0, 520.0);
            final dpr = MediaQuery.of(context).devicePixelRatio;
            final logoCacheWidth = (logoWidth * dpr).round();

            return Center(
              child: ScaleTransition(
                scale: scale,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: textWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ココシバロゴ_w.PNG',
                        width: logoWidth,
                        fit: BoxFit.contain,
                        cacheWidth: logoCacheWidth,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
  recentEvents,
  handmadeHighlight,
  quietHighlight,
}

class _StorySectionView extends StatelessWidget {
  const _StorySectionView({
    required this.section,
    required this.recentEventsStream,
    required this.firebaseReady,
    required this.eventService,
  });

  final _StorySection section;
  final Stream<List<CalendarEvent>> recentEventsStream;
  final bool firebaseReady;
  final EventService eventService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = section.isHero ? Colors.white : theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (section.isHero) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final heroCacheWidth = (constraints.maxWidth * dpr).round();
          final heroCacheHeight = (constraints.maxHeight * dpr).round();
          return SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  section.imageAsset,
                  fit: BoxFit.cover,
                  cacheWidth: heroCacheWidth,
                  cacheHeight: heroCacheHeight,
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
          return _EventHighlightSectionView(
            section: section,
          );
        }

        if (section.layout == _StoryLayout.recentEvents) {
          return _RecentEventsSectionView(
            recentEventsStream: recentEventsStream,
            eventService: eventService,
            firebaseReady: firebaseReady,
          );
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
  const _EventHighlightSectionView({
    required this.section,
  });

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
                      child: _EventCollage(
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
                          child: _EventCollage(
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
          scaleWithWidth: !isWide,
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
                        alignment: Alignment.centerRight,
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

class _RecentEventsSectionView extends StatelessWidget {
  const _RecentEventsSectionView({
    required this.recentEventsStream,
    required this.eventService,
    required this.firebaseReady,
  });

  final Stream<List<CalendarEvent>> recentEventsStream;
  final EventService eventService;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 880;
        final sectionPadding = isWide
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
        final contentMaxWidth =
            isWide ? min(constraints.maxWidth * 0.86, 920.0) : constraints.maxWidth;
        const sectionGap = 12.0;

        return SizedBox.expand(
          child: Padding(
            padding: sectionPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReservedEventsContent(
                      textColor: textColor,
                      availableWidth: contentMaxWidth,
                      eventService: eventService,
                      firebaseReady: firebaseReady,
                    ),
                    const SizedBox(height: sectionGap),
                    _RecentEventsSection(
                      color: textColor,
                      availableWidth: contentMaxWidth,
                      eventsStream: recentEventsStream,
                      firebaseReady: firebaseReady,
                    ),
                    const SizedBox(height: sectionGap),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ViewMoreButton(
                        color: textColor,
                        compact: contentMaxWidth >= _EventBodyText._viewMoreCompactWidth,
                        onTap: () => context.go(CocoshibaPaths.events),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReservedEventsContent extends StatelessWidget {
  const _ReservedEventsContent({
    required this.textColor,
    required this.availableWidth,
    required this.eventService,
    required this.firebaseReady,
  });

  final Color textColor;
  final double availableWidth;
  final EventService eventService;
  final bool firebaseReady;

  Stream<List<CalendarEvent>> _reservedStreamFor(AuthUser user) {
    return eventService
        .watchReservedEvents(user.uid)
        .map((events) => events.take(7).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;

    return StreamBuilder<AuthUser?>(
      stream: auth.onAuthStateChanged,
      builder: (context, snapshot) {
        final user = snapshot.data ?? auth.currentUser;
        if (user == null) {
          return _ReservedEventsLoginPrompt(
            textColor: textColor,
          );
        }
        return _RecentEventsSection(
          color: textColor,
          availableWidth: availableWidth,
          eventsStream: _reservedStreamFor(user),
          firebaseReady: firebaseReady,
          title: '予約したイベント',
          emptyMessage: '予約したイベントはまだありません',
          showScheduleButton: false,
        );
      },
    );
  }
}

class _ReservedEventsLoginPrompt extends StatelessWidget {
  const _ReservedEventsLoginPrompt({
    required this.textColor,
  });

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('予約したイベント', style: titleStyle),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: SizedBox(
            height: _EventBodyText._recentEventCardHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ログインして予約したイベントを確認しましょう',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go(CocoshibaPaths.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cocoshibaMainColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ログイン'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventBodyText extends StatelessWidget {
  const _EventBodyText({
    required this.section,
    required this.textColor,
    required this.maxWidth,
    this.scaleWithWidth = true,
    this.expandToMaxWidth = false,
  });

  static const double _viewMoreCompactWidth = 560;
  static const double _recentEventCompactWidth = 640;
  static const double _recentEventCardHeight = 188;
  static const double _recentEventImageHeight = 118;

  final _StorySection section;
  final Color textColor;
  final double? maxWidth;
  final bool scaleWithWidth;
  final bool expandToMaxWidth;
  static bool shouldShowViewMore(_StorySection section) =>
      section.subtitle == 'ボードゲーム会やLIVE';

  static double _recentEventCardWidth(double availableWidth) {
    if (availableWidth < _recentEventCompactWidth) {
      return 168;
    }
    return 204;
  }

  static double estimateHeight({
    required BuildContext context,
    required _StorySection section,
    required double maxWidth,
    required bool scaleWithWidth,
    required double availableWidth,
  }) {
    if (maxWidth <= 0) {
      return 0;
    }
    final theme = Theme.of(context);
    const scaledSubtitles = [
      'ふらっと立ち寄れる読書席',
      'ボードゲーム会やLIVE',
      'ハンドメイド・スローマーケット',
    ];
    final isScaledSection = scaledSubtitles.contains(section.subtitle);
    final textScale = isScaledSection && scaleWithWidth
        ? (maxWidth / 600).clamp(0.64, 1.0)
        : 1.0;
    final scaledMaxWidth =
        isScaledSection ? maxWidth * textScale : maxWidth;
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      fontSize: theme.textTheme.titleMedium?.fontSize != null
          ? theme.textTheme.titleMedium!.fontSize! * textScale
          : null,
    );
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.3,
      fontSize: theme.textTheme.headlineSmall?.fontSize != null
          ? theme.textTheme.headlineSmall!.fontSize! * textScale
          : null,
    );
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.8,
      fontSize: theme.textTheme.bodyLarge?.fontSize != null
          ? theme.textTheme.bodyLarge!.fontSize! * textScale
          : null,
    );

    double measureTextHeight(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: scaledMaxWidth);
      return painter.height;
    }

    var height = 40.0;
    height += measureTextHeight(section.subtitle, subtitleStyle);
    height += 12;
    height += measureTextHeight(section.title, titleStyle);
    height += 12;
    height += measureTextHeight(section.body, bodyStyle);

    if (shouldShowViewMore(section)) {
      final isCompactViewMore = availableWidth >= _viewMoreCompactWidth;
      final viewMorePadding = isCompactViewMore ? 4.0 : 12.0;
      final viewMoreGap = isCompactViewMore ? 6.0 : 8.0;
      final underlineHeight = isCompactViewMore ? 8.0 : 12.0;
      final preSpacing = isCompactViewMore ? 12.0 : 18.0;
      final viewMoreStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 4,
      );
      final viewMoreHeight = measureTextHeight('VIEW MORE', viewMoreStyle);
      height += preSpacing;
      height += viewMorePadding + viewMoreHeight + viewMoreGap + underlineHeight;
    }

    return height;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const scaledSubtitles = [
      'ふらっと立ち寄れる読書席',
      'ボードゲーム会やLIVE',
      'ハンドメイド・スローマーケット',
    ];
    final isScaledSection = scaledSubtitles.contains(section.subtitle);
    final showViewMore = shouldShowViewMore(section);
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
        final isCompactViewMore = availableWidth >= _viewMoreCompactWidth;
        final textScale = isScaledSection && scaleWithWidth
            ? (availableWidth / 600).clamp(0.64, 1.0)
            : 1.0;
        final scaledMaxWidth =
            isScaledSection ? baseMaxWidth * textScale : baseMaxWidth;
        final titleStyle = theme.textTheme.headlineSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1.3,
        );
        final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
          color: textColor,
          height: 1.8,
        );

        final card = DecoratedBox(
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
                if (showViewMore) ...[
                  SizedBox(height: isCompactViewMore ? 12 : 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ViewMoreButton(
                      color: textColor,
                      compact: isCompactViewMore,
                      onTap: () => context.go(CocoshibaPaths.events),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        final effectiveMaxWidth =
            expandToMaxWidth ? availableWidth : scaledMaxWidth;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: SizedBox(
            width: expandToMaxWidth ? availableWidth : null,
            child: card,
          ),
        );
      },
    );
  }
}

class _RecentEventsSection extends StatelessWidget {
  const _RecentEventsSection({
    required this.color,
    required this.availableWidth,
    required this.eventsStream,
    required this.firebaseReady,
    this.title = '直近のイベント',
    this.emptyMessage = '直近のイベントがありません',
    this.showScheduleButton = true,
    this.scheduleButtonLabel = 'イベントスケジュールはこちら',
    this.onSchedulePressed,
  });

  final Color color;
  final double availableWidth;
  final Stream<List<CalendarEvent>> eventsStream;
  final bool firebaseReady;
  final String title;
  final String emptyMessage;
  final bool showScheduleButton;
  final String scheduleButtonLabel;
  final VoidCallback? onSchedulePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = _EventBodyText._recentEventCardWidth(availableWidth);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: SizedBox(
            height: _EventBodyText._recentEventCardHeight,
            child: firebaseReady
                ? StreamBuilder<List<CalendarEvent>>(
                    stream: eventsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'イベントの取得に失敗しました',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                            ),
                          ),
                        );
                      }
                      final events = snapshot.data ?? const <CalendarEvent>[];
                      if (events.isEmpty) {
                        return Center(
                          child: Text(
                            emptyMessage,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                            ),
                          ),
                        );
                      }
                      return ScrollConfiguration(
                        behavior: const _StoryScrollBehavior(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: events
                                .map(
                                  (event) => Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _RecentEventCard(
                                      event: event,
                                      width: cardWidth,
                                      color: color,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'Firebase が初期化されていないため、イベント情報は表示できません。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
        if (showScheduleButton) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed:
                  onSchedulePressed ?? () => context.go(CocoshibaPaths.calendar),
              style: ElevatedButton.styleFrom(
                backgroundColor: cocoshibaMainColor,
                foregroundColor: Colors.white,
              ),
              child: Text(scheduleButtonLabel),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentEventCard extends StatelessWidget {
  const _RecentEventCard({
    required this.event,
    required this.width,
    required this.color,
  });

  final CalendarEvent event;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStyle = theme.textTheme.labelMedium?.copyWith(
      color: color.withOpacity(0.7),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
    final hasImage = event.imageUrls.isNotEmpty;

    Widget buildImage() {
      final placeholder = Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 32,
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

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width,
                height: _EventBodyText._recentEventImageHeight,
                child: buildImage(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatEventDate(event.startDateTime),
                        style: dateStyle),
                    const SizedBox(height: 4),
                    Text(
                      event.name,
                      style: titleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatEventDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}

class _ViewMoreButton extends StatelessWidget {
  const _ViewMoreButton({
    required this.color,
    this.compact = false,
    required this.onTap,
  });

  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: 4,
    );

    final textLineGap = compact ? 6.0 : 8.0;
    final underlineHeight = compact ? 8.0 : 12.0;
    final verticalPadding = compact ? 2.0 : 6.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('VIEW MORE', style: textStyle),
              SizedBox(height: textLineGap),
              CustomPaint(
                size: Size(180, underlineHeight),
                painter: _ViewMoreLinePainter(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewMoreLinePainter extends CustomPainter {
  const _ViewMoreLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    final endX = size.width - 14;
    final baseY = size.height;
    canvas.drawLine(Offset(0, baseY), Offset(endX, baseY), paint);
    canvas.drawLine(Offset(endX, baseY), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewMoreLinePainter oldDelegate) =>
      oldDelegate.color != color;
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
            layout: _CollageImageLayout(
              offset: layout.first.offset,
              rotation: layout.first.rotation,
              zIndex: 1,
            ),
          ),
          _CollageImageSpec(
            asset: 'assets/images/IMG_1681.jpeg',
            size: secondarySize,
            baseOffset: secondaryOffset,
            layout: _CollageImageLayout(
              offset: layout.second.offset,
              rotation: layout.second.rotation,
              zIndex: 2,
            ),
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
          imageAreaHeight * 0.76,
        );
        final secondarySize = Size(
          imageAreaWidth * 0.7,
          imageAreaHeight * 0.72,
        );

        final primaryOffset = Offset(
          imageAreaWidth * 0.5,
          imageAreaHeight * 0.38,
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
            layout: _CollageImageLayout(
              offset: layout.second.offset,
              rotation: layout.second.rotation,
              zIndex: 1,
            ),
          ),
          _CollageImageSpec(
            asset: 'assets/images/IMG_1682.jpeg',
            size: primarySize,
            baseOffset: primaryOffset,
            layout: _CollageImageLayout(
              offset: layout.first.offset,
              rotation: layout.first.rotation,
              zIndex: 2,
            ),
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
          imageAreaHeight * 0.76,
        );
        final secondarySize = Size(
          imageAreaWidth * 0.7,
          imageAreaHeight * 0.72,
        );

        final primaryOffset = Offset(
          imageAreaWidth * 0.5,
          imageAreaHeight * 0.38,
        );
        final secondaryOffset = Offset(
          imageAreaWidth * 0.02,
          imageAreaHeight * 0.02,
        );

        final imageWidgets = <_CollageImageSpec>[
          _CollageImageSpec(
            asset: 'assets/images/IMG_5959.jpeg',
            size: secondarySize,
            baseOffset: secondaryOffset,
            layout: _CollageImageLayout(
              offset: layout.second.offset,
              rotation: layout.second.rotation,
              zIndex: 1,
            ),
            alignment: Alignment.center,
          ),
          _CollageImageSpec(
            asset: 'assets/images/IMG_3803.jpeg',
            size: primarySize,
            baseOffset: primaryOffset,
            layout: _CollageImageLayout(
              offset: layout.first.offset,
              rotation: layout.first.rotation,
              zIndex: 2,
            ),
            alignment: Alignment.center,
          ),
        ]..sort((a, b) => a.layout.zIndex.compareTo(b.layout.zIndex));

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  right: textAreaWidth * imageAreaPaddingFactor,
                ),
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
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (size.width * dpr).round();

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
        cacheWidth: cacheWidth,
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
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = width != null ? (width! * dpr).round() : null;
    final cacheHeight = height != null ? (height! * dpr).round() : null;
    final image = Image.asset(
      imageAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
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
              icon: Image.asset(
                'assets/images/Instagram.png',
                width: 28,
                height: 28,
              ),
              tooltip: 'Instagram',
            ),
            IconButton(
              onPressed: () => launchUrl(
                storeFacebookUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: Image.asset(
                'assets/images/facebook.png',
                width: 28,
                height: 28,
              ),
              tooltip: 'Facebook',
            ),
            IconButton(
              onPressed: () => launchUrl(
                storeXUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: Image.asset(
                'assets/images/X.png',
                width: 28,
                height: 28,
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
