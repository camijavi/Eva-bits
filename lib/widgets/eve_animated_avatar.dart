import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/agro_prediction_engine.dart';
import '../services/app_settings.dart';
import '../services/azure_ai_service.dart';
import '../services/nasa_power_service.dart';
import '../services/subplot_graph_service.dart';

enum EveEmote {
  calm,       // Tranquila y de vez en cuando saluda
  greeting,   // Saludo
  alert,      // Alerta !
  sad,        // Triste
  surprised,  // Sorprendida
  happy,      // Feliz
  thumbsUp,   // Pulgar arriba
  thumbsDown, // Pulgar abajo
  pointing,   // Señalando algo
  jumping,    // Saltando con brazos abiertos para llamar la atención
}

class EveAnimatedAvatar extends StatefulWidget {
  final EveEmote emote;
  final double size;
  final VoidCallback? onTap;
  final bool respectVisibilitySetting;
  final bool isWalking;

  const EveAnimatedAvatar({
    super.key,
    this.emote = EveEmote.calm,
    this.size = 76,
    this.onTap,
    this.respectVisibilitySetting = false,
    this.isWalking = false,
  });

  /// Evaluates the message content given to the farmer and selects the most
  /// appropriate [EveEmote] so Eve's body language matches what she is saying.
  static EveEmote evaluateEmoteFromContent(
    String content, {
    bool isLoading = false,
  }) {
    if (isLoading) {
      return EveEmote.surprised;
    }

    final text = content.trim().toLowerCase();
    if (text.isEmpty) {
      return EveEmote.calm;
    }

    final Map<EveEmote, int> scores = {
      for (final e in EveEmote.values) e: 0,
    };

    void addScore(EveEmote emote, int points, List<String> keywords) {
      for (final kw in keywords) {
        if (text.contains(kw)) {
          scores[emote] = (scores[emote] ?? 0) + points;
        }
      }
    }

    // 1. Greeting / Welcome
    addScore(EveEmote.greeting, 5, [
      'soy eve',
      'tu ayudante de campo',
      'tu guía agrícola',
      'puedes preguntarme con confianza',
      'qué te gustaría revisar hoy',
      'i am eve',
      'your field helper',
      'what would you like to check',
    ]);
    addScore(EveEmote.greeting, 3, [
      'bienvenido',
      'buenos días',
      'buenas tardes',
      'buenas noches',
      'welcome',
    ]);
    if ((text.startsWith('hola') ||
            text.startsWith('¡hola') ||
            text.startsWith('hello') ||
            text.startsWith('hi')) &&
        text.length < 140) {
      scores[EveEmote.greeting] = (scores[EveEmote.greeting] ?? 0) + 5;
    }

    // 2. Alert (!) -> Pests, diseases, fungi, insects, or severe weather warnings
    addScore(EveEmote.alert, 4, [
      'cuidado contra plagas',
      'plagas que debes vigilar',
      'vigila principalmente estas plagas',
      'alerta',
      'urgente',
      'riesgo alto',
      'peligro',
      'gusano cogollero',
      'broca del café',
      'roya del café',
      'mosca blanca',
      'picudo',
      'gorgojo',
      'sigatoka',
      'barrenador',
      'tizón',
      'fusarium',
      'antracnosis',
      'bacteriosis',
      'helada',
      'inundación',
      'lluvias muy fuertes',
      'golpe de calor',
      'pest alert',
      'main pests to watch',
    ]);
    addScore(EveEmote.alert, 2, [
      'plaga',
      'gusano',
      'larva',
      'pulgón',
      'pulgones',
      'trips',
      'ácaro',
      'chinche',
      'minador',
      'enfermedad',
      'hongo',
      'mildiú',
      'pest',
      'disease',
      'fungus',
      'weevil',
      'borer',
      'blight',
    ]);

    // 3. Sad -> Severe drought, water deficit, wilting, root rot/suffocation, or errors
    addScore(EveEmote.sad, 5, [
      'sequía y calor fuerte',
      'sequía severa',
      'sufre sed',
      'déficit crítico',
      'déficit severo',
      'asfixia de la raíz',
      'asfixia la raíz',
      'pudrición de raíz',
      'no pude conectarme',
      'lo siento',
      'severe drought',
      'root rot',
      'root suffocation',
    ]);
    addScore(EveEmote.sad, 3, [
      'sequía',
      'falta de agua',
      'tierra muy seca',
      'marchitez',
      'marchita',
      'pierde agua rápido',
      'pérdida',
      'daño severo',
      'error',
      'drought',
      'wilting',
    ]);

    // 4. Thumbs Down -> Practices to avoid, nutrient leaching, low compatibility, closed window
    addScore(EveEmote.thumbsDown, 5, [
      'evita regar de golpe',
      'se lava el abono',
      'sin que la planta lo aproveche',
      'no conviene sembrar',
      'baja compatibilidad',
      'ventana cerrada',
      'no riegues',
      'no apliques',
      'avoid heavy flood irrigation',
      'washes away fertilizer',
      'low compatibility',
    ]);
    addScore(EveEmote.thumbsDown, 3, [
      'evita ',
      'desperdicio',
      'desfavorable',
      'no recomendable',
      'mal drenaje',
      'encharcamiento',
      'avoid ',
      'unfavorable',
    ]);

    // 5. Jumping -> Big urea/fertilizer savings, free nitrogen, exciting benefits
    addScore(EveEmote.jumping, 5, [
      'ahorro estimado de',
      'ahorro de fertilizante',
      'nitrógeno por hectárea de forma natural',
      'nitrógeno gratis',
      'abono gratis',
      'gran beneficio',
      'excelente noticia',
      'estimated savings of',
      'fertilizer and urea savings',
      'free nitrogen',
    ]);
    addScore(EveEmote.jumping, 3, [
      'ahorras',
      'urea',
      'gana cerca de',
      'atención',
      'muy importante',
      'aporta +',
    ]);

    // 6. Thumbs Up -> High compatibility, optimal irrigation system, optimal window/moisture
    addScore(EveEmote.thumbsUp, 4, [
      'alta compatibilidad',
      'compatibilidad del 9',
      'compatibilidad: 9',
      'sistema ideal',
      'sistema más conveniente',
      'humedad óptima',
      'ventana óptima',
      'te conviene sembrar',
      'excelente opción',
      'high compatibility',
      'ideal system',
      'best system for your',
      'optimal window',
    ]);
    addScore(EveEmote.thumbsUp, 2, [
      'eficiencia 9',
      'eficiencia: 9',
      'recomendado',
      'recomendada',
      'óptimo',
      'óptima',
      '95%',
      '92%',
      '90%',
    ]);

    // 7. Surprised -> Weekly changes, sudden shifts, accumulated heat/moisture changes
    addScore(EveEmote.surprised, 5, [
      'cambios de la última semana',
      'en los últimos 7 días',
      'changes over the past week',
      'over the last 7 days',
    ]);
    addScore(EveEmote.surprised, 3, [
      'pasó de ',
      'acumularon',
      'cambio brusco',
      'repentino',
      'variación',
    ]);

    // 8. Pointing -> Step-by-step plans, 3-week projections, calendar dates, soil explanation
    addScore(EveEmote.pointing, 4, [
      'plan de trabajo para las próximas 3 semanas',
      'próximas 3 semanas',
      'semana 1:',
      'semana 2:',
      'semana 3:',
      'calendario y fechas de siembra',
      'fechas recomendadas',
      'cómo se comporta tu suelo',
      '3-week work plan',
      'next 3 weeks',
      'week 1:',
      'week 2:',
      'week 3:',
      'planting calendar',
      'how your',
    ]);
    addScore(EveEmote.pointing, 2, [
      'meta:',
      'acción:',
      'lámina recomendada',
      '1. agua y riego',
      '2. clima en tu zona',
      '3. cuidado contra plagas',
      '4. próximas 3 semanas',
      'goal:',
      'action:',
    ]);

    // 9. Happy -> Stable weather, balanced soil, healthy crop growth, positive summary
    addScore(EveEmote.happy, 4, [
      'clima estable para el cultivo',
      'buen equilibrio',
      'crezca sano',
      'condiciones favorables',
      'tierra equilibrada',
      'stable weather for your crop',
      'grow healthy',
      'favorable conditions',
    ]);
    addScore(EveEmote.happy, 2, [
      'resumen práctico',
      'sano',
      'favorable',
      'buen drenaje',
      'practical summary',
    ]);

    EveEmote bestEmote = EveEmote.calm;
    int highestScore = 0;

    // Priority order in case of ties
    const priorityOrder = [
      EveEmote.alert,
      EveEmote.sad,
      EveEmote.thumbsDown,
      EveEmote.jumping,
      EveEmote.surprised,
      EveEmote.thumbsUp,
      EveEmote.pointing,
      EveEmote.greeting,
      EveEmote.happy,
      EveEmote.calm,
    ];

    for (final candidate in priorityOrder) {
      final candidateScore = scores[candidate] ?? 0;
      if (candidateScore > highestScore) {
        highestScore = candidateScore;
        bestEmote = candidate;
      }
    }

    return highestScore > 0 ? bestEmote : EveEmote.calm;
  }

