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

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Bar: Decorative App Brand Pill on left, Language on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_rounded,
                                  size: 15,
                                  color: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Eva Bits',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: AppLanguage.toggleLanguage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language_rounded,
                                    size: 16,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isSpanish ? 'Español' : 'English',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Eve Stage (Bigger Eve + Rich Decorations)
                      _buildEveDecoratedStage(),

                      const SizedBox(height: 28),

                      // Headline Title (Moved lower for comfortable breathing room)
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          height: 1.18,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF4B5563),
                            height: 1.45,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Feature Card Carousel
                      SizedBox(
                        height: 96,
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
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
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: item.iconBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        item.icon,
                                        color: item.iconColor,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey.shade600,
                                            height: 1.25,
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
                      ),
                      const SizedBox(height: 14),

                      // Page Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          featureItems.length,
                          (index) {
                            final isActive = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
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
                      const SizedBox(height: 24),

                      // Bottom CTA Pill Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E6F38),
                            foregroundColor: Colors.white,
                            elevation: 2.5,
                            shadowColor: const Color(0xFF1E6F38)
                                .withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _onGetStartedPressed,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                buttonText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
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
    );
  }

  Widget _buildEveDecoratedStage() {
    return Center(
      child: SizedBox(
        width: 290,
        height: 275,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft Outer Ambient Glow Ring
            Container(
              width: 275,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.35),
              ),
            ),

            // Main Soft Pastel Organic Backdrop (Graduated Mint to Butter Yellow)
            Container(
              width: 255,
              height: 245,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(125),
                  topRight: Radius.circular(105),
                  bottomLeft: Radius.circular(115),
                  bottomRight: Radius.circular(135),
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
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),

            // Decorative Floating Badge 1: Top-Left (Sun / Climate)
            Positioned(
              top: 8,
              left: 10,
              child: _buildDecorativeOrb(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFFA000),
                bgColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFECB3),
                size: 38,
              ),
            ),

            // Decorative Floating Badge 2: Top-Right (Leaf / Agroecology)
            Positioned(
              top: 14,
              right: 12,
              child: _buildDecorativeOrb(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
                size: 36,
              ),
            ),

            // Decorative Floating Badge 3: Mid-Left (Water / Irrigation)
            Positioned(
              bottom: 48,
              left: 2,
              child: _buildDecorativeOrb(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF1976D2),
                bgColor: const Color(0xFFE3F2FD),
                borderColor: const Color(0xFFBBDEFB),
                size: 34,
              ),
            ),

            // Decorative Floating Badge 4: Mid-Right (Satellite Earth Sensor)
            Positioned(
              bottom: 54,
              right: 4,
              child: _buildDecorativeOrb(
                icon: Icons.satellite_alt_rounded,
                iconColor: const Color(0xFF00897B),
                bgColor: const Color(0xFFE0F2F1),
                borderColor: const Color(0xFFB2DFDB),
                size: 36,
              ),
            ),

            // Eve Animated Avatar (Bigger size 225, waving with gentle smile, isSpeaking = false)
            const Positioned(
              bottom: 8,
              child: EveAnimatedAvatar(
                emote: EveEmote.greeting,
                size: 225,
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
