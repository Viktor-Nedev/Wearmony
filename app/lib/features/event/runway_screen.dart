import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/confetti.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/fix_suggestions.dart';
import 'board_loader.dart';

enum RunwayMode { solo, duo, finale }

/// 3D Virtual Runway Catwalk: immersive fashion show experience with
/// moving spotlights, mirror-gloss runway floor, ambient audio visualizer,
/// solo/duo/finale camera angles, and live on-stage clash fixes with confetti!
class RunwayScreen extends StatefulWidget {
  const RunwayScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<RunwayScreen> createState() => _RunwayScreenState();
}

class _RunwayScreenState extends State<RunwayScreen>
    with BoardLoader, TickerProviderStateMixin {
  @override
  String get boardEventId => widget.eventId;

  int _currentIndex = 0;
  RunwayMode _mode = RunwayMode.solo;
  bool _autoWalk = false;
  Timer? _autoTimer;
  final _confetti = ConfettiController();

  AnimationController? _spotlightAnim;
  AnimationController? _pulseAnim;

  void _syncAnimations() {
    final wanted = !Motion.reduced(context);
    if (wanted) {
      _spotlightAnim ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      )..repeat(reverse: true);
      _pulseAnim ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else {
      _spotlightAnim?.dispose();
      _spotlightAnim = null;
      _pulseAnim?.dispose();
      _pulseAnim = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _spotlightAnim?.dispose();
    _pulseAnim?.dispose();
    super.dispose();
  }

  void _toggleAutoWalk() {
    setState(() {
      _autoWalk = !_autoWalk;
      if (_autoWalk) {
        _autoTimer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
          if (!mounted) return;
          final b = board;
          if (b == null || b.participants.isEmpty) return;
          setState(() {
            _currentIndex = (_currentIndex + 1) % b.participants.length;
          });
        });
      } else {
        _autoTimer?.cancel();
        _autoTimer = null;
      }
    });
  }

  void _nextModel() {
    final b = board;
    if (b == null || b.participants.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % b.participants.length;
    });
  }

  void _prevModel() {
    final b = board;
    if (b == null || b.participants.isEmpty) return;
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + b.participants.length) % b.participants.length;
    });
  }

  Future<void> _openFixDialog(
    BoardParticipant person,
    BoardParticipant partner,
    HarmonyFinding finding,
  ) async {
    final b = board;
    if (b == null) return;
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high, color: Brand.rose),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.fixTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      finding.sentence,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FixSuggestionsPanel(
                      eventId: widget.eventId,
                      target: finding,
                      currency: b.budget.currency,
                      onChanged: () async {
                        Navigator.pop(ctx);
                        await loadBoard();
                        _confetti.burst(count: 85);
                      },
                      user: person.userId,
                      withUser: partner.userId,
                      myUserId: b.me?.userId,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    // On phones the mode switcher shows icons only, so the title and back button keep their room.
    final compact = MediaQuery.sizeOf(context).width < 600;
    final b = board;

    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.runwayTitle)),
        body: boardError == null
            ? const Center(child: CircularProgressIndicator())
            : ErrorRetry(error: boardError!, onRetry: loadBoard),
      );
    }

    if (b.participants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.runwayTitle)),
        body: Center(
          child: NoticeBar(
            l10n.addPeopleHint(b.event.joinCode),
            icon: Icons.group_add_outlined,
          ),
        ),
      );
    }

    final safeIndex = _currentIndex.clamp(0, b.participants.length - 1);
    final activePerson = b.participants[safeIndex];
    final partner = b.byId(activePerson.pairWith);

    // Check if there is an active near-miss clash for this person
    final warningFinding = b.harmony.findings
        .where(
          (f) =>
              f.relation == 'near_miss' &&
              f.people.contains(activePerson.displayName),
        )
        .firstOrNull;

    // Demo people and mock renders are labeled on stage, like everywhere else.
    final simulated = b.participants.any(
      (p) => p.render.resultUrl != null && p.render.mock,
    );
    final honesty = b.event.demo
        ? (l10n.frameHonestDemo, Icons.brush_outlined)
        : simulated
        ? (l10n.frameHonestMock, Icons.science_outlined)
        : null;

    return ConfettiCannon(
      controller: _confetti,
      child: Scaffold(
        backgroundColor: const Color(0xFF100913),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/e/${widget.eventId}?tab=board'),
          ),
          title: Text(
            l10n.runwayTitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: Brand.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          actions: [
            // Mode switcher
            SegmentedButton<RunwayMode>(
              showSelectedIcon: !compact,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white70,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? Brand.berry.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              segments: [
                ButtonSegment(
                  value: RunwayMode.solo,
                  label: compact ? null : Text(l10n.runwaySolo),
                  tooltip: compact ? l10n.runwaySolo : null,
                  icon: const Icon(Icons.person, size: 16),
                ),
                ButtonSegment(
                  value: RunwayMode.duo,
                  label: compact ? null : Text(l10n.runwayDuo),
                  tooltip: compact ? l10n.runwayDuo : null,
                  icon: const Icon(Icons.favorite, size: 16),
                  enabled: partner != null,
                ),
                ButtonSegment(
                  value: RunwayMode.finale,
                  label: compact ? null : Text(l10n.runwayFinale),
                  tooltip: compact ? l10n.runwayFinale : null,
                  icon: const Icon(Icons.groups, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) => setState(() => _mode = set.first),
            ),
            const SizedBox(width: 8),
            // Auto-walk button
            IconButton(
              tooltip: _autoWalk ? l10n.runwayPause : l10n.runwayPlay,
              icon: Icon(
                _autoWalk ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: _autoWalk ? Brand.rose : Colors.white,
                size: 28,
              ),
              onPressed: _toggleAutoWalk,
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Moving spotlights
            _spotlightAnim != null
                ? AnimatedBuilder(
                    animation: _spotlightAnim!,
                    builder: (context, _) => CustomPaint(
                      painter: _StageSpotlightPainter(_spotlightAnim!.value),
                      size: Size.infinite,
                    ),
                  )
                : CustomPaint(
                    painter: _StageSpotlightPainter(0.5),
                    size: Size.infinite,
                  ),

            // Catwalk Stage Floor with mirror gloss reflection
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 260,
              child: CustomPaint(
                painter: _StageFloorPainter(),
                size: Size.infinite,
              ),
            ),

            // Models Stage Display
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120, top: 40),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 550),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: switch (_mode) {
                      RunwayMode.solo => _SoloRunwayView(
                        key: ValueKey('solo_${activePerson.userId}'),
                        person: activePerson,
                      ),
                      RunwayMode.duo =>
                        partner == null
                            ? _SoloRunwayView(
                                key: ValueKey('solo_${activePerson.userId}'),
                                person: activePerson,
                              )
                            : _DuoRunwayView(
                                key: ValueKey(
                                  'duo_${activePerson.userId}_${partner.userId}',
                                ),
                                person: activePerson,
                                partner: partner,
                              ),
                      RunwayMode.finale => _FinaleRunwayView(
                        key: const ValueKey('finale'),
                        board: b,
                      ),
                    },
                  ),
                ),
              ),
            ),

            // Bottom Audio-Visualizer EQ beat
            Positioned(
              bottom: 96,
              left: 0,
              right: 0,
              child: Center(
                child: _pulseAnim != null
                    ? AnimatedBuilder(
                        animation: _pulseAnim!,
                        builder: (context, _) =>
                            _AudioBarsVisualizer(progress: _pulseAnim!.value),
                      )
                    : const _AudioBarsVisualizer(progress: 0.5),
              ),
            ),

            if (honesty != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Brand.champagne.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(honesty.$2, size: 14, color: Brand.champagne),
                      const SizedBox(width: 6),
                      Text(
                        honesty.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Floating Model Info Card
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  // Dark glass: white text stays readable in both themes.
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Left / Prev
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _prevModel,
                        ),
                        const SizedBox(width: 8),

                        // Model Info Details
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    activePerson.displayName,
                                    style: text.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: Brand.displayFont,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (activePerson.pose == Pose.seated)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.poseSeated,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  if (activePerson.look.total > 0)
                                    Text(
                                      formatMoney(
                                        context,
                                        activePerson.look.total,
                                        b.budget.currency,
                                      ),
                                      style: text.labelLarge?.copyWith(
                                        color: Brand.champagne,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (activePerson.look.garment != null) ...[
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: hexColor(
                                          activePerson.look.garment!.colorHex,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        activePerson.look.garment!.name,
                                        style: text.bodySmall?.copyWith(
                                          color: Colors.white70,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      l10n.none,
                                      style: text.bodySmall?.copyWith(
                                        color: Colors.white38,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Clash Fix Quick Action Button
                        if (warningFinding != null && partner != null) ...[
                          const SizedBox(width: 12),
                          PulseGlow(
                            color: const Color(0xFFD64545),
                            radius: 16,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD64545),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.auto_fix_high, size: 16),
                              label: Text(l10n.runwayFixNow),
                              onPressed: () => _openFixDialog(
                                activePerson,
                                partner,
                                warningFinding,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(width: 8),
                        // Right / Next
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _nextModel,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoloRunwayView extends StatelessWidget {
  const _SoloRunwayView({super.key, required this.person});

  final BoardParticipant person;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Brand.plum.withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: NetImage(person.pictureUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }
}

class _DuoRunwayView extends StatelessWidget {
  const _DuoRunwayView({
    super.key,
    required this.person,
    required this.partner,
  });

  final BoardParticipant person;
  final BoardParticipant partner;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NetImage(person.pictureUrl, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NetImage(partner.pictureUrl, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

class _FinaleRunwayView extends StatelessWidget {
  const _FinaleRunwayView({super.key, required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (i, p) in board.participants.indexed) ...[
            SizedBox(
              width: 180,
              height: 380,
              child: Reveal(
                delay: Duration(milliseconds: i * 80),
                scale: 0.88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: NetImage(p.pictureUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _StageFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Trapezoid perspective catwalk
    final path = Path()
      ..moveTo(size.width * 0.28, 0)
      ..lineTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.95, size.height)
      ..lineTo(size.width * 0.05, size.height)
      ..close();

    // Mirror sheen gradient
    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          const Color(0x33441A3D),
          const Color(0x882A0F26),
          const Color(0xDD150714),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawPath(path, floorPaint);

    // Glowing stage runway boundary lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          Brand.rose.withValues(alpha: 0.1),
          Brand.rose.withValues(alpha: 0.8),
          Brand.champagne.withValues(alpha: 0.9),
        ],
        [0.0, 0.5, 1.0],
      );

    // Left border
    canvas.drawLine(
      Offset(size.width * 0.28, 0),
      Offset(size.width * 0.05, size.height),
      linePaint,
    );
    // Right border
    canvas.drawLine(
      Offset(size.width * 0.72, 0),
      Offset(size.width * 0.95, size.height),
      linePaint,
    );

    // Lateral perspective stripes
    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.08);

    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      final leftX = ui.lerpDouble(size.width * 0.28, size.width * 0.05, i / 5)!;
      final rightX = ui.lerpDouble(
        size.width * 0.72,
        size.width * 0.95,
        i / 5,
      )!;
      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), stripePaint);
    }
  }

  @override
  bool shouldRepaint(_StageFloorPainter old) => false;
}

class _StageSpotlightPainter extends CustomPainter {
  _StageSpotlightPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = math.sin(t * math.pi * 2) * (size.width * 0.14);

    // Left sweeping spotlight
    final leftOrigin = Offset(size.width * 0.15, -40);
    final leftTarget = Offset(size.width * 0.45 + sweep, size.height * 0.65);
    final leftBeam = Path()
      ..moveTo(leftOrigin.dx - 20, leftOrigin.dy)
      ..lineTo(leftOrigin.dx + 20, leftOrigin.dy)
      ..lineTo(leftTarget.dx + 160, leftTarget.dy)
      ..lineTo(leftTarget.dx - 160, leftTarget.dy)
      ..close();

    final leftPaint = Paint()
      ..shader = ui.Gradient.radial(
        leftOrigin,
        size.height * 0.9,
        [
          Brand.rose.withValues(alpha: 0.32),
          Brand.rose.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      );
    canvas.drawPath(leftBeam, leftPaint);

    // Right sweeping spotlight
    final rightOrigin = Offset(size.width * 0.85, -40);
    final rightTarget = Offset(size.width * 0.55 - sweep, size.height * 0.65);
    final rightBeam = Path()
      ..moveTo(rightOrigin.dx - 20, rightOrigin.dy)
      ..lineTo(rightOrigin.dx + 20, rightOrigin.dy)
      ..lineTo(rightTarget.dx + 160, rightTarget.dy)
      ..lineTo(rightTarget.dx - 160, rightTarget.dy)
      ..close();

    final rightPaint = Paint()
      ..shader = ui.Gradient.radial(
        rightOrigin,
        size.height * 0.9,
        [
          Brand.champagne.withValues(alpha: 0.28),
          Brand.champagne.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      );
    canvas.drawPath(rightBeam, rightPaint);
  }

  @override
  bool shouldRepaint(_StageSpotlightPainter old) => old.t != t;
}

class _AudioBarsVisualizer extends StatelessWidget {
  const _AudioBarsVisualizer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const barsCount = 28;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barsCount, (i) {
        final phase = (i / barsCount) * math.pi * 3;
        final wave = math.sin(progress * math.pi * 2 + phase).abs();
        final height = 6.0 + wave * 22.0;
        final color = Color.lerp(Brand.rose, Brand.champagne, i / barsCount)!;
        return Container(
          width: 3.5,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        );
      }),
    );
  }
}