  @override
  State<EveAnimatedAvatar> createState() => _EveAnimatedAvatarState();
}

class _EveAnimatedAvatarState extends State<EveAnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _cycleCount = 0;
  double _lastValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
      ..addListener(() {
        final v = _controller.value;
        if (v < _lastValue) {
          _cycleCount = (_cycleCount + 1) % 1000;
        }
        _lastValue = v;
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData? _getBadgeIcon() {
    switch (widget.emote) {
      case EveEmote.thumbsUp:
        return Icons.thumb_up_rounded;
      case EveEmote.thumbsDown:
        return Icons.thumb_down_rounded;
      case EveEmote.pointing:
        return Icons.touch_app_rounded;
      default:
        return null;
    }
  }

  Color _getBadgeColor() {
    switch (widget.emote) {
      case EveEmote.thumbsUp:
        return const Color(0xFF2E7D32);
      case EveEmote.thumbsDown:
        return const Color(0xFFC62828);
      case EveEmote.pointing:
        return const Color(0xFF0277BD);
      default:
        return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.respectVisibilitySetting) {
      return ValueListenableBuilder<bool>(
        valueListenable: AppSettings.showEve,
        builder: (context, isVisible, _) {
          if (!isVisible) return const SizedBox.shrink();
          return _buildAvatarContent();
        },
      );
    }
    return _buildAvatarContent();
  }

  Widget _buildAvatarContent() {
    final badgeIcon = _getBadgeIcon();

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final wave = math.sin(t * 2 * math.pi);

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _EveCowPainter(
                    emote: widget.emote,
                    progress: t,
                    cycleCount: _cycleCount,
                    isWalking: widget.isWalking,
                  ),
                ),
                if (badgeIcon != null)
                  Positioned(
                    right: widget.emote == EveEmote.pointing
                        ? -2 + (wave.abs() * 3)
                        : 0,
                    top: widget.emote == EveEmote.thumbsDown
                        ? widget.size * 0.48
                        : widget.size * 0.12 + (wave * 2),
                    child: Container(
                      width: widget.size * 0.28,
                      height: widget.size * 0.28,
                      decoration: BoxDecoration(
                        color: _getBadgeColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          badgeIcon,
                          size: widget.size * 0.16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EveCowPainter extends CustomPainter {
  final EveEmote emote;
  final double progress;
  final int cycleCount;
  final bool isWalking;

  _EveCowPainter({
    required this.emote,
    required this.progress,
    this.cycleCount = 0,
    this.isWalking = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    final sinVal = math.sin(progress * 2 * math.pi);
    final cosVal = math.cos(progress * 2 * math.pi);
    final fastSin = math.sin(progress * 4 * math.pi);
    // Smooth 0.0 -> 1.0 (jump up + open arms) -> 0.0 (land + close arms)
    final jumpPhase = sinVal.abs();
    // For EveEmote.calm: calm 75% of the time, waves hello every 4th cycle
    final bool isCalmWavingNow = (emote == EveEmote.calm) && (cycleCount % 4 == 2);
    final double calmWaveLift =
        isCalmWavingNow ? math.sin(progress * math.pi).clamp(0.0, 1.0) : 0.0;

    // Compute vertical bounce & head tilt based on emote
    double bounceY = 0.0;
    double headTilt = 0.0;
    double earAngleOffset = 0.0;

    if (isWalking) {
      bounceY = -fastSin.abs() * h * 0.035;
      headTilt = sinVal * 0.05;
      earAngleOffset = fastSin.abs() * 0.12;
    } else {
      switch (emote) {
        case EveEmote.calm:
          bounceY = sinVal * -h * 0.012;
          headTilt = isCalmWavingNow ? (sinVal * 0.055) : (sinVal * 0.018);
          earAngleOffset = isCalmWavingNow ? (sinVal * 0.07) : (sinVal * 0.025);
          break;
        case EveEmote.greeting:
          bounceY = sinVal.abs() * -h * 0.025;
          headTilt = sinVal * 0.06;
          earAngleOffset = sinVal * 0.08;
          break;
        case EveEmote.alert:
          bounceY = fastSin.abs() * -h * 0.03;
          headTilt = fastSin * 0.03;
          earAngleOffset = 0.18; // Perked up
          break;
        case EveEmote.sad:
          bounceY = h * 0.025 + (sinVal * h * 0.008);
          headTilt = -0.08;
          earAngleOffset = -0.42; // Drooping ears
          break;
        case EveEmote.surprised:
          bounceY = -sinVal.abs() * h * 0.055;
          earAngleOffset = 0.22;
          break;
        case EveEmote.happy:
          bounceY = -sinVal.abs() * h * 0.045;
          headTilt = sinVal * 0.09;
          earAngleOffset = sinVal.abs() * 0.15;
          break;
        case EveEmote.thumbsUp:
          bounceY = -sinVal.abs() * h * 0.03;
          headTilt = 0.07;
          earAngleOffset = 0.12;
          break;
        case EveEmote.thumbsDown:
          bounceY = h * 0.01;
          headTilt = sinVal * 0.11; // Shaking head
          earAngleOffset = -0.20;
          break;
        case EveEmote.pointing:
          bounceY = sinVal * h * 0.015;
          headTilt = 0.05;
          earAngleOffset = 0.10;
          break;
        case EveEmote.jumping:
          bounceY = -jumpPhase * h * 0.11;
          headTilt = sinVal * 0.04;
          earAngleOffset = jumpPhase * 0.28;
          break;
      }
    }

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final blackFill = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    final pinkFill = Paint()
      ..color = const Color(0xFFE69DB8)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.022).clamp(1.2, 2.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // -------------------------------------------------------------------------
    // 1. LEGS & RECTANGULAR HOOVES (Matches designer's drawing)
    // -------------------------------------------------------------------------
    if (emote == EveEmote.jumping) {
      // Dynamic ground shadow that shrinks as Eve jumps up and expands on landing
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.14 * (1.0 - jumpPhase * 0.45))
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.915),
          width: w * (0.46 - jumpPhase * 0.18),
          height: h * 0.045,
        ),
        shadowPaint,
      );
    }

    final legLift = emote == EveEmote.jumping ? bounceY : 0.0;
    final leftWalkStep = isWalking ? (sinVal.clamp(-1.0, 0.0) * h * 0.055) : 0.0;
    final rightWalkStep =
        isWalking ? ((-sinVal).clamp(-1.0, 0.0) * h * 0.055) : 0.0;

    final legTop =
        h * 0.60 + (emote == EveEmote.jumping ? bounceY : bounceY * 0.5);
    final leftLegBottom = h * 0.86 + legLift + leftWalkStep;
    final rightLegBottom = h * 0.86 + legLift + rightWalkStep;
    final legWidth = w * 0.075;

    final leftLegRect =
        Rect.fromLTWH(cx - w * 0.145, legTop, legWidth, leftLegBottom - legTop);
    final rightLegRect =
        Rect.fromLTWH(cx + w * 0.07, legTop, legWidth, rightLegBottom - legTop);

    canvas.drawRect(leftLegRect, whiteFill);
    canvas.drawRect(leftLegRect, outlinePaint);
    canvas.drawRect(rightLegRect, whiteFill);
    canvas.drawRect(rightLegRect, outlinePaint);

    // Rectangular black hooves extending slightly outward
    final hoofHeight = h * 0.055;
    final hoofWidth = w * 0.14;
    final leftHoofRect = Rect.fromLTWH(
        cx - w * 0.21, leftLegBottom - 1, hoofWidth, hoofHeight);
    final rightHoofRect = Rect.fromLTWH(
        cx + w * 0.07, rightLegBottom - 1, hoofWidth, hoofHeight);

    canvas.drawRect(leftHoofRect, blackFill);
    canvas.drawRect(rightHoofRect, blackFill);

    // -------------------------------------------------------------------------
    // 2. ARMS & CIRCULAR BLACK HOOVES (Articulated by Emote)
    // -------------------------------------------------------------------------
    final shoulderY = h * 0.43 + bounceY;
    final leftShoulder = Offset(cx - w * 0.22, shoulderY);
    final rightShoulder = Offset(cx + w * 0.22, shoulderY);

    Offset leftHand;
    Offset leftControl;
    Offset rightHand;
    Offset rightControl;

    // Left arm pose
    if (isWalking) {
      leftHand = Offset(
          cx - w * 0.34 - sinVal * w * 0.04, h * 0.56 + bounceY + sinVal * 4);
      leftControl = Offset(cx - w * 0.33, h * 0.46 + bounceY);
    } else if (emote == EveEmote.jumping) {
      // Opens wide & upward while jumping up (jumpPhase -> 1), closes on landing (jumpPhase -> 0)
      final closedLeftHand = Offset(cx - w * 0.27, h * 0.61);
      final openLeftHand = Offset(cx - w * 0.45, h * 0.20 + bounceY);
      final closedLeftCtrl = Offset(cx - w * 0.28, h * 0.51);
      final openLeftCtrl = Offset(cx - w * 0.36, h * 0.31 + bounceY);
      leftHand = Offset.lerp(closedLeftHand, openLeftHand, jumpPhase)!;
      leftControl = Offset.lerp(closedLeftCtrl, openLeftCtrl, jumpPhase)!;
    } else if (emote == EveEmote.surprised) {
      leftHand = Offset(cx - w * 0.40, h * 0.34 + bounceY - sinVal.abs() * 4);
      leftControl = Offset(cx - w * 0.34, h * 0.36 + bounceY);
    } else if (emote == EveEmote.happy) {
      leftHand = Offset(cx - w * 0.36, h * 0.48 + bounceY + sinVal * 4);
      leftControl = Offset(cx - w * 0.34, h * 0.42 + bounceY);
    } else if (emote == EveEmote.sad) {
      leftHand = Offset(cx - w * 0.29, h * 0.65 + bounceY);
      leftControl = Offset(cx - w * 0.30, h * 0.54 + bounceY);
    } else {
      leftHand = Offset(cx - w * 0.34, h * 0.60 + bounceY + cosVal * 1.5);
      leftControl = Offset(cx - w * 0.33, h * 0.46 + bounceY);
    }

    // Right arm pose (Main expressive arm for calm, greeting, pointing, thumbsUp/Down, jumping)
    if (isWalking) {
      rightHand = Offset(
          cx + w * 0.34 + sinVal * w * 0.04, h * 0.56 + bounceY - sinVal * 4);
      rightControl = Offset(cx + w * 0.33, h * 0.46 + bounceY);
    } else {
      switch (emote) {
        case EveEmote.calm:
          // Calm resting arm at side, occasionally lifting smoothly to wave hello
          final restingRightHand =
              Offset(cx + w * 0.34, h * 0.60 + bounceY - cosVal * 1.5);
          final restingRightCtrl = Offset(cx + w * 0.33, h * 0.46 + bounceY);
          final waveX = fastSin * w * 0.055;
          final wavingRightHand =
              Offset(cx + w * 0.37 + waveX, h * 0.25 + bounceY);
          final wavingRightCtrl = Offset(cx + w * 0.35, h * 0.36 + bounceY);
          rightHand =
              Offset.lerp(restingRightHand, wavingRightHand, calmWaveLift)!;
          rightControl =
              Offset.lerp(restingRightCtrl, wavingRightCtrl, calmWaveLift)!;
          break;
        case EveEmote.jumping:
          final closedRightHand = Offset(cx + w * 0.27, h * 0.61);
          final openRightHand = Offset(cx + w * 0.45, h * 0.20 + bounceY);
          final closedRightCtrl = Offset(cx + w * 0.28, h * 0.51);
          final openRightCtrl = Offset(cx + w * 0.36, h * 0.31 + bounceY);
          rightHand = Offset.lerp(closedRightHand, openRightHand, jumpPhase)!;
          rightControl = Offset.lerp(closedRightCtrl, openRightCtrl, jumpPhase)!;
          break;
        case EveEmote.greeting:
          final waveX = sinVal * w * 0.06;
          rightHand = Offset(cx + w * 0.37 + waveX, h * 0.24 + bounceY);
          rightControl = Offset(cx + w * 0.35, h * 0.36 + bounceY);
          break;
        case EveEmote.pointing:
          final reachX = sinVal.abs() * w * 0.04;
          rightHand = Offset(cx + w * 0.43 + reachX, h * 0.38 + bounceY);
          rightControl = Offset(cx + w * 0.33, h * 0.39 + bounceY);
          break;
        case EveEmote.thumbsUp:
          rightHand = Offset(cx + w * 0.36, h * 0.28 + bounceY + sinVal * 2);
          rightControl = Offset(cx + w * 0.34, h * 0.38 + bounceY);
          break;
        case EveEmote.thumbsDown:
          rightHand = Offset(cx + w * 0.36, h * 0.56 + bounceY);
          rightControl = Offset(cx + w * 0.34, h * 0.47 + bounceY);
          break;
        case EveEmote.surprised:
          rightHand =
              Offset(cx + w * 0.40, h * 0.34 + bounceY - sinVal.abs() * 4);
          rightControl = Offset(cx + w * 0.34, h * 0.36 + bounceY);
          break;
        case EveEmote.happy:
          rightHand = Offset(cx + w * 0.36, h * 0.48 + bounceY - sinVal * 4);
          rightControl = Offset(cx + w * 0.34, h * 0.42 + bounceY);
          break;
        case EveEmote.alert:
          rightHand = Offset(cx + w * 0.36, h * 0.34 + bounceY + fastSin * 3);
          rightControl = Offset(cx + w * 0.34, h * 0.40 + bounceY);
          break;
        case EveEmote.sad:
          rightHand = Offset(cx + w * 0.29, h * 0.65 + bounceY);
          rightControl = Offset(cx + w * 0.30, h * 0.54 + bounceY);
          break;
      }
    }

    _drawCurvedArm(canvas, leftShoulder, leftControl, leftHand, w * 0.055,
        whiteFill, outlinePaint, blackFill);
    _drawCurvedArm(canvas, rightShoulder, rightControl, rightHand, w * 0.055,
        whiteFill, outlinePaint, blackFill);

    // -------------------------------------------------------------------------
    // 3. ROUND WHITE TORSO & CHARACTERISTIC BLACK SPOT
    // -------------------------------------------------------------------------
    final bodyCenter = Offset(cx, h * 0.49 + bounceY);
    final bodyRadius = w * 0.235;
    canvas.drawCircle(bodyCenter, bodyRadius, whiteFill);
    canvas.drawCircle(bodyCenter, bodyRadius, outlinePaint);

    // Characteristic black spot on left chest (angled oval + lower lobe)
    canvas.save();
    final spotCenter = Offset(cx - w * 0.095, h * 0.46 + bounceY);
    canvas.translate(spotCenter.dx, spotCenter.dy);
    canvas.rotate(0.42);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: w * 0.155, height: h * 0.085),
      blackFill,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(cx - w * 0.09, h * 0.50 + bounceY),
      w * 0.042,
      blackFill,
    );

    // -------------------------------------------------------------------------
    // 4. HEAD, EARS, PINK SNOUT & EXPRESSIVE EYES
    // -------------------------------------------------------------------------
    final headCenter = Offset(cx, h * 0.265 + bounceY);
    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(headTilt);

    // Left & Right Ears behind top of head
    _drawEar(
      canvas,
      offset: Offset(-w * 0.095, -h * 0.115),
      angle: -0.22 - earAngleOffset,
      width: w * 0.068,
      height: h * 0.105,
      whiteFill: whiteFill,
      outlinePaint: outlinePaint,
    );
    _drawEar(
      canvas,
      offset: Offset(w * 0.095, -h * 0.115),
      angle: 0.22 + earAngleOffset,
      width: w * 0.068,
      height: h * 0.105,
      whiteFill: whiteFill,
      outlinePaint: outlinePaint,
    );

    // White Head Oval
    final headRect =
        Rect.fromCenter(center: Offset.zero, width: w * 0.29, height: h * 0.24);
    canvas.drawOval(headRect, whiteFill);
    canvas.drawOval(headRect, outlinePaint);

    // Eyes based on Emote
    final leftEyePos = Offset(-w * 0.055, -h * 0.032);
    final rightEyePos = Offset(w * 0.055, -h * 0.032);
    final isBlinking = progress > 0.92;

    if (emote == EveEmote.happy || emote == EveEmote.thumbsUp) {
      // Happy curved eyes
      final happyEyePaint = Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.028).clamp(1.6, 3.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
            center: leftEyePos, width: w * 0.055, height: h * 0.045),
        math.pi,
        math.pi,
        false,
        happyEyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: rightEyePos, width: w * 0.055, height: h * 0.045),
        math.pi,
        math.pi,
        false,
        happyEyePaint,
      );
    } else if (isBlinking &&
        emote != EveEmote.alert &&
        emote != EveEmote.surprised) {
      // Natural blink line
      canvas.drawLine(
        Offset(leftEyePos.dx - w * 0.025, leftEyePos.dy),
        Offset(leftEyePos.dx + w * 0.025, leftEyePos.dy),
        outlinePaint,
      );
      canvas.drawLine(
        Offset(rightEyePos.dx - w * 0.025, rightEyePos.dy),
        Offset(rightEyePos.dx + w * 0.025, rightEyePos.dy),
        outlinePaint,
      );
    } else {
      final eyeRadius = (emote == EveEmote.surprised || emote == EveEmote.alert)
          ? w * 0.028
          : w * 0.022;
      canvas.drawCircle(leftEyePos, eyeRadius, blackFill);
      canvas.drawCircle(rightEyePos, eyeRadius, blackFill);

      // Sad / Concerned eyebrows
      if (emote == EveEmote.sad || emote == EveEmote.thumbsDown) {
        canvas.drawLine(
          Offset(leftEyePos.dx - w * 0.03, leftEyePos.dy - h * 0.022),
          Offset(leftEyePos.dx + w * 0.02, leftEyePos.dy - h * 0.035),
          outlinePaint,
        );
        canvas.drawLine(
          Offset(rightEyePos.dx - w * 0.02, rightEyePos.dy - h * 0.035),
          Offset(rightEyePos.dx + w * 0.03, rightEyePos.dy - h * 0.022),
          outlinePaint,
        );
      }
    }

    // Pink Snout Oval (overlapping lower head, matching designer's artwork)
    final snoutCenter = Offset(0, h * 0.048);
    final snoutRect = Rect.fromCenter(
        center: snoutCenter, width: w * 0.285, height: h * 0.125);
    canvas.drawOval(snoutRect, pinkFill);
    canvas.drawOval(snoutRect, outlinePaint);

    // Two Square Black Nostrils inside Pink Snout
    final nostrilSize = w * 0.038;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(-w * 0.042, snoutCenter.dy - h * 0.004),
        width: nostrilSize,
        height: nostrilSize,
      ),
      blackFill,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.042, snoutCenter.dy - h * 0.004),
        width: nostrilSize,
        height: nostrilSize,
      ),
      blackFill,
    );

    canvas.restore();

    // -------------------------------------------------------------------------
    // 5. VECTOR ALERT "!" OR SURPRISED RAYS OVERLAY
    // -------------------------------------------------------------------------
    if (emote == EveEmote.alert) {
      final pulse = 1.0 + (fastSin.abs() * 0.15);
      final alertCenter = Offset(cx + w * 0.28, h * 0.14);
      final alertPaint = Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(alertCenter.dx, alertCenter.dy);
      canvas.scale(pulse);

      // Red alert circle with white "!"
      canvas.drawCircle(Offset.zero, w * 0.12, alertPaint);
      canvas.drawCircle(
          Offset.zero,
          w * 0.12,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      final exclamPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, -h * 0.022),
              width: w * 0.032,
              height: h * 0.085),
          const Radius.circular(2),
        ),
        exclamPaint,
      );
      canvas.drawCircle(Offset(0, h * 0.048), w * 0.018, exclamPaint);
      canvas.restore();
    } else if (emote == EveEmote.surprised) {
      final rayPaint = Paint()
        ..color = const Color(0xFFF57F17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final topY = h * 0.06 + bounceY;
      canvas.drawLine(
          Offset(cx, topY), Offset(cx, topY - h * 0.05), rayPaint);
      canvas.drawLine(Offset(cx - w * 0.14, topY + h * 0.02),
          Offset(cx - w * 0.19, topY - h * 0.03), rayPaint);
      canvas.drawLine(Offset(cx + w * 0.14, topY + h * 0.02),
          Offset(cx + w * 0.19, topY - h * 0.03), rayPaint);
    } else if (emote == EveEmote.jumping && jumpPhase > 0.45) {
      // Attention-calling motion arcs above hands when Eve is airborne with open arms
      final attentionOpacity = ((jumpPhase - 0.45) / 0.55).clamp(0.0, 1.0);
      final motionPaint = Paint()
        ..color = const Color(0xFF2E7D32).withValues(alpha: attentionOpacity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(leftHand.dx - w * 0.02, leftHand.dy - h * 0.06),
        Offset(leftHand.dx - w * 0.05, leftHand.dy - h * 0.11),
        motionPaint,
      );
      canvas.drawLine(
        Offset(rightHand.dx + w * 0.02, rightHand.dy - h * 0.06),
        Offset(rightHand.dx + w * 0.05, rightHand.dy - h * 0.11),
        motionPaint,
      );
    }
  }

  void _drawEar(
    Canvas canvas, {
    required Offset offset,
    required double angle,
    required double width,
    required double height,
    required Paint whiteFill,
    required Paint outlinePaint,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    canvas.drawOval(rect, whiteFill);
    canvas.drawOval(rect, outlinePaint);
    canvas.restore();
  }

  void _drawCurvedArm(
    Canvas canvas,
    Offset start,
    Offset control,
    Offset end,
    double thickness,
    Paint whiteFill,
    Paint outlinePaint,
    Paint blackFill,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final armWhiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final armBorderStroke = Paint()
      ..color = outlinePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness + outlinePaint.strokeWidth * 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, armBorderStroke);
    canvas.drawPath(path, armWhiteStroke);

    // Circular black hoof at the end of the arm
    canvas.drawCircle(end, thickness * 0.95, blackFill);
  }

  @override
  bool shouldRepaint(covariant _EveCowPainter oldDelegate) {
    return oldDelegate.emote != emote ||
        oldDelegate.progress != progress ||
        oldDelegate.cycleCount != cycleCount ||
        oldDelegate.isWalking != isWalking;
  }
}

