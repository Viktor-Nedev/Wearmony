import 'package:flutter/material.dart';

import 'motion.dart';

/// Drag to compare: the "before" photo on the left, the try-on on the right.
/// Opens with a wipe that reveals the result.
class BeforeAfter extends StatefulWidget {
  const BeforeAfter({
    super.key,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
  });

  final Widget before;
  final Widget after;
  final String beforeLabel;
  final String afterLabel;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  double? _split;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isDismissed && _split == null) {
      if (Motion.reduced(context)) {
        _split = 0.5;
      } else {
        _intro.forward();
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  double get _value {
    if (_split != null) return _split!;
    // Wipe from fully "before" to the middle.
    return 1 - 0.5 * Curves.easeInOutCubic.transform(_intro.value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void drag(double dx) =>
            setState(() => _split = (dx / width).clamp(0.02, 0.98));
        return GestureDetector(
          onHorizontalDragStart: (d) => drag(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => drag(d.localPosition.dx),
          onTapDown: (d) => drag(d.localPosition.dx),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                final split = _value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.after,
                    ClipRect(
                      clipper: _LeftClipper(split),
                      child: widget.before,
                    ),
                    Positioned(
                      left: width * split - 1.5,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 3, color: Colors.white),
                    ),
                    Positioned(
                      left: width * split - 20,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows,
                            size: 22,
                            color: Color(0xFF3D1530),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Tag(widget.beforeLabel, visible: split > 0.18),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _Tag(widget.afterLabel, visible: split < 0.82),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.split);

  final double split;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.split != split;
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.visible});

  final String label;
  final bool visible;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: Motion.fast,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ),
  );
}
