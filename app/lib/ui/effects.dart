import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// Slowly drifting, softly blurred color blobs: the brand backdrop.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child, this.intensity = 1});

  final Widget child;

  /// 0..1, how strong the colors are.
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(seconds: 24);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final painter = loop == null
        ? _AuroraPainter(0, dark, widget.intensity)
        : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).colorScheme.surface),
        RepaintBoundary(
          child: loop == null
              ? CustomPaint(painter: painter)
              : AnimatedBuilder(
                  animation: loop!,
                  builder: (context, _) => CustomPaint(
                    painter: _AuroraPainter(
                      loop!.value,
                      dark,
                      widget.intensity,
                    ),
                  ),
                ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.dark, this.intensity);

  final double t;
  final bool dark;
  final double intensity;

  static const _blobs = [
    (Brand.berry, 0.18, 0.12, 0.55, 1.0, 0.0),
    (Brand.rose, 0.82, 0.18, 0.5, 1.3, 1.7),
    (Brand.champagne, 0.7, 0.85, 0.55, 0.8, 3.1),
    (Brand.plum, 0.12, 0.8, 0.45, 1.1, 4.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    final maxSide = math.max(size.width, size.height);
    for (final (color, x, y, radius, speed, phase) in _blobs) {
      final center = Offset(
        size.width * (x + 0.08 * math.sin(angle * speed + phase)),
        size.height * (y + 0.06 * math.cos(angle * speed * 0.8 + phase)),
      );
      final r = maxSide * radius;
      final alpha = (dark ? 0.30 : 0.38) * intensity;
      final paint = Paint()
        ..shader = ui.Gradient.radial(center, r, [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.t != t || old.dark != dark || old.intensity != intensity;
}

/// Frosted glass panel for content over the aurora.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Brand.plum.withValues(alpha: dark ? 0.35 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (dark ? const Color(0xFF241A21) : Colors.white).withValues(
                alpha: dark ? 0.62 : 0.68,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.08 : 0.7),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The logo: two overlapping circles (two people in harmony) and the wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size * 1.55,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _Disc(size: size, colors: const [Brand.plum, Brand.berry]),
          ),
          Positioned(
            left: size * 0.55,
            child: Opacity(
              opacity: 0.88,
              child: _Disc(
                size: size,
                colors: const [Color(0xFFE38FA8), Brand.champagne],
              ),
            ),
          ),
        ],
      ),
    );
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.35),
        Text(
          'Wearmony',
          style: TextStyle(
            fontFamily: Brand.displayFont,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.82,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );
}

/// Text painted with the brand gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          (dark
                  ? const LinearGradient(
                      colors: [Color(0xFFF6C7DB), Brand.rose, Brand.champagne],
                    )
                  : Brand.gradient)
              .createShader(bounds),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}

/// Primary call to action: gradient pill with a light sweep on hover.
class BrandButton extends StatefulWidget {
  const BrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<BrandButton> createState() => _BrandButtonState();
}

class _BrandButtonState extends State<BrandButton>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _pressed = false;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduced = Motion.reduced(context);
    final label = Text(
      widget.label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 15),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) {
          if (enabled && !reduced) _sweep.forward(from: 0);
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed && !reduced ? 0.97 : 1,
            duration: Motion.fast,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.45,
              duration: Motion.fast,
              child: Container(
                height: 54,
                width: widget.expand ? double.infinity : null,
                decoration: BoxDecoration(
                  gradient: Brand.gradient,
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: Brand.berry.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _sweep,
                        builder: (context, _) => Positioned.fill(
                          child: FractionalTranslation(
                            translation: Offset(-1.2 + 2.4 * _sweep.value, 0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.28),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                            ],
                            Flexible(child: label),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated placeholder while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget box(double t) => Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + 3 * t, 0),
          end: Alignment(-0.5 + 3 * t, 0),
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerHigh,
          ],
        ),
      ),
    );
    if (loop == null) return box(0.5);
    return AnimatedBuilder(
      animation: loop!,
      builder: (context, _) => box(loop!.value),
    );
  }
}

/// A light beam sweeping over a photo while the try-on engine works.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key});

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay>
    with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 2200);

  @override
  Widget build(BuildContext context) {
    if (loop == null) {
      return ColoredBox(color: Brand.plum.withValues(alpha: 0.12));
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: loop!,
        builder: (context, _) {
          final t = Curves.easeInOutSine.transform(
            loop!.value < 0.5 ? loop!.value * 2 : 2 - loop!.value * 2,
          );
          return CustomPaint(painter: _BeamPainter(t), size: Size.infinite);
        },
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  _BeamPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Brand.plum.withValues(alpha: 0.10),
    );
    final y = size.height * t;
    final glow = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y - 70),
        Offset(0, y + 8),
        [
          Brand.rose.withValues(alpha: 0),
          Brand.rose.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.9),
        ],
        [0, 0.85, 1],
      );
    canvas.drawRect(Rect.fromLTRB(0, y - 70, size.width, y + 2), glow);
    canvas.drawRect(
      Rect.fromLTRB(0, y, size.width, y + 2.5),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_BeamPainter old) => old.t != t;
}

/// A burst of brand-colored sparkles; call [SparkleBurstState.burst] to play it.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({super.key, required this.child});

  final Widget child;

  @override
  State<SparkleBurst> createState() => SparkleBurstState();
}

class SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  final _random = math.Random(7);
  List<_Sparkle> _sparkles = const [];

  void burst() {
    if (Motion.reduced(context)) return;
    _sparkles = List.generate(26, (_) {
      final angle = _random.nextDouble() * 2 * math.pi;
      return _Sparkle(
        direction: Offset(math.cos(angle), math.sin(angle)),
        distance: 60 + _random.nextDouble() * 90,
        size: 3 + _random.nextDouble() * 5,
        color: [
          Brand.plum,
          Brand.berry,
          Brand.rose,
          Brand.champagne,
        ][_random.nextInt(4)],
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _controller.isAnimating
                ? CustomPaint(
                    painter: _SparklePainter(_sparkles, _controller.value),
                    size: const Size(1, 1),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _Sparkle {
  const _Sparkle({
    required this.direction,
    required this.distance,
    required this.size,
    required this.color,
  });

  final Offset direction;
  final double distance;
  final double size;
  final Color color;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.sparkles, this.t);

  final List<_Sparkle> sparkles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOutCubic.transform(t);
    for (final s in sparkles) {
      final position = s.direction * s.distance * eased + Offset(0, 30 * t * t);
      final paint = Paint()
        ..color = s.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(t * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: s.size,
            height: s.size * 1.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

/// A rounded progress bar that fills smoothly to [value] (0..1).
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 7,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: Motion.reduced(context) ? target : 0, end: target),
      duration: const Duration(milliseconds: 1000),
      curve: Motion.emphasized,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      ),
    );
  }
}