/// Interactive Banner Card showing Eve with a context-aware emote and message.
/// Automatically hides when AppSettings.showEve is false.
class EveReactionBanner extends StatelessWidget {
  final EveEmote? emote;
  final String? title;
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final Color? accentColor;
  final Color? backgroundColor;

  const EveReactionBanner({
    super.key,
    this.emote,
    this.title,
    required this.message,
    this.onTap,
    this.onActionTap,
    this.actionLabel,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.showEve,
      builder: (context, showEve, _) {
        if (!showEve) return const SizedBox.shrink();

        final effectiveTap = onTap ?? onActionTap;
        final effectiveAccent = accentColor ?? const Color(0xFF1B5E20);
        final effectiveBg = backgroundColor ?? const Color(0xFFF1F8E9);
        final effectiveTitle = title ?? AppLanguage.strings.kIvyCopilotTitle;
        final effectiveEmote =
            emote ?? EveAnimatedAvatar.evaluateEmoteFromContent(message);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: effectiveAccent.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              EveAnimatedAvatar(
                emote: effectiveEmote,
                size: 68,
                onTap: effectiveTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effectiveTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: effectiveAccent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                    if (effectiveTap != null && actionLabel != null) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: effectiveTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 13, color: effectiveAccent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                actionLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: effectiveAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// InteractiveEmoteBar allowing users to preview or switch Eve's 8 emotes
class EveEmotePreviewSelector extends StatelessWidget {
  final EveEmote selectedEmote;
  final ValueChanged<EveEmote> onEmoteSelected;
  final AppStrings s;

  const EveEmotePreviewSelector({
    super.key,
    required this.selectedEmote,
    required this.onEmoteSelected,
    required this.s,
  });

  String _getLabel(EveEmote e) {
    switch (e) {
      case EveEmote.calm:
        return s.kEmoteCalm;
      case EveEmote.greeting:
        return s.kEmoteGreeting;
      case EveEmote.alert:
        return s.kEmoteAlert;
      case EveEmote.sad:
        return s.kEmoteSad;
      case EveEmote.surprised:
        return s.kEmoteSurprised;
      case EveEmote.happy:
        return s.kEmoteHappy;
      case EveEmote.thumbsUp:
        return s.kEmoteThumbsUp;
      case EveEmote.thumbsDown:
        return s.kEmoteThumbsDown;
      case EveEmote.pointing:
        return s.kEmotePointing;
      case EveEmote.jumping:
        return s.kEmoteJumping;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: EveEmote.values.map((e) {
        final isSelected = e == selectedEmote;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onEmoteSelected(e),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFF1F5F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFD0DCD3),
              ),
            ),
            child: Text(
              _getLabel(e),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1E2D24),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Single reusable component to display rounded Eve on the bottom-right of any screen.
/// When [onAddPressed] is provided, Eve appears tucked right behind the "+" button on the right side.
class EveFloatingLauncherButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? tooltip;
  final VoidCallback? onAddPressed;
  final String? addTooltip;
  final Map<String, dynamic>? farmData;
  final Map<String, dynamic>? nasaData;
  final FarmPredictionsReport? report;
  final SubplotGraph? graph;
  final List<Map<String, dynamic>>? subplots;
  final String? activeCrop;
  final String? activeSoil;
  final String? initialQuery;

  const EveFloatingLauncherButton({
    super.key,
    this.onPressed,
    this.tooltip,
    this.onAddPressed,
    this.addTooltip,
    this.farmData,
    this.nasaData,
    this.report,
    this.graph,
    this.subplots,
    this.activeCrop,
    this.activeSoil,
    this.initialQuery,
  });

  static void openChatModal(
    BuildContext context, {
    Map<String, dynamic>? farmData,
    Map<String, dynamic>? nasaData,
    FarmPredictionsReport? report,
    SubplotGraph? graph,
    List<Map<String, dynamic>>? subplots,
    String? activeCrop,
    String? activeSoil,
    String? initialQuery,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return EveUnifiedChatSheet(
          farmData: farmData,
          nasaData: nasaData,
          report: report,
          graph: graph,
          subplots: subplots,
          activeCrop: activeCrop,
          activeSoil: activeSoil,
          initialQuery: initialQuery,
        );
      },
    );
  }

  void _handleTap(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    openChatModal(
      context,
      farmData: farmData,
      nasaData: nasaData,
      report: report,
      graph: graph,
      subplots: subplots,
      activeCrop: activeCrop,
      activeSoil: activeSoil,
      initialQuery: initialQuery,
    );
  }

  Widget _buildRoundedEveCircle(BuildContext context, {bool badgeOnLeft = false}) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFE8F5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF2E7D32),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: EveAnimatedAvatar(
                emote: EveEmote.calm,
                size: 64,
              ),
            ),
          ),
          Positioned(
            top: -2,
            right: badgeOnLeft ? null : -2,
            left: badgeOnLeft ? -2 : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 12,
                  color: Color(0xFFFFD54F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChatButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white, width: 1.8),
      ),
      tooltip: tooltip,
      onPressed: () => _handleTap(context),
      child: const Icon(
        Icons.chat_bubble_rounded,
        color: Color(0xFFFFD54F),
        size: 22,
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: const Color(0xFF0F5A37),
      foregroundColor: Colors.white,
      elevation: 5,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white, width: 2.0),
      ),
      tooltip: addTooltip,
      onPressed: onAddPressed,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.showEve,
      builder: (context, showEve, _) {
        if (!showEve) {
          if (onAddPressed != null) {
            return SizedBox(
              width: 104,
              height: 84,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomRight,
                children: [
                  Positioned(
                    right: 36,
                    bottom: 14,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: _buildCompactChatButton(context),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _buildAddButton(),
                  ),
                ],
              ),
            );
          }
          return _buildCompactChatButton(context);
        }

        if (onAddPressed != null) {
          return SizedBox(
            width: 112,
            height: 92,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                // Eve positioned behind the "+" button on the right side
                Positioned(
                  right: 34,
                  bottom: 14,
                  child: _buildRoundedEveCircle(context, badgeOnLeft: true),
                ),
                // Foreground "+" action button
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _buildAddButton(),
                ),
              ],
            ),
          );
        }

        return _buildRoundedEveCircle(context);
      },
    );
  }
}

