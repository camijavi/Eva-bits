import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/responsive.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../widgets/eve_animated_avatar.dart';
import 'dashboard_screen.dart';
import 'new_farm_info_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool checkExisting;

  const WelcomeScreen({
    super.key,
    this.checkExisting = true,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isCheckingExisting = true;
  int _currentPage = 0;
  late final PageController _pageController;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.checkExisting) {
      _checkExistingFarm();
    } else {
      _isCheckingExisting = false;
      _startCarouselTimer();
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _checkExistingFarm() async {
    try {
      final existingFarm = await DatabaseManager().getLatestFarm();
      if (existingFarm != null && mounted) {
        final farmName = existingFarm['name']?.toString();
        final country = existingFarm['country']?.toString();
        final surface = existingFarm['total_surface']?.toString();
        final unit = existingFarm['surface_unit']?.toString() ?? 'ha';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  farmName: farmName,
                  location: country,
                  surface: surface != null ? '$surface $unit' : null,
                ),
              ),
            );
          }
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isCheckingExisting = false;
      });
      _startCarouselTimer();
    }
  }

  void _onGetStartedPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FarmInfoScreen(checkExisting: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (_isCheckingExisting) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final isSpanish = AppLanguage.isSpanish;

        final headline = isSpanish
            ? '¡Te damos la bienvenida\na Eva Bits!'
            : 'Welcome\nto Eva Bits!';

        final subtitle = isSpanish
            ? 'Tu asistente agroecológico. Te guiaré paso a paso para cuidar tu suelo, planificar cultivos y tomar decisiones inteligentes con datos satelitales.'
            : 'Your agroecological assistant. I will guide you step by step to care for your soil, plan crops, and make smart decisions with satellite data.';

        final buttonText = isSpanish ? 'Comenzar' : 'Get Started';

        final featureItems = [
          _WelcomeFeature(
            icon: Icons.satellite_alt_rounded,
            iconColor: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
            iconBgColor: isDark ? const Color(0xFF10283A) : const Color(0xFFE3F2FD),
            title: isSpanish
                ? 'Observaciones Satelitales'
                : 'Satellite Observations',
            description: isSpanish
                ? 'Monitoreo en tiempo real de radiación, lluvia y humedad de la NASA'
                : 'Real-time monitoring of radiation, rainfall, and moisture from NASA',
          ),
          _WelcomeFeature(
            icon: Icons.eco_rounded,
            iconColor: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
            iconBgColor: isDark ? const Color(0xFF1B3322) : const Color(0xFFE8F5E9),
            title: isSpanish
                ? 'Manejo Agroecológico'
                : 'Agroecological Management',
            description: isSpanish
                ? 'Rotación de cultivos, fijación de nitrógeno y salud del suelo'
                : 'Crop rotation, biological nitrogen fixation, and soil health',
          ),
          _WelcomeFeature(
            icon: Icons.smart_toy_rounded,
            iconColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
            iconBgColor: isDark ? const Color(0xFF332010) : const Color(0xFFFFF3E0),
            title: isSpanish
                ? 'Asistencia con Eve'
                : 'Smart AI Guidance with Eve',
            description: isSpanish
                ? 'Recomendaciones personalizadas y respuestas de Eve en tiempo real'
                : 'Tailored recommendations and continuous field advice from Eve',
          ),
        ];

        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
          child: Scaffold(
            backgroundColor: AppColors.getBackground(context),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final responsive = Responsive(context, constraints);
                  final isTablet = responsive.isTabletOrDesktop;
                  final isShort = responsive.isShort;
                  final isNarrow = responsive.isSmallMobile;
                  final isLandscape = responsive.isLandscape;

                  final textScaler = MediaQuery.textScalerOf(context);

                  // Responsive carousel height (ample vertical room on tablet)
                  final carouselHeight = isTablet
                      ? (158.0 * textScaler.scale(1.0)).clamp(152.0, 200.0)
                      : (98.0 * textScaler.scale(1.0)).clamp(96.0, 134.0);

                  // Comfortable tablet paddings that allow content to use tablet width
                  final horizontalPadding = isNarrow
                      ? 14.0
                      : (isTablet ? (isLandscape ? 36.0 : 28.0) : 20.0);
                  final verticalPadding =
                      isShort ? 8.0 : (isTablet ? 18.0 : 12.0);

                  // Max content width: on tablet, allow full utilization up to 940px
                  final maxContentWidth = isTablet
                      ? (isLandscape ? 880.0 : 940.0)
                      : 540.0;

                  // Calculate stage size
                  final stageWidth = _calculateStageWidth(
                    isTablet: isTablet,
                    isLandscape: isLandscape,
                    isShort: isShort,
                    availableWidth: constraints.maxWidth,
                    availableHeight: constraints.maxHeight,
                  );
                  final stageHeight = stageWidth * (260.0 / 280.0);

                  // Base gap measurements
                  final baseGapTopBar =
                      isTablet ? 24.0 : (isShort ? 10.0 : 16.0);
                  final baseGapStage =
                      isTablet ? 28.0 : (isShort ? 14.0 : 20.0);
                  final baseGapHeadline =
                      isTablet ? 12.0 : (isShort ? 8.0 : 10.0);
                  final baseGapSubtitle =
                      isTablet ? 26.0 : (isShort ? 14.0 : 20.0);
                  final baseGapCarousel = isTablet ? 16.0 : 10.0;
                  final baseGapDots =
                      isTablet ? 36.0 : (isShort ? 16.0 : 22.0);
                  final bottomMargin = isTablet ? 24.0 : 14.0;

                  // Estimated height of content
                  final topBarEstH = isTablet ? 56.0 : 42.0;
                  final headlineEstH = isTablet ? 104.0 : 64.0;
                  final subtitleEstH = isTablet ? 66.0 : 46.0;
                  final dotsEstH = isTablet ? 13.0 : 8.0;
                  final buttonEstH = isTablet ? 70.0 : 52.0;

                  final totalFixedH = topBarEstH +
                      stageHeight +
                      headlineEstH +
                      subtitleEstH +
                      carouselHeight +
                      dotsEstH +
                      buttonEstH +
                      baseGapTopBar +
                      baseGapStage +
                      baseGapHeadline +
                      baseGapSubtitle +
                      baseGapCarousel +
                      baseGapDots +
                      bottomMargin +
                      (verticalPadding * 2);

                  // Distribute spare height so button anchors to bottom on tablets
                  final spareHeight = (!isLandscape &&
                          constraints.maxHeight > totalFixedH)
                      ? (constraints.maxHeight - totalFixedH)
                      : 0.0;

                  final extraTop = (spareHeight * 0.12).clamp(0.0, 24.0);
                  final extraStage = (spareHeight * 0.16).clamp(0.0, 32.0);
                  final extraSubtitle = (spareHeight * 0.14).clamp(0.0, 28.0);
                  final extraBeforeButton =
                      (spareHeight * 0.58).clamp(0.0, 240.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxContentWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Bar: Decorative App Brand Pill on left, Language on right
                              _buildTopBar(
                                context: context,
                                isDark: isDark,
                                isNarrow: isNarrow,
                                isTablet: isTablet,
                                isSpanish: isSpanish,
                              ),
                              SizedBox(height: baseGapTopBar + extraTop),

                              // Eve Decorated Stage (Grand, prominent and animated)
                              _buildEveDecoratedStage(
                                stageWidth: stageWidth,
                                stageHeight: stageHeight,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: baseGapStage + extraStage),

                              // Headline Title
                              Text(
                                headline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? 44.0
                                      : (isShort || isNarrow ? 23.0 : 26.0),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getTextPrimary(context),
                                  height: 1.16,
                                  letterSpacing: isTablet ? -0.5 : -0.4,
                                ),
                              ),
                              SizedBox(height: baseGapHeadline),

                              // Subtitle
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 720 : double.infinity,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 8.0 : 4.0,
                                  ),
                                  child: Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? 19.5
                                          : (isShort || isNarrow
                                              ? 13.0
                                              : 14.0),
                                      color:
                                          AppColors.getTextSecondary(context),
                                      height: 1.48,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: baseGapSubtitle + extraSubtitle),

                              // Feature Card Carousel (Expanded width and height on tablet)
                              _buildFeatureCarousel(
                                context: context,
                                isDark: isDark,
                                isTablet: isTablet,
                                carouselHeight: carouselHeight,
                                featureItems: featureItems,
                              ),
                              SizedBox(height: baseGapCarousel),

                              // Page Indicator Dots
                              _buildDots(
                                isDark: isDark,
                                isTablet: isTablet,
                                count: featureItems.length,
                              ),
                              SizedBox(height: baseGapDots + extraBeforeButton),

                              // Bottom CTA Pill Button (Anchored near bottom, spans comfortably)
                              _buildCtaButton(
                                buttonText: buttonText,
                                isTablet: isTablet,
                                isNarrow: isNarrow,
                              ),
                              SizedBox(height: bottomMargin),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateStageWidth({
    required bool isTablet,
    required bool isLandscape,
    required bool isShort,
    required double availableWidth,
    required double availableHeight,
  }) {
    if (isTablet) {
      if (isLandscape || isShort) {
        return (availableHeight * 0.40).clamp(240.0, 310.0);
      } else {
        // Generous, majestic stage on tablet portrait that utilizes tablet screen width
        return (availableWidth * 0.62).clamp(400.0, 520.0);
      }
    } else {
      final maxStageW = isShort ? 230.0 : 280.0;
      return (availableWidth * 0.74).clamp(190.0, maxStageW);
    }
  }

  Widget _buildTopBar({
    required BuildContext context,
    required bool isDark,
    required bool isNarrow,
    required bool isTablet,
    required bool isSpanish,
  }) {
    final pillPadding = EdgeInsets.symmetric(
      horizontal: isTablet ? 22.0 : (isNarrow ? 10.0 : 12.0),
      vertical: isTablet ? 11.0 : (isNarrow ? 5.0 : 6.0),
    );
    final brandIconSize = isTablet ? 22.0 : (isNarrow ? 14.0 : 15.0);
    final brandFontSize = isTablet ? 16.5 : (isNarrow ? 11.5 : 12.5);
    final langIconSize = isTablet ? 22.0 : (isNarrow ? 15.0 : 16.0);
    final langFontSize = isTablet ? 16.5 : (isNarrow ? 12.0 : 13.0);
    final borderRadius = isTablet ? 28.0 : 20.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: pillPadding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3024) : const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color:
                  isDark ? const Color(0xFF2E4E39) : const Color(0xFFC8E6C9),
              width: isTablet ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco_rounded,
                size: brandIconSize,
                color:
                    isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              ),
              SizedBox(width: isTablet ? 8 : 5),
              Text(
                'Eva Bits',
                style: TextStyle(
                  fontSize: brandFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF81C784)
                      : const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: AppLanguage.toggleLanguage,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 22.0 : (isNarrow ? 10.0 : 13.0),
              vertical: isTablet ? 11.0 : (isNarrow ? 5.0 : 6.0),
            ),
            decoration: BoxDecoration(
              color: AppColors.getCardBg(context),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.getBorder(context),
                width: isTablet ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: isTablet ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: langIconSize,
                  color: isDark
                      ? const Color(0xFF81C784)
                      : const Color(0xFF2E7D32),
                ),
                SizedBox(width: isTablet ? 8 : 5),
                Text(
                  isSpanish ? 'Español' : 'English',
                  style: TextStyle(
                    fontSize: langFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEveDecoratedStage({
    required double stageWidth,
    required double stageHeight,
    required bool isTablet,
  }) {
    final isDark = AppColors.isDark(context);
    final scale = stageWidth / 280.0;
    final maxAvatarSize = isTablet ? 395.0 : 225.0;
    final avatarSize = (215.0 * scale).clamp(150.0, maxAvatarSize);

    return Center(
      child: SizedBox(
        width: stageWidth,
        height: stageHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft Outer Ambient Glow Ring
            Container(
              width: 265 * scale,
              height: 250 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark
                        ? const Color(0xFF1E3024)
                        : const Color(0xFFE8F5E9))
                    .withValues(alpha: 0.35),
              ),
            ),

            // Main Soft Pastel Organic Backdrop
            Container(
              width: 245 * scale,
              height: 235 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(120 * scale),
                  topRight: Radius.circular(100 * scale),
                  bottomLeft: Radius.circular(110 * scale),
                  bottomRight: Radius.circular(130 * scale),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF1E2E23),
                          Color(0xFF263D2E),
                          Color(0xFF1A291F),
                        ]
                      : const [
                          Color(0xFFE0F2E9),
                          Color(0xFFFFF9C4),
                          Color(0xFFE8F5E9),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark
                            ? const Color(0xFF101913)
                            : const Color(0xFFC8E6C9))
                        .withValues(alpha: 0.45),
                    blurRadius: 26 * scale,
                    spreadRadius: 4 * scale,
                  ),
                ],
              ),
            ),

            // Decorative Floating Badge 1: Top-Left (Sun / Climate)
            Positioned(
              top: 6 * scale,
              left: 8 * scale,
              child: _buildDecorativeOrb(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFFA000),
                bgColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFECB3),
                size: 36 * scale,
              ),
            ),

            // Decorative Floating Badge 2: Top-Right (Leaf / Agroecology)
            Positioned(
              top: 12 * scale,
              right: 10 * scale,
              child: _buildDecorativeOrb(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
                size: 34 * scale,
              ),
            ),

            // Decorative Floating Badge 3: Mid-Left (Water / Irrigation)
            Positioned(
              bottom: 44 * scale,
              left: 2 * scale,
              child: _buildDecorativeOrb(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF1976D2),
                bgColor: const Color(0xFFE3F2FD),
                borderColor: const Color(0xFFBBDEFB),
                size: 32 * scale,
              ),
            ),

            // Decorative Floating Badge 4: Mid-Right (Satellite Earth Sensor)
            Positioned(
              bottom: 50 * scale,
              right: 4 * scale,
              child: _buildDecorativeOrb(
                icon: Icons.satellite_alt_rounded,
                iconColor: const Color(0xFF00897B),
                bgColor: const Color(0xFFE0F2F1),
                borderColor: const Color(0xFFB2DFDB),
                size: 34 * scale,
              ),
            ),

            // Eve Animated Avatar
            Positioned(
              bottom: 6 * scale,
              child: EveAnimatedAvatar(
                emote: EveEmote.greeting,
                size: avatarSize,
                isSpeaking: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeOrb({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required double size,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A261F) : bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF2E4235) : Colors.white,
          width: (size * 0.065).clamp(2.0, 4.0),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF101913) : borderColor)
                .withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.48,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildFeatureCarousel({
    required BuildContext context,
    required bool isDark,
    required bool isTablet,
    required double carouselHeight,
    required List<_WelcomeFeature> featureItems,
  }) {
    final iconBoxSize = isTablet ? 74.0 : 48.0;
    final iconSize = isTablet ? 38.0 : 24.0;
    final titleFontSize = isTablet ? 22.0 : 14.0;
    final descFontSize = isTablet ? 17.0 : 12.0;
    final cardBorderRadius = isTablet ? 28.0 : 20.0;
    final cardPadding = EdgeInsets.symmetric(
      horizontal: isTablet ? 24.0 : 14.0,
      vertical: isTablet ? 18.0 : 10.0,
    );

    return SizedBox(
      height: carouselHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: featureItems.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final item = featureItems[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: cardPadding,
            decoration: BoxDecoration(
              color: AppColors.getCardBg(context),
              borderRadius: BorderRadius.circular(cardBorderRadius),
              border: Border.all(
                color: AppColors.getBorder(context),
                width: isTablet ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: isTablet ? 20 : 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: item.iconBgColor,
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 14),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: item.iconColor,
                      size: iconSize,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 6 : 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: descFontSize,
                          color: AppColors.getTextSecondary(context),
                          height: isTablet ? 1.38 : 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots({
    required bool isDark,
    required bool isTablet,
    required int count,
  }) {
    final activeSize = isTablet ? 13.0 : 8.0;
    final inactiveSize = isTablet ? 9.0 : 6.0;
    final dotMargin = isTablet ? 7.0 : 4.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(horizontal: dotMargin),
            width: isActive ? activeSize : inactiveSize,
            height: isActive ? activeSize : inactiveSize,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : (isDark
                      ? const Color(0xFF2E4235)
                      : const Color(0xFFD6DCD6)),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCtaButton({
    required String buttonText,
    required bool isTablet,
    required bool isNarrow,
  }) {
    final buttonHeight = isTablet ? 70.0 : (isNarrow ? 48.0 : 52.0);
    final fontSize = isTablet ? 22.0 : (isNarrow ? 14.5 : 16.0);
    final iconSize = isTablet ? 26.0 : (isNarrow ? 18.0 : 20.0);
    final borderRadius = isTablet ? 38.0 : 28.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: isTablet ? 4.0 : 2.5,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: _onGetStartedPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeFeature {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;

  const _WelcomeFeature({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
  });
}
