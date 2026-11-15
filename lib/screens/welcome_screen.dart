import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
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
    // Pure light theme forced on WelcomeScreen
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1E6F38),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E6F38),
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      useMaterial3: true,
    );

    if (_isCheckingExisting) {
      return Theme(
        data: lightTheme,
        child: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Theme(
      data: lightTheme,
      child: ValueListenableBuilder<AppLanguageType>(
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
              iconColor: const Color(0xFF1976D2),
              iconBgColor: const Color(0xFFE3F2FD),
              title: isSpanish
                  ? 'Observaciones Satelitales'
                  : 'Satellite Observations',
              description: isSpanish
                  ? 'Monitoreo en tiempo real de radiación, lluvia y humedad de la NASA'
                  : 'Real-time monitoring of radiation, rainfall, and moisture from NASA',
            ),
            _WelcomeFeature(
              icon: Icons.eco_rounded,
              iconColor: const Color(0xFF2E7D32),
              iconBgColor: const Color(0xFFE8F5E9),
              title: isSpanish
                  ? 'Manejo Agroecológico'
                  : 'Agroecological Management',
              description: isSpanish
                  ? 'Rotación de cultivos, fijación de nitrógeno y salud del suelo'
                  : 'Crop rotation, biological nitrogen fixation, and soil health',
            ),
            _WelcomeFeature(
              icon: Icons.smart_toy_rounded,
              iconColor: const Color(0xFFE65100),
              iconBgColor: const Color(0xFFFFF3E0),
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
            maxScaleFactor: 1.2,
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;
                    final isNarrow = availableWidth < 360;
                    final isShort = availableHeight < 680;
                    final isTablet = availableWidth >= 600;

                    final textScaler = MediaQuery.textScalerOf(context);
                    final carouselHeight =
                        (98.0 * textScaler.scale(1.0)).clamp(96.0, 134.0);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 16 : (isTablet ? 32 : 22),
                              vertical: isShort ? 8 : 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Top Bar: Decorative App Brand Pill on left, Language on right
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 10 : 12,
                                        vertical: isNarrow ? 5 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F8E9),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFC8E6C9),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.eco_rounded,
                                            size: isNarrow ? 14 : 15,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Eva Bits',
                                            style: TextStyle(
                                              fontSize: isNarrow ? 11.5 : 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1B5E20),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: AppLanguage.toggleLanguage,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isNarrow ? 10 : 13,
                                          vertical: isNarrow ? 5 : 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.03),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.language_rounded,
                                              size: isNarrow ? 15 : 16,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isSpanish ? 'Español' : 'English',
                                              style: TextStyle(
                                                fontSize: isNarrow ? 12 : 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF374151),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isShort ? 12 : 16),

                                // Eve Stage (Responsively scaled for all screens)
                                _buildEveDecoratedStage(
                                  availableWidth: availableWidth,
                                  isShort: isShort,
                                ),

                                SizedBox(height: isShort ? 16 : 24),

                                // Headline Title
                                Text(
                                  headline,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isShort || isNarrow ? 23 : 26,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                    height: 1.2,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(height: isShort ? 8 : 12),

                                // Subtitle
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isShort || isNarrow ? 13 : 14,
                                      color: const Color(0xFF374151),
                                      height: 1.45,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isShort ? 16 : 22),

                                // Feature Card Carousel
                                SizedBox(
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
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFF1F5F9),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.04),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: item.iconBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  item.icon,
                                                  color: item.iconColor,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF111827),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    item.description,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF4B5563),
                                                      height: 1.25,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Page Indicator Dots
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    featureItems.length,
                                    (index) {
                                      final isActive = _currentPage == index;
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: isActive ? 8 : 6,
                                        height: isActive ? 8 : 6,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? const Color(0xFF1E6F38)
                                              : const Color(0xFFD6DCD6),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: isShort ? 16 : 22),

                                // Bottom CTA Pill Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E6F38),
                                      foregroundColor: Colors.white,
                                      elevation: 2.5,
                                      shadowColor: const Color(0xFF1E6F38)
                                          .withValues(alpha: 0.35),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28),
                                      ),
                                    ),
                                    onPressed: _onGetStartedPressed,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          buttonText,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 19,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
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
      ),
    );
  }

  Widget _buildEveDecoratedStage({
    required double availableWidth,
    required bool isShort,
  }) {
    final maxStageW = isShort ? 230.0 : 280.0;
    final stageWidth = (availableWidth * 0.74).clamp(190.0, maxStageW);
    final stageHeight = stageWidth * (260.0 / 280.0);
    final scale = stageWidth / 280.0;

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
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.35),
              ),
            ),

            // Main Soft Pastel Organic Backdrop (Graduated Mint to Butter Yellow)
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE0F2E9),
                    Color(0xFFFFF9C4),
                    Color(0xFFE8F5E9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC8E6C9).withValues(alpha: 0.45),
                    blurRadius: 20 * scale,
                    spreadRadius: 3 * scale,
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

            // Eve Animated Avatar (Scale proportionally)
            Positioned(
              bottom: 6 * scale,
              child: EveAnimatedAvatar(
                emote: EveEmote.greeting,
                size: (215 * scale).clamp(150.0, 225.0),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
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
