import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/motion.dart';

/// Three steps joined by a dashed line that draws itself when scrolled into view:
/// step one appears, the line runs to step two, and so on.
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key, required this.wide});

  final bool wide;

  static const _badge = 58.0;

  // Timeline over one linear 0..1 run.
  static const _stepStart = [0.0, 0.38, 0.76];
  static const _stepLength = 0.24;
  static const _lineStart = [0.14, 0.52];
  static const _lineLength = 0.26;

  static double _part(double t, double start, double length) =>
      Interval(start, math.min(1, start + length)).transform(t);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final steps = [
      (Icons.qr_code_2_rounded, l10n.step1Title, l10n.step1Body),
      (Icons.add_a_photo_outlined, l10n.step2Title, l10n.step2Body),
      (Icons.diversity_3_rounded, l10n.step3Title, l10n.step3Body),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RevealOnScroll(
          child: Text(
            l10n.howItWorks,
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
        ),
        SizedBox(height: wide ? 36 : 28),
        ScrollAnimated(
          duration: const Duration(milliseconds: 2100),
          curve: Curves.linear,
          builder: (context, t, _) {
            double step(int i) => _part(t, _stepStart[i], _stepLength);
            double line(int i) => _part(t, _lineStart[i], _lineLength);
            return wide ? _wide(steps, step, line) : _narrow(steps, step, line);
          },
        ),
      ],
    );
  }

  Widget _wide(
    List<(IconData, String, String)> steps,
    double Function(int) step,
    double Function(int) line,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final column = constraints.maxWidth / steps.length;
        const gap = _badge / 2 + 14;
        return Stack(
          children: [
            for (var i = 0; i < steps.length - 1; i++)
              Positioned(
                left: column * (i + 0.5) + gap,
                width: column - 2 * gap,
                top: _badge / 2 - 5,
                height: 10,
                child: CustomPaint(
                  painter: _DashedLine(
                    progress: line(i),
                    axis: Axis.horizontal,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (icon, title, body)) in steps.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          _StepBadge(
                            icon: icon,
                            number: i + 1,
                            progress: step(i),
                          ),
                          const SizedBox(height: 18),
                          _StepText(
                            title: title,
                            body: body,
                            progress: step(i),
                            center: true,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _narrow(
    List<(IconData, String, String)> steps,
    double Function(int) step,
    double Function(int) line,
  ) {
    return Column(
      children: [
        for (final (i, (icon, title, body)) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _badge,
                  child: Column(
                    children: [
                      _StepBadge(icon: icon, number: i + 1, progress: step(i)),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: CustomPaint(
                              painter: _DashedLine(
                                progress: line(i),
                                axis: Axis.vertical,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 6,
                      bottom: i < steps.length - 1 ? 30 : 0,
                    ),
                    child: _StepText(
                      title: title,
                      body: body,
                      progress: step(i),
                      center: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.icon,
    required this.number,
    required this.progress,
  });

  final IconData icon;
  final int number;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = HowItWorks._badge;
    final p = progress.clamp(0.0, 1.0);
    return Opacity(
      opacity: p,
      child: Transform.scale(
        scale: 0.55 + 0.45 * Curves.easeOutBack.transform(p),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Brand.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: Brand.berry.withValues(alpha: 0.32 * p),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 27),
              ),
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: Brand.champagne, width: 1.6),
                  ),
                  child: Text(
                    '$number',
                    style: Brand.numbers(
                      Theme.of(context).textTheme.labelLarge,
                    )?.copyWith(color: scheme.primary, height: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({
    required this.title,
    required this.body,
    required this.progress,
    required this.center,
  });

  final String title;
  final String body;
  final double progress;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final align = center ? TextAlign.center : TextAlign.start;
    final p = Motion.emphasized.transform(progress.clamp(0.0, 1.0));
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - p)),
        child: Column(
          crossAxisAlignment: center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              textAlign: align,
              style: text.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: align,
              style: text.bodyMedium?.copyWith(
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dashed gradient line drawn up to [progress], with a dot at its moving end.
class _DashedLine extends CustomPainter {
  _DashedLine({required this.progress, required this.axis});

  final double progress;
  final Axis axis;

  static const _dash = 7.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p == 0) return;
    final horizontal = axis == Axis.horizontal;
    final length = horizontal ? size.width : size.height;
    final middle = horizontal ? size.height / 2 : size.width / 2;
    final end = length * Motion.emphasized.transform(p);
    Offset at(double d) => horizontal ? Offset(d, middle) : Offset(middle, d);

    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: const [Brand.berry, Brand.champagne],
        begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
        end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    for (var start = 0.0; start < end; start += _dash + _gap) {
      canvas.drawLine(at(start), at(math.min(start + _dash, end)), paint);
    }
    if (p < 1) {
      canvas.drawCircle(at(end), 4.5, Paint()..color = Brand.berry);
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) =>
      old.progress != progress || old.axis != axis;
}