/// Duolingo-style upper conversation stage:
/// Eve walks from the side toward the center of the screen while growing larger,
/// and displays her current message progressively (little by little, step by step)
/// inside a Duolingo speech bubble above her head without ever cutting off text.
class EveDuolingoConversationStage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String speechBubbleText;
  final bool isLoading;
  final String loadingText;
  final VoidCallback onClose;
  final bool showEveStage;
  final bool isNormalChatFolded;
  final VoidCallback? onToggleFoldChat;

  const EveDuolingoConversationStage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.speechBubbleText,
    required this.isLoading,
    required this.loadingText,
    required this.onClose,
    this.showEveStage = true,
    this.isNormalChatFolded = false,
    this.onToggleFoldChat,
  });

  @override
  State<EveDuolingoConversationStage> createState() =>
      _EveDuolingoConversationStageState();
}

class _EveDuolingoConversationStageState
    extends State<EveDuolingoConversationStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _walkInController;
  late final Animation<double> _walkCurve;

  List<String> _chunks = const [''];
  int _currentChunkIndex = 0;
  int _revealedCharCount = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _walkInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _walkCurve = CurvedAnimation(
      parent: _walkInController,
      curve: Curves.easeOutCubic,
    );
    _walkInController.forward();
    _prepareChunksAndStartTypewriter(widget.speechBubbleText);
  }

  @override
  void didUpdateWidget(covariant EveDuolingoConversationStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speechBubbleText != widget.speechBubbleText ||
        (oldWidget.isLoading && !widget.isLoading)) {
      _prepareChunksAndStartTypewriter(widget.speechBubbleText);
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _walkInController.dispose();
    super.dispose();
  }

  List<String> _splitIntoChunks(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [''];

    final paragraphs = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final result = <String>[];
    for (final p in paragraphs) {
      final lines = p
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.length <= 3 && p.length <= 240) {
        result.add(p);
      } else {
        // Group header + up to 2 bullet lines per card so it never overflows or cuts off
        String? sectionHeader;
        final contentLines = <String>[];
        for (int i = 0; i < lines.length; i++) {
          if (i == 0 && !lines[i].startsWith('•') && !lines[i].startsWith('-')) {
            sectionHeader = lines[i];
          } else {
            contentLines.add(lines[i]);
          }
        }
        if (contentLines.isEmpty && sectionHeader != null) {
          result.add(sectionHeader);
        } else {
          for (int i = 0; i < contentLines.length; i += 2) {
            final slice = contentLines.sublist(
              i,
              math.min(i + 2, contentLines.length),
            );
            if (i == 0 && sectionHeader != null) {
              result.add('$sectionHeader\n${slice.join('\n')}');
            } else {
              result.add(slice.join('\n'));
            }
          }
        }
      }
    }

    return result.isEmpty ? [trimmed] : result;
  }

  void _prepareChunksAndStartTypewriter(String text) {
    _typewriterTimer?.cancel();
    _chunks = _splitIntoChunks(text);
    _currentChunkIndex = 0;
    _startTypewriterForCurrentChunk();
  }

  void _startTypewriterForCurrentChunk() {
    _typewriterTimer?.cancel();
    final targetText = _chunks[_currentChunkIndex];
    _revealedCharCount = 0;

    if (targetText.isEmpty) return;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _revealedCharCount = math.min(targetText.length, _revealedCharCount + 2);
        if (_revealedCharCount >= targetText.length) {
          timer.cancel();
        }
      });
    });
  }

  void _onBubbleOrNextTap() {
    if (widget.isLoading || _chunks.isEmpty) return;
    final currentFullText = _chunks[_currentChunkIndex];
    if (_revealedCharCount < currentFullText.length) {
      // Complete current step immediately if still typing
      _typewriterTimer?.cancel();
      setState(() {
        _revealedCharCount = currentFullText.length;
      });
    } else if (_currentChunkIndex < _chunks.length - 1) {
      setState(() {
        _currentChunkIndex++;
      });
      _startTypewriterForCurrentChunk();
    }
  }

  void _onPrevChunkTap() {
    if (widget.isLoading || _currentChunkIndex <= 0) return;
    setState(() {
      _currentChunkIndex--;
    });
    _startTypewriterForCurrentChunk();
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = AppLanguage.current.value == AppLanguageType.spanish;
    final foldBtnLabel = widget.isNormalChatFolded
        ? (isSpanish ? 'Mostrar chat' : 'Show chat')
        : (isSpanish ? 'Ocultar chat' : 'Hide chat');
    final nextLabel = isSpanish ? 'Siguiente' : 'Next';
    final prevLabel = isSpanish ? 'Anterior' : 'Back';

    final currentFullChunk =
        _chunks.isNotEmpty ? _chunks[_currentChunkIndex] : '';
    final visibleChunkText = currentFullChunk.substring(
      0,
      _revealedCharCount.clamp(0, currentFullChunk.length),
    );
    final evaluatedEmote = EveAnimatedAvatar.evaluateEmoteFromContent(
      currentFullChunk.isNotEmpty ? currentFullChunk : widget.speechBubbleText,
      isLoading: widget.isLoading,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        12,
        widget.showEveStage ? 10 : 6,
      ),
      decoration: BoxDecoration(
        gradient: widget.showEveStage
            ? const LinearGradient(
                colors: [Color(0xFFF9FCF9), Color(0xFFF1F8E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: widget.showEveStage ? null : Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Header Row with Title, Fold Chat Toggle & Close Button
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2D24),
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showEveStage && widget.onToggleFoldChat != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: widget.onToggleFoldChat,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isNormalChatFolded
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFA5D6A7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isNormalChatFolded
                                ? Icons.unfold_more_rounded
                                : Icons.unfold_less_rounded,
                            size: 15,
                            color: widget.isNormalChatFolded
                                ? Colors.white
                                : const Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            foldBtnLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: widget.isNormalChatFolded
                                  ? Colors.white
                                  : const Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: widget.onClose,
              ),
            ],
          ),

          // Upper Duolingo Stage (Hidden completely when Eve is disabled)
          if (widget.showEveStage) ...[
            const SizedBox(height: 6),

            // Duolingo Speech Bubble Above Centered Eve (Progressive & Uncut)
            AnimatedBuilder(
              animation: _walkCurve,
              builder: (context, child) {
                final bubbleOpacity =
                    ((_walkCurve.value - 0.35) / 0.65).clamp(0.0, 1.0);
                final bubbleScale = 0.88 + (0.12 * bubbleOpacity);
                return Opacity(
                  opacity: bubbleOpacity,
                  child: Transform.scale(
                    scale: bubbleScale,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _onBubbleOrNextTap,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: widget.isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.loadingText,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          widget.isNormalChatFolded ? 220 : 150,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        visibleChunkText,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E35),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_chunks.length > 1) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Step counter pills
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F8E9),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${_currentChunkIndex + 1} / ${_chunks.length}',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2E7D32),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Prev / Next controls
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_currentChunkIndex > 0)
                                              InkWell(
                                                onTap: _onPrevChunkTap,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .chevron_left_rounded,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF556B5D),
                                                      ),
                                                      Text(
                                                        prevLabel,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF556B5D),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if (_currentChunkIndex <
                                                _chunks.length - 1) ...[
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: _onBubbleOrNextTap,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF2E7D32),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        nextLabel,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      const Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                  // Downward triangular tail pointing to Eve in the center
                  CustomPaint(
                    size: const Size(22, 11),
                    painter: _DuolingoBubbleTailPainter(
                      fillColor: Colors.white,
                      borderColor: const Color(0xFFE0E0E0),
                    ),
                  ),
                ],
              ),
            ),

            // Centered Large Eve Walking In & Growing Larger
            AnimatedBuilder(
              animation: _walkCurve,
              builder: (context, _) {
                final v = _walkCurve.value;
                final isStillWalking = v < 0.94;
                final dx = (1.0 - v) * 115.0;
                final dy = (1.0 - v) * 18.0;
                final scale = 0.45 + (0.55 * v);
                final avatarHeight = widget.isNormalChatFolded ? 124.0 : 102.0;
                final avatarSize = widget.isNormalChatFolded ? 114.0 : 96.0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  height: avatarHeight,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Subtle Duolingo-style floor shadow oval under Eve
                            Container(
                              width: 58,
                              height: 11,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.08 * v),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            EveAnimatedAvatar(
                              emote: evaluatedEmote,
                              size: avatarSize,
                              isWalking: isStillWalking,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DuolingoBubbleTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _DuolingoBubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPath = Path()
      ..moveTo(0, -1.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width, -1.5)
      ..close();

    final borderPath = Path()
      ..moveTo(0, -0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width, -0.5);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DuolingoBubbleTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// Unified Duolingo-style conversation modal sheet for Eve across all screens.
class EveUnifiedChatSheet extends StatefulWidget {
  final Map<String, dynamic>? farmData;
  final Map<String, dynamic>? nasaData;
  final FarmPredictionsReport? report;
  final SubplotGraph? graph;
  final List<Map<String, dynamic>>? subplots;
  final String? activeCrop;
  final String? activeSoil;
  final String? initialQuery;

  const EveUnifiedChatSheet({
    super.key,
    this.farmData,
    this.nasaData,
    this.report,
    this.graph,
    this.subplots,
    this.activeCrop,
    this.activeSoil,
    this.initialQuery,
  });

  @override
  State<EveUnifiedChatSheet> createState() => _EveUnifiedChatSheetState();
}

class _EveUnifiedChatSheetState extends State<EveUnifiedChatSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isNormalChatFolded = false;

  late final AnimationController _foldController;
  late final Animation<double> _foldCurve;

  late Map<String, dynamic> _farmData;
  late Map<String, dynamic> _nasaData;
  FarmPredictionsReport? _report;
  SubplotGraph? _graph;
  List<Map<String, dynamic>> _subplots = [];
  String _activeCrop = 'Maíz';
  String _activeSoil = 'Franco';

  @override
  void initState() {
    super.initState();
    _foldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1.0, // 1.0 = normal chat unfolded, 0.0 = normal chat folded
    );
    _foldCurve = CurvedAnimation(
      parent: _foldController,
      curve: Curves.easeInOutCubic,
    );

    _farmData = widget.farmData ??
        {
          'name': 'Mi Finca',
          'zone': 'Nicaragua',
          'total_surface': 2.5,
          'unit': 'ha',
        };
    _nasaData = widget.nasaData ?? NasaPowerService.getFallbackData();
    _report = widget.report;
    _graph = widget.graph;
    _subplots = widget.subplots ?? [];
    _activeCrop = widget.activeCrop ?? 'Maíz';
    _activeSoil = widget.activeSoil ?? 'Franco';

    _initializeAndAskFirst();
  }

  @override
  void dispose() {
    _foldController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFoldNormalChat() {
    setState(() {
      _isNormalChatFolded = !_isNormalChatFolded;
      if (_isNormalChatFolded) {
        _foldController.reverse();
      } else {
        _foldController.forward();
        _scrollToBottom();
      }
    });
  }

  String _cleanText(String raw) {
    return raw.replaceAll('*', '').trim();
  }

  Future<void> _initializeAndAskFirst() async {
    final s = AppLanguage.strings;
    final firstQuery = widget.initialQuery ?? s.kIvyInitialPrompt;

    if (widget.farmData == null || widget.report == null) {
      try {
        final db = DatabaseManager();
        final latestFarm = await db.getLatestFarm();
        if (latestFarm != null) {
          _farmData = latestFarm;
          final farmId = latestFarm['id'] as int?;
          final lots = await db.getAllLotsWithSubplots(farmId: farmId);
          final spList = <Map<String, dynamic>>[];
          for (final lot in lots) {
            final sps = lot['subplots'] as List<dynamic>? ?? [];
            for (final sp in sps) {
              if (sp is Map<String, dynamic>) {
                spList.add(sp);
              }
            }
          }
          _subplots = spList;
          if (_subplots.isNotEmpty) {
            _activeCrop =
                widget.activeCrop ?? (_subplots.first['crop']?.toString() ?? 'Maíz');
            _activeSoil = widget.activeSoil ??
                (_subplots.first['soil_type']?.toString() ?? 'Franco');
          }
          if (farmId != null) {
            _graph = await SubplotGraphService.getGraphForFarm(farmId);
          }
        }
      } catch (_) {}

      _report ??= AgroPredictionEngine.generateReport(
        farmData: _farmData,
        nasaData: _nasaData,
        graph: _graph,
        subplots: _subplots,
        targetCrop: _activeCrop,
        targetSoilType: _activeSoil,
        strings: s,
      );
    }

    if (mounted) {
      await _askEve(firstQuery);
    }
  }

  Future<void> _askEve(String query) async {
    final cleanQuery = _cleanText(query);
    final s = AppLanguage.strings;
    setState(() {
      _messages.add({'role': 'user', 'text': cleanQuery});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final effectiveReport = _report ??
          AgroPredictionEngine.generateReport(
            farmData: _farmData,
            nasaData: _nasaData,
            graph: _graph,
            subplots: _subplots,
            targetCrop: _activeCrop,
            targetSoilType: _activeSoil,
            strings: s,
          );

      final reply = await AzureAiService.askEve(
        userQuery: cleanQuery,
        farmData: _farmData,
        nasaData: _nasaData,
        predictionsReport: effectiveReport,
        graph: _graph,
        subplots: _subplots,
        activeCrop: _activeCrop,
        activeSoil: _activeSoil,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': _cleanText(reply)});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': _cleanText(s.kIvyErrorMessage),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getLatestEveSpeechText(AppStrings s) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'assistant') {
        return _cleanText(_messages[i]['text'] ?? '');
      }
    }
    return s.kIvyAnalyzingScenario;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLanguage.strings;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxModalHeight =
        (mediaQuery.size.height - mediaQuery.padding.top - bottomInset)
            .clamp(320.0, mediaQuery.size.height * 0.92);

    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.showEve,
      builder: (context, showEve, _) {
        final effectiveFolded = showEve && _isNormalChatFolded;

        return AnimatedBuilder(
          animation: _foldCurve,
          builder: (context, _) {
            final foldFactor = showEve ? _foldCurve.value : 1.0;

            return Container(
              constraints: BoxConstraints(
                maxHeight: maxModalHeight,
              ),
              margin: EdgeInsets.only(bottom: bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize:
                    foldFactor < 0.99 ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  EveDuolingoConversationStage(
                    title: s.kIvyCopilotTitle,
                    subtitle: '$_activeCrop • ${s.kSoilPrefix} $_activeSoil',
                    speechBubbleText: _getLatestEveSpeechText(s),
                    isLoading: _isLoading,
                    loadingText: s.kIvyAnalyzingScenario,
                    onClose: () => Navigator.pop(context),
                    showEveStage: showEve,
                    isNormalChatFolded: effectiveFolded,
                    onToggleFoldChat: showEve ? _toggleFoldNormalChat : null,
                  ),
                  const Divider(height: 1),

                  // Foldable "Normal" Chat Section (3D paper fold animation)
                  if (foldFactor > 0.01)
                    Flexible(
                      fit: foldFactor < 0.99 ? FlexFit.loose : FlexFit.tight,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: foldFactor,
                          child: Opacity(
                            opacity: foldFactor.clamp(0.0, 1.0),
                            child: Transform(
                              alignment: Alignment.topCenter,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0018)
                                ..rotateX((1.0 - foldFactor) * 1.15),
                              child: SizedBox(
                                height: maxModalHeight * 0.42,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  itemCount:
                                      _messages.length + (_isLoading ? 1 : 0),
                                  itemBuilder: (ctx, index) {
                                    if (index == _messages.length &&
                                        _isLoading) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F8E9),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFDCEDC8)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF2E7D32),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  s.kIvyAnalyzingScenario,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey.shade800,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    final msg = _messages[index];
                                    final isUser = msg['role'] == 'user';
                                    final cleanMsgText =
                                        _cleanText(msg['text'] ?? '');

                                    return Align(
                                      alignment: isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.82,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? const Color(0xFF1B5E20)
                                              : const Color(0xFFF7FAF7),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(18),
                                            topRight: const Radius.circular(18),
                                            bottomLeft: isUser
                                                ? const Radius.circular(18)
                                                : const Radius.circular(4),
                                            bottomRight: isUser
                                                ? const Radius.circular(4)
                                                : const Radius.circular(18),
                                          ),
                                          border: isUser
                                              ? null
                                              : Border.all(
                                                  color:
                                                      const Color(0xFFE0E0E0)),
                                        ),
                                        child: Text(
                                          cleanMsgText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: isUser
                                                ? Colors.white
                                                : const Color(0xFF1E2D24),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildQuickChip(
                            Icons.pest_control_rounded, s.kQuickPromptPests),
                        _buildQuickChip(Icons.thunderstorm_rounded,
                            s.kQuickPromptPhenomena),
                        _buildQuickChip(
                            Icons.date_range_rounded, s.kQuickPrompt3Weeks),
                        _buildQuickChip(Icons.water_drop_rounded,
                            s.kQuickPromptIrrigation),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 8, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: s.kIvyInputHint,
                              hintStyle: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: const Color(0xFFF1F6F2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (t) {
                              final q = t.trim();
                              if (q.isNotEmpty && !_isLoading) {
                                _controller.clear();
                                _askEve(q);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: Color(0xFF1B5E20)),
                          onPressed: () {
                            final q = _controller.text.trim();
                            if (q.isNotEmpty && !_isLoading) {
                              _controller.clear();
                              _askEve(q);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 15, color: const Color(0xFF1B5E20)),
        backgroundColor: const Color(0xFFEAF5EC),
        side: const BorderSide(color: Color(0xFFC8E6C9)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: _isLoading
            ? null
            : () {
                _askEve(label);
              },
      ),
    );
  }
}
