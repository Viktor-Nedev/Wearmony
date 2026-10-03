import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../util/format.dart';
import '../util/harmony_text.dart';
import 'harmony_visuals.dart';
import 'motion.dart';

/// The group as a ring of outfit colors with one line per compared pair,
/// colored by relation. The weakest pair pulses when it is a near-miss.
/// Pointing at (or tapping) a person keeps only their lines in focus.
class HarmonyMap extends StatefulWidget {
  const HarmonyMap({super.key, required this.board});

  final Board board;

  @override
  State<HarmonyMap> createState() => _HarmonyMapState();
}

class _Edge {
  const _Edge(this.a, this.b, this.finding, {required this.weakest});

  final int a;
  final int b;
  final HarmonyFinding finding;
  final bool weakest;
}

class _HarmonyMapState extends State<HarmonyMap> with TickerProviderStateMixin {
  AnimationController? _pulse;
  String? _focus;

  /// The pulse only runs while there is a near-miss to point at.
  bool get _needsPulse => widget.board.harmony.weakest?.isWarning ?? false;

  void _syncPulse() {
    final wanted = _needsPulse && !Motion.reduced(context);
    if (wanted && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1700),
      )..repeat();
    } else if (!wanted && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(HarmonyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  static bool _same(HarmonyFinding x, HarmonyFinding? y) =>
      y != null &&
      x.scope == y.scope &&
      x.people.join('|') == y.people.join('|') &&
      x.subjects.join('|') == y.subjects.join('|');

  /// Node centers on an ellipse; two people sit side by side.
  static List<Offset> _layout(int count, Size size) {
    final center = size.center(Offset.zero);
    final rx = size.width / 2 - 64;
    final ry = size.height / 2 - 52;
    final start = count == 2 ? math.pi : -math.pi / 2;
    return [
      for (var i = 0; i < count; i++)
        center +
            Offset(
              rx * math.cos(start + 2 * math.pi * i / count),
              ry * math.sin(start + 2 * math.pi * i / count),
            ),
    ];
  }

  /// Moves a label a little away from the middle of the map, off the crossing lines.
  static Offset _outward(Offset point, Offset center) {
    final away = point - center;
    if (away.distance < 1) return point;
    return point + away / away.distance * 16;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final board = widget.board;
    final people = [
      for (final person in board.participants)
        if (person.look.garment != null) person,
    ];
    final index = {for (final (i, person) in people.indexed) person.userId: i};
    final weakest = board.harmony.weakest;
    final edges = <_Edge>[];
    final alerts = <int>{};
    for (final finding in board.harmony.findings) {
      if (finding.scope == 'pair' && finding.people.length == 2) {
        final a = index[finding.people[0]];
        final b = index[finding.people[1]];
        if (a == null || b == null) continue;
        edges.add(_Edge(a, b, finding, weakest: _same(finding, weakest)));
      } else if (finding.scope == 'self' &&
          finding.isWarning &&
          _same(finding, weakest)) {
        final a = index[finding.people.first];
        if (a != null) alerts.add(a);
      }
    }
    if (people.length < 2 || edges.isEmpty) return const SizedBox.shrink();

    final focus = index[_focus];
    final relations = {for (final edge in edges) edge.finding.relation};
    final text = Theme.of(context).textTheme;
    final nearMisses = edges.where((e) => e.finding.isWarning).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The drawing is described in one sentence; the findings list has the details.
        Semantics(
          container: true,
          label: l10n.harmonyMapSemantics(people.length, nearMisses),
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final size = Size(
                  width,
                  width < 520 ? width * 0.92 : math.min(width * 0.52, 400),
                );
                final positions = _layout(people.length, size);
                return ScrollAnimated(
                  duration: const Duration(milliseconds: 1700),
                  curve: Curves.linear,
                  builder: (context, t, _) {
                    final lines = const Interval(0.3, 1).transform(t);
                    Widget paint(double pulse) => CustomPaint(
                      painter: _MapPainter(
                        edges: edges,
                        positions: positions,
                        progress: lines,
                        pulse: pulse,
                        focus: focus,
                        alerts: alerts,
                      ),
                    );
                    final weakestEdge = edges
                        .where((e) => e.weakest && e.finding.isWarning)
                        .firstOrNull;
                    return SizedBox.fromSize(
                      size: size,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: _pulse == null
                                  ? paint(0.25)
                                  : AnimatedBuilder(
                                      animation: _pulse!,
                                      builder: (context, _) =>
                                          paint(_pulse!.value),
                                    ),
                            ),
                          ),
                          if (weakestEdge != null)
                            _DeltaChip(
                              at: _outward(
                                Offset.lerp(
                                  positions[weakestEdge.a],
                                  positions[weakestEdge.b],
                                  0.5,
                                )!,
                                size.center(Offset.zero),
                              ),
                              finding: weakestEdge.finding,
                              opacity: const Interval(0.85, 1).transform(t),
                            ),
                          for (final (i, person) in people.indexed)
                            Positioned(
                              left: positions[i].dx - 50,
                              top: positions[i].dy - 26,
                              width: 100,
                              child: _MapNode(
                                person: person,
                                youLabel: l10n.you,
                                progress: Interval(
                                  math.min(0.04 * i, 0.3),
                                  math.min(0.04 * i + 0.3, 1),
                                ).transform(t),
                                focused: focus == i,
                                dimmed:
                                    focus != null &&
                                    focus != i &&
                                    !edges.any(
                                      (e) =>
                                          (e.a == focus && e.b == i) ||
                                          (e.b == focus && e.a == i),
                                    ),
                                onHover: (inside) => setState(
                                  () => _focus = inside ? person.userId : null,
                                ),
                                onTap: () => setState(
                                  () => _focus = _focus == person.userId
                                      ? null
                                      : person.userId,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 8,
          children: [
            for (final relation in const [
              'near_miss',
              'matched',
              'complementary',
              'contrast',
            ])
              if (relations.contains(relation))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: relation == 'near_miss' ? 4 : 2.5,
                      decoration: BoxDecoration(
                        color: relationColor(relation),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(relationName(l10n, relation), style: text.labelMedium),
                  ],
                ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.harmonyMapHint,
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.person,
    required this.youLabel,
    required this.progress,
    required this.focused,
    required this.dimmed,
    required this.onHover,
    required this.onTap,
  });

  final BoardParticipant person;
  final String youLabel;
  final double progress;
  final bool focused;
  final bool dimmed;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final look = person.look;
    final outfit = hexColor(look.garment?.colorHex);
    final p = progress.clamp(0.0, 1.0);
    final disc = focused ? 54.0 : 48.0;

    Widget satellite(String? hex, Alignment at) => Align(
      alignment: at,
      child: Container(
        width: 17,
        height: 17,
        decoration: BoxDecoration(
          color: hexColor(hex),
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 2.5),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: Motion.fast,
          opacity: dimmed ? 0.35 : 1,
          child: Opacity(
            opacity: p,
            child: Transform.scale(
              scale: 0.4 + 0.6 * Curves.easeOutBack.transform(p),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 62,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Motion.fast,
                          curve: Motion.curve,
                          width: disc,
                          height: disc,
                          decoration: BoxDecoration(
                            color: outfit,
                            shape: BoxShape.circle,
                            // A light ring keeps dark outfits visible on the dark theme.
                            border: Border.all(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : scheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: outfit.withValues(
                                  alpha: focused ? 0.6 : 0.4,
                                ),
                                blurRadius: focused ? 22 : 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                        if (look.hair != null)
                          satellite(look.hair!.colorHex, Alignment.topRight),
                        if (look.makeup != null)
                          satellite(
                            look.makeup!.colorHex,
                            Alignment.bottomRight,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    person.isMe ? youLabel : person.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: focused ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small ΔE label at the middle of the weakest line.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.at,
    required this.finding,
    required this.opacity,
  });

  final Offset at;
  final HarmonyFinding finding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final color = relationColor(finding.relation);
    return Positioned(
      left: at.dx - 40,
      top: at.dy - 13,
      width: 80,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                'ΔE ${finding.deltaE.toStringAsFixed(1)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.edges,
    required this.positions,
    required this.progress,
    required this.pulse,
    required this.focus,
    required this.alerts,
  });

  final List<_Edge> edges;
  final List<Offset> positions;
  final double progress;
  final double pulse;
  final int? focus;
  final Set<int> alerts;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = 0.5 + 0.5 * math.sin(pulse * 2 * math.pi);
    // Quiet lines first, warnings on top.
    final ordered = [...edges]
      ..sort(
        (x, y) => (x.finding.isWarning ? 1 : 0) - (y.finding.isWarning ? 1 : 0),
      );
    for (final edge in ordered) {
      final finding = edge.finding;
      final color = relationColor(finding.relation);
      final inFocus = focus == null || edge.a == focus || edge.b == focus;
      final from = positions[edge.a];
      final to = Offset.lerp(from, positions[edge.b], progress)!;
      if (progress <= 0) continue;
      if (edge.weakest && finding.isWarning && inFocus) {
        canvas.drawLine(
          from,
          to,
          Paint()
            ..color = color.withValues(alpha: 0.18 + 0.3 * glow)
            ..strokeWidth = 8 + 6 * glow
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      final strong = finding.isWarning || (focus != null && inFocus);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color.withValues(
            alpha: !inFocus ? 0.07 : (strong ? 0.95 : 0.45),
          )
          ..strokeWidth = finding.isWarning
              ? 3.4
              : (finding.partners ? 2.6 : 1.7)
          ..strokeCap = StrokeCap.round,
      );
    }
    // A person whose own hair or lip color nearly matches their outfit.
    for (final i in alerts) {
      canvas.drawCircle(
        positions[i],
        30 + 6 * glow,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = relationColor(
            'near_miss',
          ).withValues(alpha: 0.25 + 0.5 * (1 - glow)),
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.focus != focus ||
      old.edges != edges ||
      old.positions != positions;
}
