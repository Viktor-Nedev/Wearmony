import 'package:flutter/material.dart';

import 'motion.dart';

/// A simple illustrated person, standing or seated. Used where a real photo
/// would be wrong (landing showcase, empty states). Colors animate on change.
class Figure extends StatelessWidget {
  const Figure({
    super.key,
    required this.clothing,
    this.hair = const Color(0xFF3B2A20),
    this.skin = const Color(0xFFE2B595),
    this.lips,
    this.tie,
    this.seated = false,
    this.width = 96,
  });

  final Color clothing;
  final Color hair;
  final Color skin;
  final Color? lips;
  final Color? tie;
  final bool seated;
  final double width;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.reduced(context)
        ? Duration.zero
        : const Duration(milliseconds: 700);
    return SizedBox(
      width: width,
      height: width * 1.55,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: clothing),
        duration: duration,
        curve: Motion.emphasized,
        builder: (context, clothingNow, _) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: hair),
          duration: duration,
          curve: Motion.emphasized,
          builder: (context, hairNow, _) => CustomPaint(
            painter: _FigurePainter(
              clothing: clothingNow ?? clothing,
              hair: hairNow ?? hair,
              skin: skin,
              lips: lips,
              tie: tie,
              seated: seated,
              pants: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF5B6475)
                  : const Color(0xFF3E4552),
            ),
          ),
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.clothing,
    required this.hair,
    required this.skin,
    required this.lips,
    required this.tie,
    required this.seated,
    required this.pants,
  });

  final Color clothing;
  final Color hair;
  final Color skin;
  final Color? lips;
  final Color? tie;
  final bool seated;
  final Color pants;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Paint fill(Color color) => Paint()..color = color;
    Offset p(double x, double y) => Offset(w * x, h * y);

    // Hair behind the head.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.29, h * 0.05, w * 0.71, h * 0.27),
        Radius.circular(w * 0.2),
      ),
      fill(hair),
    );
    // Neck and head.
    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, h * 0.2, w * 0.55, h * 0.28),
      fill(skin),
    );
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.15), width: w * 0.36, height: h * 0.2),
      fill(skin),
    );
    // Fringe.
    final fringe = Path()
      ..moveTo(w * 0.32, h * 0.13)
      ..quadraticBezierTo(w * 0.34, h * 0.05, w * 0.5, h * 0.05)
      ..quadraticBezierTo(w * 0.66, h * 0.05, w * 0.68, h * 0.13)
      ..quadraticBezierTo(w * 0.6, h * 0.09, w * 0.5, h * 0.09)
      ..quadraticBezierTo(w * 0.4, h * 0.09, w * 0.32, h * 0.13)
      ..close();
    canvas.drawPath(fringe, fill(hair));
    if (lips != null) {
      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.5, 0.2),
          width: w * 0.08,
          height: h * 0.012,
        ),
        fill(lips!),
      );
    }

    if (seated) {
      final wheel = Paint()
        ..color = const Color(0xFF6B7280)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035;
      canvas.drawCircle(p(0.46, 0.76), w * 0.28, wheel);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.24, h * 0.55, w * 0.74, h * 0.58),
          const Radius.circular(4),
        ),
        fill(const Color(0xFF4B5563)),
      );
      // Torso, lap and lower legs.
      final torso = Path()
        ..moveTo(w * 0.3, h * 0.3)
        ..quadraticBezierTo(w * 0.5, h * 0.27, w * 0.7, h * 0.3)
        ..lineTo(w * 0.72, h * 0.57)
        ..lineTo(w * 0.28, h * 0.57)
        ..close();
      canvas.drawPath(torso, fill(clothing));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.3, h * 0.53, w * 0.86, h * 0.6),
          const Radius.circular(6),
        ),
        fill(clothing),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.76, h * 0.58, w * 0.86, h * 0.86),
          const Radius.circular(6),
        ),
        fill(clothing),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.74, h * 0.86, w * 0.96, h * 0.89),
          const Radius.circular(4),
        ),
        fill(const Color(0xFF374151)),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.36, h * 0.6, w * 0.48, h * 0.97),
          Radius.circular(w * 0.05),
        ),
        fill(pants),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.52, h * 0.6, w * 0.64, h * 0.97),
          Radius.circular(w * 0.05),
        ),
        fill(pants),
      );
      final torso = Path()
        ..moveTo(w * 0.3, h * 0.3)
        ..quadraticBezierTo(w * 0.5, h * 0.27, w * 0.7, h * 0.3)
        ..lineTo(w * 0.76, h * 0.66)
        ..quadraticBezierTo(w * 0.5, h * 0.7, w * 0.24, h * 0.66)
        ..close();
      canvas.drawPath(torso, fill(clothing));
    }
    if (tie != null) {
      final tiePath = Path()
        ..moveTo(w * 0.47, h * 0.29)
        ..lineTo(w * 0.53, h * 0.29)
        ..lineTo(w * 0.55, h * 0.47)
        ..lineTo(w * 0.5, h * 0.52)
        ..lineTo(w * 0.45, h * 0.47)
        ..close();
      canvas.drawPath(tiePath, fill(tie!));
    }
    // Arms.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.2, h * 0.31, w * 0.29, h * 0.55),
        Radius.circular(w * 0.05),
      ),
      fill(skin),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.71, h * 0.31, w * 0.8, h * 0.55),
        Radius.circular(w * 0.05),
      ),
      fill(skin),
    );
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.clothing != clothing ||
      old.hair != hair ||
      old.lips != lips ||
      old.tie != tie ||
      old.seated != seated ||
      old.pants != pants;
}
