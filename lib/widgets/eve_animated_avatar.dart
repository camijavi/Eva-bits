import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';

enum EveEmote {
  greeting,   // Saludo
  alert,      // Alerta !
  sad,        // Triste
  surprised,  // Sorprendida
  happy,      // Feliz
  thumbsUp,   // Pulgar arriba
  thumbsDown, // Pulgar abajo
  pointing,   // Señalando algo
}

class EveAnimatedAvatar extends StatefulWidget {
  final EveEmote emote;
  final double size;
  final VoidCallback? onTap;
  final bool respectVisibilitySetting;

  const EveAnimatedAvatar({
    super.key,
    this.emote = EveEmote.greeting,
    this.size = 76,
    this.onTap,
    this.respectVisibilitySetting = false,
  });

  @override
  State<EveAnimatedAvatar> createState() => _EveAnimatedAvatarState();
}

class _EveAnimatedAvatarState extends State<EveAnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
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

  _EveCowPainter({
    required this.emote,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    final sinVal = math.sin(progress * 2 * math.pi);
    final cosVal = math.cos(progress * 2 * math.pi);
    final fastSin = math.sin(progress * 4 * math.pi);

    // Compute vertical bounce & head tilt based on emote
    double bounceY = 0.0;
    double headTilt = 0.0;
    double earAngleOffset = 0.0;

    switch (emote) {
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
    final legTop = h * 0.60 + bounceY * 0.5;
    final legBottom = h * 0.86;
    final legWidth = w * 0.075;

    final leftLegRect =
        Rect.fromLTWH(cx - w * 0.145, legTop, legWidth, legBottom - legTop);
    final rightLegRect =
        Rect.fromLTWH(cx + w * 0.07, legTop, legWidth, legBottom - legTop);

    canvas.drawRect(leftLegRect, whiteFill);
    canvas.drawRect(leftLegRect, outlinePaint);
    canvas.drawRect(rightLegRect, whiteFill);
    canvas.drawRect(rightLegRect, outlinePaint);

    // Rectangular black hooves extending slightly outward
    final hoofHeight = h * 0.055;
    final hoofWidth = w * 0.14;
    final leftHoofRect = Rect.fromLTWH(
        cx - w * 0.21, legBottom - 1, hoofWidth, hoofHeight);
    final rightHoofRect = Rect.fromLTWH(
        cx + w * 0.07, legBottom - 1, hoofWidth, hoofHeight);

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
    if (emote == EveEmote.surprised) {
      leftHand = Offset(cx - w * 0.40, h * 0.34 + bounceY - sinVal.abs() * 4);
      leftControl = Offset(cx - w * 0.34, h * 0.36 + bounceY);
    } else if (emote == EveEmote.happy) {
      leftHand = Offset(cx - w * 0.36, h * 0.48 + bounceY + sinVal * 4);
      leftControl = Offset(cx - w * 0.34, h * 0.42 + bounceY);
    } else if (emote == EveEmote.sad) {
      leftHand = Offset(cx - w * 0.29, h * 0.65 + bounceY);
      leftControl = Offset(cx - w * 0.30, h * 0.54 + bounceY);
    } else {
      leftHand = Offset(cx - w * 0.34, h * 0.60 + bounceY + cosVal * 2);
      leftControl = Offset(cx - w * 0.33, h * 0.46 + bounceY);
    }

    // Right arm pose (Main expressive arm for greeting, pointing, thumbsUp/Down)
    switch (emote) {
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
        rightHand = Offset(cx + w * 0.40, h * 0.34 + bounceY - sinVal.abs() * 4);
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
    return oldDelegate.emote != emote || oldDelegate.progress != progress;
  }
}

/// Interactive Banner Card showing Eve with a context-aware emote and message.
/// Automatically hides when AppSettings.showEve is false.
class EveReactionBanner extends StatelessWidget {
  final EveEmote emote;
  final String? title;
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final Color? accentColor;
  final Color? backgroundColor;

  const EveReactionBanner({
    super.key,
    required this.emote,
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
                emote: emote,
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
