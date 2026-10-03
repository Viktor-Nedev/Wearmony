import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Motion rules: short, eased, and off when the user asks for reduced motion.
class Motion {
  const Motion._();

  /// Tests switch motion off so screens settle.
  static bool forceReduced = false;

  static bool reduced(BuildContext context) =>
      forceReduced || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// Delay for the n-th item of a staggered list, capped so long lists stay snappy.
  static Duration stagger(int index, {int stepMs = 60, int maxSteps = 10}) =>
      Duration(milliseconds: stepMs * index.clamp(0, maxSteps));
}

/// Fades and slides its child in once, after [delay]. Use [Motion.stagger] for lists.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 18),
    this.duration = const Duration(milliseconds: 520),
    this.scale = 1,
  });

  final Widget child;
  final Duration delay;

  /// Starting offset in logical pixels.
  final Offset offset;
  final Duration duration;

  /// Starting scale, e.g. 0.96 for a gentle zoom-in.
  final double scale;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasized,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(
              scale: widget.scale + (1 - widget.scale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Lifts slightly under the mouse and dips when pressed. Wrap cards and tiles.
class Hoverable extends StatefulWidget {
  const Hoverable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool enabled;

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final active = widget.enabled && !reduced;
    final scale = !active ? 1.0 : (_pressed ? 0.97 : (_hover ? 1.02 : 1.0));
    final shadow = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: _hover && active ? 0.18 : 0.0);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTap: widget.onTap == null
            ? null
            : () {
                // A light tick on Android; nothing on the web.
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: scale,
          duration: Motion.fast,
          curve: Motion.curve,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.curve,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Text that counts from its previous value to [value].
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return Text(format(value), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Motion.emphasized,
      builder: (context, current, _) => Text(format(current), style: style),
    );
  }
}

/// Runs [onTick] repeatedly while mounted and motion is allowed (for looping effects).
mixin LoopingAnimation<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  AnimationController? loop;

  Duration get loopDuration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loop == null && !Motion.reduced(context)) {
      loop = AnimationController(vsync: this, duration: loopDuration)..repeat();
    }
  }

  @override
  void dispose() {
    loop?.dispose();
    super.dispose();
  }
}

/// Runs a one-shot animation the first time its child scrolls into view,
/// and passes the eased progress (0..1) to [builder].
class ScrollAnimated extends StatefulWidget {
  const ScrollAnimated({
    super.key,
    required this.builder,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Motion.emphasized,
    this.child,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Duration delay;
  final Duration duration;

  /// Pass [Curves.linear] to sequence several parts with [Interval]s.
  final Curve curve;
  final Widget? child;

  @override
  State<ScrollAnimated> createState() => _ScrollAnimatedState();
}

class _ScrollAnimatedState extends State<ScrollAnimated>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final _curve = CurvedAnimation(parent: _controller, curve: widget.curve);
  ScrollPosition? _position;
  Timer? _timer;
  bool _shown = false;
  bool _pending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    if (Motion.reduced(context)) {
      _shown = true;
      _controller.value = 1;
      return;
    }
    _position?.removeListener(_scheduleCheck);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_scheduleCheck);
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(ScrollAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Content above may have grown or shrunk without any scrolling.
    _scheduleCheck();
  }

  /// Measures after the next frame: when the scroll offset changes, the new
  /// positions only exist once that frame has been laid out.
  void _scheduleCheck() {
    if (_shown || _pending) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      _check();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.sizeOf(context).height;
    // Starts just before the content is in view. Content that is already fully
    // on screen always starts, e.g. a footer when the page cannot scroll further.
    if (top > screen * 0.92 && top + box.size.height > screen) return;
    _shown = true;
    _position?.removeListener(_scheduleCheck);
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => widget.builder(context, _curve.value, child),
    );
  }
}

/// [Reveal] that waits until the content scrolls into view.
class RevealOnScroll extends StatelessWidget {
  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 28),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return ScrollAnimated(
      delay: delay,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: offset * (1 - t), child: child),
      ),
    );
  }
}
