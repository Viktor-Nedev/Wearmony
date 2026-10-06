import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'motion.dart';

/// A particle of metallic confetti or streamer fluttering through the air.
class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.isStreamer,
    required this.phase,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  final double rotationSpeed;
  final bool isStreamer;
  final double phase;
  double angle = 0;
}

/// An animated confetti cannon that rains metallic ribbons and foil sparkles across the screen.
class ConfettiCannon extends StatefulWidget {
  const ConfettiCannon({super.key, required this.child, this.controller});

  final Widget child;
  final ConfettiController? controller;

  static ConfettiController of(BuildContext context) {
    final state = context.findAncestorStateOfType<_ConfettiCannonState>();
    return state?._controller ?? ConfettiController();
  }

  @override
  State<ConfettiCannon> createState() => _ConfettiCannonState();
}

class ConfettiController extends ChangeNotifier {
  void burst({int count = 65}) {
    _burstCount = count;
    notifyListeners();
  }

  int _burstCount = 65;
  int get burstCount => _burstCount;
}

class _ConfettiCannonState extends State<ConfettiCannon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final ConfettiController _controller;
  final List<_Particle> _particles = [];
  final _random = math.Random();

  static const _palette = [
    Brand.plum,
    Brand.berry,
    Brand.rose,
    Brand.champagne,
    Color(0xFFFFD700), // Gold
    Color(0xFFE87A90), // Coral
    Color(0xFF8AE0B3), // Mint green
    Color(0xFFFFFFFF), // Silver/white
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ConfettiController();
    _controller.addListener(_handleBurst);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(_tick);
  }

  @override
  void didUpdateWidget(ConfettiCannon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleBurst);
      _controller = widget.controller ?? ConfettiController();
      _controller.addListener(_handleBurst);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleBurst);
    _anim.dispose();
    super.dispose();
  }

  void _handleBurst() {
    if (Motion.reduced(context)) return;
    _particles.clear();
    final count = _controller.burstCount;

    for (var i = 0; i < count; i++) {
      // Launch from top-center with wide horizontal spread
      final speed = 250 + _random.nextDouble() * 450;
      final angle = (math.pi / 2) + (_random.nextDouble() - 0.5) * 1.5;
      final isStreamer = _random.nextDouble() > 0.65;

      _particles.add(
        _Particle(
          position: Offset(
            0.5 + (_random.nextDouble() - 0.5) * 0.4,
            -0.05 - _random.nextDouble() * 0.15,
          ),
          velocity: Offset(
            math.cos(angle) * (speed * 0.0018),
            math.sin(angle) * (speed * 0.0022),
          ),
          color: _palette[_random.nextInt(_palette.length)],
          size: isStreamer
              ? (12 + _random.nextDouble() * 10)
              : (6 + _random.nextDouble() * 6),
          rotationSpeed: (_random.nextDouble() - 0.5) * 14,
          isStreamer: isStreamer,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }

    _anim.forward(from: 0);
  }

  void _tick() {
    final t = _anim.value;
    for (final p in _particles) {
      p.position += p.velocity;
      // Gravity acceleration
      p.velocity = Offset(p.velocity.dx * 0.985, p.velocity.dy + 0.00035);
      // Sway with sine wave
      p.position = Offset(
        p.position.dx + math.sin(t * 12 + p.phase) * 0.0015,
        p.position.dy,
      );
      p.angle += p.rotationSpeed * 0.05;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_anim.isAnimating && _particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  opacity: (1.0 - (_anim.value - 0.65).clamp(0.0, 0.35) / 0.35),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.opacity});

  final List<_Particle> particles;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final x = p.position.dx * size.width;
      final y = p.position.dy * size.height;

      // Skip particles outside viewport
      if (y < -40 || y > size.height + 40 || x < -40 || x > size.width + 40) {
        continue;
      }

      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle);

      // Simulate 3D tilt with y-scale
      final scaleY = math.cos(p.angle * 1.5 + p.phase);
      canvas.scale(1.0, scaleY.abs().clamp(0.15, 1.0));

      if (p.isStreamer) {
        // Metallic ribbon strip
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 0.35,
              height: p.size * 1.8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        // Diamond / Square confetti foil
        final path = Path()
          ..moveTo(0, -p.size * 0.7)
          ..lineTo(p.size * 0.7, 0)
          ..lineTo(0, p.size * 0.7)
          ..lineTo(-p.size * 0.7, 0)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
