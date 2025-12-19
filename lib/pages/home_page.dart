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
      title: 'イベントがつなぐ縁',
      subtitle: 'ボードゲーム会やLIVE',
      body:
          '人と人が交わる夜。\n'
          '小さな挑戦を後押しするイベントを開催しています。',
      imageAsset: 'assets/images/IMG_3803.jpeg',
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
  });

  final String title;
  final String subtitle;
  final String body;
  final String imageAsset;
  final bool isHero;
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
      color: theme.colorScheme.primary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 860;

        final storeInfo = _StoreInfoPlain(theme: theme);

        return SizedBox.expand(
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
      color: theme.colorScheme.primary,
    );
    final subStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
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
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Instagram',
            ),
            IconButton(
              onPressed: () => launchUrl(
                storeFacebookUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.facebook_outlined),
              tooltip: 'Facebook',
            ),
            IconButton(
              onPressed: () => launchUrl(
                storeXUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.alternate_email),
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
