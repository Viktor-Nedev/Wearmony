import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../util/save_png.dart';
import '../../widgets/common.dart';
import 'board_loader.dart';

/// Event Color Moodboard & Chromatic Harmony Studio:
/// Interactive Chromatic Wheel, color swatch deck, color temperature
/// balance, aesthetic vibe analysis, and palette image export.
class MoodboardScreen extends StatefulWidget {
  const MoodboardScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<MoodboardScreen> createState() => _MoodboardScreenState();
}

class _MoodboardScreenState extends State<MoodboardScreen>
    with BoardLoader, SingleTickerProviderStateMixin {
  @override
  String get boardEventId => widget.eventId;

  String? _selectedPersonId;
  final _paletteKey = GlobalKey();
  bool _saving = false;

  AnimationController? _pulseController;

  void _syncPulse() {
    final wanted = !Motion.reduced(context);
    if (wanted && _pulseController == null) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    } else if (!wanted && _pulseController != null) {
      _pulseController!.dispose();
      _pulseController = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _exportPalette(String eventName) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final boundary =
          _paletteKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await savePng(
        data!.buffer.asUint8List(),
        'wearmony-palette-${eventName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}.png',
        text: 'Wearmony Color Palette: $eventName',
      );
      if (savesByDownload) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final b = board;

    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.moodboardTitle)),
        body: boardError == null
            ? const Center(child: CircularProgressIndicator())
            : ErrorRetry(error: boardError!, onRetry: loadBoard),
      );
    }

    // Collect all unique outfit colors with participant names
    final swatches = <String, (Color, List<String>, double)>{};
    for (final p in b.participants) {
      final garment = p.look.garment;
      if (garment != null && garment.colorHex != null) {
        final hex = garment.colorHex!.toUpperCase();
        final c = hexColor(hex);
        final existing = swatches[hex];
        if (existing == null) {
          swatches[hex] = (c, [p.displayName], garment.price);
        } else {
          existing.$2.add(p.displayName);
        }
      }
    }

    final selected = b.participants
        .where((p) => p.userId == _selectedPersonId)
        .firstOrNull;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/e/${widget.eventId}?tab=board'),
        ),
        title: Text(l10n.moodboardTitle),
        actions: [
          IconButton(
            tooltip: l10n.moodboardExport,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _saving ? null : () => _exportPalette(b.event.name),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header subtitle
                      Text(
                        l10n.moodboardSubtitle,
                        style: text.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Section: Chromatic Wheel & Inspection
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 780;
                          final wheel = _ChromaticWheelCard(
                            board: b,
                            selectedId: _selectedPersonId,
                            pulse: _pulseController,
                            onSelect: (id) =>
                                setState(() => _selectedPersonId = id),
                          );

                          final inspector = _NodeInspectorCard(
                            board: b,
                            person: selected,
                            onClose: () =>
                                setState(() => _selectedPersonId = null),
                          );

                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 12, child: wheel),
                                const SizedBox(width: 20),
                                Expanded(flex: 9, child: inspector),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              wheel,
                              const SizedBox(height: 16),
                              inspector,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Aesthetics & Vibe Analysis
                      _AestheticVibeCard(
                        board: b,
                        swatches: swatches.values.map((s) => s.$1).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Swatch deck (captured boundary for export)
                      RepaintBoundary(
                        key: _paletteKey,
                        child: GlassCard(
                          radius: 28,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.palette_outlined,
                                    color: Brand.rose,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.moodboardPaletteTitle,
                                    style: text.titleLarge?.copyWith(
                                      fontFamily: Brand.displayFont,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    b.event.name,
                                    style: text.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (swatches.isEmpty)
                                Text(
                                  l10n.moodboardNoSwatches,
                                  style: text.bodyMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (final entry in swatches.entries)
                                      _SwatchCard(
                                        hex: entry.key,
                                        color: entry.value.$1,
                                        people: entry.value.$2,
                                        price: entry.value.$3,
                                        currency: b.budget.currency,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _ChromaticWheelCard extends StatelessWidget {
  const _ChromaticWheelCard({
    required this.board,
    required this.selectedId,
    required this.pulse,
    required this.onSelect,
  });

  final Board board;
  final String? selectedId;
  final AnimationController? pulse;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lens_blur_rounded, color: Brand.champagne),
              const SizedBox(width: 10),
              Text(
                l10n.moodboardWheelTitle,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.moodboardWheelHint,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: pulse != null
                  ? AnimatedBuilder(
                      animation: pulse!,
                      builder: (context, _) => CustomPaint(
                        painter: _ChromaticWheelPainter(
                          board: board,
                          selectedId: selectedId,
                          pulseValue: pulse!.value,
                        ),
                        child: Stack(
                          children: [
                            for (final (i, p) in board.participants.indexed)
                              _buildNodeTouchTarget(context, p, i),
                          ],
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _ChromaticWheelPainter(
                        board: board,
                        selectedId: selectedId,
                        pulseValue: 0.5,
                      ),
                      child: Stack(
                        children: [
                          for (final (i, p) in board.participants.indexed)
                            _buildNodeTouchTarget(context, p, i),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeTouchTarget(
    BuildContext context,
    BoardParticipant p,
    int index,
  ) {
    final color = p.look.garment != null
        ? hexColor(p.look.garment!.colorHex)
        : Colors.grey;

    final hsl = HSLColor.fromColor(color);
    final angle = hsl.hue * math.pi / 180;
    final radius = 100.0 * (0.4 + hsl.saturation * 0.6);
    final center = const Offset(160, 160);
    final pos = Offset(
      center.dx + radius * math.cos(angle) - 16,
      center.dy + radius * math.sin(angle) - 16,
    );

    final isSelected = selectedId == p.userId;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onTap: () => onSelect(isSelected ? null : p.userId),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: isSelected ? 1.3 : 1.0,
            duration: Motion.fast,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white70,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  p.displayName.isNotEmpty ? p.displayName[0] : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
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

class _ChromaticWheelPainter extends CustomPainter {
  _ChromaticWheelPainter({
    required this.board,
    required this.selectedId,
    required this.pulseValue,
  });

  final Board board;
  final String? selectedId;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.44;

    // Background chromatic hue ring
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..shader = ui.Gradient.sweep(
        center,
        [
          const Color(0xFFFF0000), // 0 Red
          const Color(0xFFFFFF00), // 60 Yellow
          const Color(0xFF00FF00), // 120 Green
          const Color(0xFF00FFFF), // 180 Cyan
          const Color(0xFF0000FF), // 240 Blue
          const Color(0xFFFF00FF), // 300 Magenta
          const Color(0xFFFF0000), // 360 Red
        ],
        [0.0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1.0],
      );

    canvas.drawCircle(center, radius, sweepPaint);

    // Inner subtle coordinate grid
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.12);

    canvas.drawCircle(center, radius * 0.65, gridPaint);
    canvas.drawCircle(center, radius * 0.35, gridPaint);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // Pairwise chords connecting nodes
    final positions = <String, Offset>{};
    for (final p in board.participants) {
      if (p.look.garment == null) continue;
      final c = hexColor(p.look.garment!.colorHex);
      final hsl = HSLColor.fromColor(c);
      final angle = hsl.hue * math.pi / 180;
      final dist = (radius - 13) * (0.4 + hsl.saturation * 0.6);
      positions[p.displayName] = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );
    }

    for (final finding in board.harmony.findings) {
      if (finding.people.length < 2) continue;
      final a = positions[finding.people[0]];
      final b = positions[finding.people[1]];
      if (a == null || b == null) continue;

      final isNearMiss = finding.relation == 'near_miss';
      final isMatch = finding.relation == 'matched';
      final isComp = finding.relation == 'complementary';

      final chordColor = isNearMiss
          ? const Color(0xFFD64545)
          : (isMatch
                ? Brand.success
                : (isComp ? const Color(0xFFB8862F) : Colors.white24));

      final stroke = isNearMiss ? (2.5 + pulseValue * 1.5) : 1.5;

      final chordPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = chordColor.withValues(alpha: isNearMiss ? 0.85 : 0.45);

      canvas.drawLine(a, b, chordPaint);
    }
  }

  @override
  bool shouldRepaint(_ChromaticWheelPainter old) =>
      old.selectedId != selectedId || old.pulseValue != pulseValue;
}

class _NodeInspectorCard extends StatelessWidget {
  const _NodeInspectorCard({
    required this.board,
    required this.person,
    required this.onClose,
  });

  final Board board;
  final BoardParticipant? person;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (person == null) {
      return GlassCard(
        radius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: Brand.rose),
                const SizedBox(width: 10),
                Text(
                  l10n.moodboardInspectTitle,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.moodboardInspectHint,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final garment = person!.look.garment;
    final color = garment != null ? hexColor(garment.colorHex) : Colors.grey;
    final hex = garment?.colorHex ?? '#888888';

    // Pairwise relations for this person
    final relations = board.harmony.findings
        .where((f) => f.people.contains(person!.displayName))
        .toList();

    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  person!.displayName,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: Brand.displayFont,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (garment != null) ...[
            Text(
              garment.name,
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'HEX: $hex',
                  style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  tooltip: l10n.linkCopied,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: hex));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.linkCopied}: $hex')),
                    );
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            l10n.moodboardPairRelations,
            style: text.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          if (relations.isEmpty)
            Text(l10n.none, style: text.bodySmall)
          else
            for (final r in relations) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    RelationPill(relation: r.relation, label: r.relation),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.sentence,
                        style: text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _AestheticVibeCard extends StatelessWidget {
  const _AestheticVibeCard({required this.board, required this.swatches});

  final Board board;
  final List<Color> swatches;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    // Null until at least two outfits can be compared; never shown as a perfect score.
    final score = board.harmony.groupScore;

    // Calculate color temperature balance
    var warmCount = 0;
    var coolCount = 0;
    for (final c in swatches) {
      final hsl = HSLColor.fromColor(c);
      // Black, white, grays and very muted colors have no real warmth either way.
      if (hsl.saturation < 0.15 ||
          hsl.lightness < 0.12 ||
          hsl.lightness > 0.92) {
        continue;
      }
      if (hsl.hue <= 90 || hsl.hue >= 300) {
        warmCount++;
      } else {
        coolCount++;
      }
    }
    final total = math.max(1, warmCount + coolCount);
    final warmPercent = (warmCount / total * 100).round();

    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Brand.rose),
              const SizedBox(width: 10),
              Text(
                l10n.moodboardVibeTitle,
                style: text.titleLarge?.copyWith(
                  fontFamily: Brand.displayFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final col1 = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.moodboardCohesionScore, style: text.labelLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (score != null) ...[
                        ScoreGauge(score: score, size: 68),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Text(
                          score == null
                              ? l10n.harmonyNoData
                              : score >= 80
                              ? l10n.moodboardCohesionHigh
                              : (score >= 60
                                    ? l10n.moodboardCohesionMed
                                    : l10n.moodboardCohesionLow),
                          style: text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final col2 = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.moodboardTempBalance, style: text.labelLarge),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: [
                          Expanded(
                            flex: math.max(1, warmPercent),
                            child: Container(
                              color: const Color(0xFFE88A6E),
                              alignment: Alignment.center,
                              child: Text(
                                '$warmPercent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: math.max(1, 100 - warmPercent),
                            child: Container(
                              color: const Color(0xFF5B88C4),
                              alignment: Alignment.center,
                              child: Text(
                                '${100 - warmPercent}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.moodboardWarm,
                          style: text.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.moodboardCool,
                          style: text.bodySmall,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (wide) {
                return Row(
                  children: [
                    Expanded(child: col1),
                    const SizedBox(width: 32),
                    Expanded(child: col2),
                  ],
                );
              }
              return Column(children: [col1, const SizedBox(height: 20), col2]);
            },
          ),
        ],
      ),
    );
  }
}

class _SwatchCard extends StatelessWidget {
  const _SwatchCard({
    required this.hex,
    required this.color,
    required this.people,
    required this.price,
    required this.currency,
  });

  final String hex;
  final Color color;
  final List<String> people;
  final double price;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Color block
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hex,
                  style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  people.join(', '),
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(context, price, currency),
                  style: text.bodySmall?.copyWith(
                    color: Brand.champagne,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
