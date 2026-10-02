import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'effects.dart';
import 'figure.dart';
import 'motion.dart';

Color relationColor(String relation) => switch (relation) {
  'near_miss' => const Color(0xFFD64545),
  'matched' => Brand.success,
  'complementary' => const Color(0xFFB8862F),
  _ => const Color(0xFF5B6B8C),
};

Color scoreColor(int score) {
  if (score >= 80) return Brand.success;
  if (score >= 60) return Brand.warning;
  return const Color(0xFFD64545);
}

/// A rounded label for a harmony relation.
class RelationPill extends StatelessWidget {
  const RelationPill({super.key, required this.relation, required this.label});

  final String relation;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = relationColor(relation);
    return AnimatedContainer(
      duration: Motion.medium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

/// Two overlapping color discs that slide together: one comparison at a glance.
class ColorPair extends StatelessWidget {
  const ColorPair({
    super.key,
    required this.a,
    required this.b,
    this.size = 34,
  });

  final Color a;
  final Color b;
  final double size;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.surfaceContainerLowest;
    Widget disc(Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: Motion.reduced(context) ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, _) => SizedBox(
        width: size * 1.65,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: size * 0.65 * (1 - t) * 0.5, child: disc(a)),
            Positioned(
              left: size * 0.65 + size * 0.3 * (1 - t),
              child: disc(b),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated arc showing a 0..100 harmony score.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 150,
    this.caption,
  });

  final int score;
  final double size;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final track = Theme.of(context).colorScheme.surfaceContainerHigh;
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: reduced ? score.toDouble() : 0,
        end: score.toDouble(),
      ),
      duration: const Duration(milliseconds: 1200),
      curve: Motion.emphasized,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GaugePainter(value / 100, scoreColor(value.round()), track),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.round().toString(),
                  style: TextStyle(
                    fontFamily: Brand.bodyFont,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: size * 0.28,
                    color: scoreColor(value.round()),
                    height: 1,
                  ),
                ),
                Text('/100', style: Theme.of(context).textTheme.labelMedium),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.fraction, this.color, this.track);

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke,
    );
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      start,
      sweep * fraction.clamp(0, 1),
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: [color.withValues(alpha: 0.55), color],
          transform: const GradientRotation(0),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// Landing showcase: three illustrated friends; a near-miss pink is spotted,
/// fixed, and the group score climbs. Loops while visible.
class HarmonyShowcase extends StatefulWidget {
  const HarmonyShowcase({super.key});

  @override
  State<HarmonyShowcase> createState() => _HarmonyShowcaseState();
}

class _Scene {
  const _Scene(this.colors, this.relation, this.score, this.deltaE);

  final List<Color> colors;
  final String relation;
  final int score;
  final double deltaE;
}

class _HarmonyShowcaseState extends State<HarmonyShowcase> {
  static const _scenes = [
    _Scene(
      [Color(0xFFE8A0B4), Color(0xFFE39AB6), Color(0xFF1F2A44)],
      'near_miss',
      46,
      3.0,
    ),
    _Scene(
      [Color(0xFFE8A0B4), Color(0xFFE8A0B4), Color(0xFF1F2A44)],
      'matched',
      85,
      0.4,
    ),
    _Scene(
      [Color(0xFF1F4E9C), Color(0xFFD4A017), Color(0xFF1E7F5C)],
      'complementary',
      85,
      61.2,
    ),
  ];
  int _index = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && !Motion.reduced(context)) {
      _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        if (mounted) setState(() => _index = (_index + 1) % _scenes.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _label(AppLocalizations l10n, String relation) => switch (relation) {
    'near_miss' => l10n.relationNearMiss,
    'matched' => l10n.relationMatched,
    _ => l10n.relationComplementary,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scene = _scenes[_index];
    final text = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Figure(
                clothing: scene.colors[0],
                hair: const Color(0xFFC8A165),
                skin: const Color(0xFFE8B998),
                lips: const Color(0xFF9E2A4B),
                width: 84,
              ),
              Figure(
                clothing: scene.colors[1],
                hair: const Color(0xFF2B211B),
                skin: const Color(0xFFF1CDB0),
                width: 84,
              ),
              Figure(
                clothing: scene.colors[2],
                hair: const Color(0xFF1E1612),
                skin: const Color(0xFF8D5A3B),
                seated: true,
                width: 84,
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: Motion.medium,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(_index),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ColorPair(a: scene.colors[0], b: scene.colors[1], size: 26),
                const SizedBox(width: 10),
                RelationPill(
                  relation: scene.relation,
                  label:
                      '${_label(l10n, scene.relation)} · ΔE ${scene.deltaE.toStringAsFixed(1)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(end: scene.score / 100),
            duration: const Duration(milliseconds: 900),
            curve: Motion.emphasized,
            builder: (context, value, _) => Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: scoreColor((value * 100).round()),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.groupHarmony((value * 100).round()),
                  style: text.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
