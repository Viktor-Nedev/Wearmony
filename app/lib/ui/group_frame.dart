import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'figure.dart';
import 'harmony_visuals.dart';
import 'motion.dart';

/// Backdrops for the group photo, all painted in code.
enum FrameBackdrop {
  ballroom(dark: true),
  stage(dark: true),
  garden(dark: false),
  studio(dark: false);

  const FrameBackdrop({required this.dark});

  /// Light text goes on dark backdrops.
  final bool dark;

  static FrameBackdrop forTemplate(EventTemplate template) =>
      switch (template) {
        EventTemplate.prom => ballroom,
        EventTemplate.theatre => stage,
        EventTemplate.group => garden,
      };
}

String backdropName(AppLocalizations l10n, FrameBackdrop backdrop) =>
    switch (backdrop) {
      FrameBackdrop.ballroom => l10n.backdropBallroom,
      FrameBackdrop.stage => l10n.backdropStage,
      FrameBackdrop.garden => l10n.backdropGarden,
      FrameBackdrop.studio => l10n.backdropStudio,
    };

/// Everyone's current look in one frame: a lineup on a themed backdrop, with the
/// harmony score, the group's palette and honest labels for simulated content.
/// Sizes scale with the width, so the saved image looks the same on any screen.
class GroupFrame extends StatelessWidget {
  const GroupFrame({super.key, required this.board, required this.backdrop});

  final Board board;
  final FrameBackdrop backdrop;

  /// Partners stand next to each other.
  static List<BoardParticipant> lineup(Board board) {
    final placed = <String>{};
    final order = <BoardParticipant>[];
    for (final person in board.participants) {
      if (!placed.add(person.userId)) continue;
      order.add(person);
      final partner = board.byId(person.pairWith);
      if (partner != null && placed.add(partner.userId)) order.add(partner);
    }
    return order;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final portrait = width < 560;
        final height = portrait ? width * 1.3 : width * 0.6;
        final unit = width / 100;
        final people = lineup(board);
        final ink = backdrop.dark ? Colors.white : Brand.plumDeep;
        final pad = unit * (portrait ? 5 : 3.2);
        final titleHeight = unit * (portrait ? 23 : 9);
        final footerHeight = unit * (portrait ? 12 : 6.5);

        final l10n = AppLocalizations.of(context);
        return Semantics(
          image: true,
          label: l10n.frameSemantics(
            board.event.name,
            people.map((p) => p.isMe ? l10n.you : p.displayName).join(', '),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(unit * 2.4),
              child: Stack(
                children: [
                  Positioned.fill(child: _Backdrop(kind: backdrop)),
                  Positioned(
                    left: pad,
                    right: pad,
                    top: pad,
                    child: _TitleBlock(
                      board: board,
                      ink: ink,
                      unit: unit,
                      portrait: portrait,
                    ),
                  ),
                  Positioned(
                    left: pad,
                    right: pad,
                    top: pad + titleHeight,
                    bottom: pad + footerHeight,
                    child: people.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context).frameEmpty,
                              style: TextStyle(
                                color: ink,
                                fontSize: unit * 2.6,
                              ),
                            ),
                          )
                        : _Lineup(
                            people: people,
                            board: board,
                            ink: ink,
                            unit: unit,
                            perRow: portrait ? 3 : 7,
                          ),
                  ),
                  Positioned(
                    left: pad,
                    right: pad,
                    bottom: pad,
                    child: _Footer(
                      board: board,
                      people: people,
                      ink: ink,
                      unit: unit,
                      portrait: portrait,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.board,
    required this.ink,
    required this.unit,
    required this.portrait,
  });

  final Board board;
  final Color ink;
  final double unit;
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final score = board.harmony.groupScore;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          board.event.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: Brand.displayFont,
            fontWeight: FontWeight.w700,
            fontSize: unit * (portrait ? 6.4 : 3.6),
            height: 1.1,
            color: ink,
          ),
        ),
        SizedBox(height: unit * 0.6),
        Text(
          [
            templateName(l10n, board.event.template),
            if (board.event.eventDate != null)
              formatEventDay(context, board.event.eventDate!),
            l10n.framePeople(board.participantCount),
          ].join(' · '),
          style: TextStyle(
            fontSize: unit * (portrait ? 3.4 : 1.6),
            fontWeight: FontWeight.w600,
            color: ink.withValues(alpha: 0.75),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
    final badge = score == null
        ? null
        : Container(
            padding: EdgeInsets.symmetric(
              horizontal: unit * (portrait ? 3 : 1.4),
              vertical: unit * (portrait ? 1.6 : 0.7),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(unit * 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: unit * 2,
                  offset: Offset(0, unit * 0.6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: unit * (portrait ? 2.6 : 1.2),
                  height: unit * (portrait ? 2.6 : 1.2),
                  decoration: BoxDecoration(
                    color: scoreColor(score),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: unit * (portrait ? 1.6 : 0.7)),
                Text(
                  l10n.frameHarmony(score),
                  style: TextStyle(
                    fontFamily: Brand.bodyFont,
                    fontWeight: FontWeight.w800,
                    fontSize: unit * (portrait ? 3.2 : 1.5),
                    color: Brand.plumDeep,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
    if (portrait) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          if (badge != null) ...[SizedBox(height: unit * 2), badge],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        if (badge != null) badge,
      ],
    );
  }
}

/// People in one or two rows, overlapping a little like in a real group photo.
class _Lineup extends StatelessWidget {
  const _Lineup({
    required this.people,
    required this.board,
    required this.ink,
    required this.unit,
    required this.perRow,
  });

  final List<BoardParticipant> people;
  final Board board;
  final Color ink;
  final double unit;
  final int perRow;

  static const _aspect = 1.42;
  static const _overlap = 0.08;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = people.length <= perRow
            ? [people]
            : [
                people.sublist(0, (people.length / 2).ceil()),
                people.sublist((people.length / 2).ceil()),
              ];
        final rowHeight = constraints.maxHeight / rows.length;
        final plaque = unit * (perRow <= 3 ? 7 : 3.4);
        final children = <Widget>[];
        // Hearts go on top of every portrait, so the next one cannot cover them.
        final hearts = <Widget>[];
        var index = 0;
        for (final (r, row) in rows.indexed) {
          final n = row.length;
          final byWidth = constraints.maxWidth / (n - (n - 1) * _overlap);
          final byHeight = (rowHeight - plaque) / _aspect;
          final cardWidth = math.min(math.min(byWidth, byHeight), unit * 24);
          final cardHeight = cardWidth * _aspect;
          final total = cardWidth * (n - (n - 1) * _overlap);
          final left = (constraints.maxWidth - total) / 2;
          final top = rowHeight * r + (rowHeight - cardHeight - plaque);
          for (final (i, person) in row.indexed) {
            final partnerNext =
                i + 1 < n && row[i + 1].userId == person.pairWith;
            children.add(
              Positioned(
                left: left + i * cardWidth * (1 - _overlap),
                top: top,
                width: cardWidth,
                height: cardHeight + plaque,
                child: Reveal(
                  delay: Motion.stagger(index, stepMs: 90),
                  offset: Offset(0, unit * 3),
                  child: _Portrait(
                    person: person,
                    board: board,
                    unit: unit,
                    cardHeight: cardHeight,
                    plaque: plaque,
                    ink: ink,
                  ),
                ),
              ),
            );
            if (partnerNext) {
              final heart = unit * (perRow <= 3 ? 5 : 2.4);
              hearts.add(
                Positioned(
                  left:
                      left +
                      (i + 1) * cardWidth * (1 - _overlap) -
                      heart / 2 +
                      cardWidth * _overlap / 2,
                  top: top + cardHeight * 0.78,
                  width: heart,
                  height: heart,
                  child: Reveal(
                    delay: Motion.stagger(index + 3, stepMs: 90),
                    scale: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: heart / 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Brand.berry,
                        size: heart * 0.6,
                      ),
                    ),
                  ),
                ),
              );
            }
            index++;
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [...children, ...hearts],
        );
      },
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.person,
    required this.board,
    required this.unit,
    required this.cardHeight,
    required this.plaque,
    required this.ink,
  });

  final BoardParticipant person;
  final Board board;
  final double unit;
  final double cardHeight;
  final double plaque;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outfit = hexColor(person.look.garment?.colorHex);
    final radius = Radius.circular(cardHeight);
    final picture = person.pictureUrl;
    return Column(
      children: [
        Container(
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: radius,
              bottom: Radius.circular(unit * 1.2),
            ),
            border: Border.all(color: Colors.white, width: unit * 0.35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: unit * 2.4,
                offset: Offset(0, unit * 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: radius,
              bottom: Radius.circular(unit * 0.9),
            ),
            child: picture != null
                ? NetImage(picture)
                : ColoredBox(
                    color: const Color(0xFFEDE7EA),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: Figure(
                          clothing: person.look.garment == null
                              ? const Color(0xFFBDB3B8)
                              : outfit,
                          seated: person.pose == Pose.seated,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(height: plaque * 0.18),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: plaque * 0.32,
            vertical: plaque * 0.1,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(plaque),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: plaque * 0.3,
                height: plaque * 0.3,
                decoration: BoxDecoration(
                  color: person.look.garment == null
                      ? Colors.transparent
                      : outfit,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
              SizedBox(width: plaque * 0.14),
              Flexible(
                child: Text(
                  person.isMe ? l10n.you : person.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: plaque * 0.36,
                    fontWeight: FontWeight.w700,
                    color: Brand.plumDeep,
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.board,
    required this.people,
    required this.ink,
    required this.unit,
    required this.portrait,
  });

  final Board board;
  final List<BoardParticipant> people;
  final Color ink;
  final double unit;
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = [
      for (final p in people)
        if (p.look.garment != null) hexColor(p.look.garment!.colorHex),
    ];
    final simulated = board.participants.any(
      (p) => p.render.resultUrl != null && p.render.mock,
    );
    final honesty = board.event.demo
        ? l10n.frameHonestDemo
        : (simulated ? l10n.frameHonestMock : l10n.frameHonestReal);
    final small = TextStyle(
      fontSize: unit * (portrait ? 2.7 : 1.25),
      fontWeight: FontWeight.w600,
      color: ink.withValues(alpha: 0.85),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (colors.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(unit),
            child: SizedBox(
              height: unit * (portrait ? 2 : 0.9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final color in colors)
                    Expanded(child: ColoredBox(color: color)),
                ],
              ),
            ),
          ),
        SizedBox(height: unit * (portrait ? 2 : 0.9)),
        Row(
          children: [
            Text(
              'Wearmony',
              style: TextStyle(
                fontFamily: Brand.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: unit * (portrait ? 3.4 : 1.6),
                color: ink,
              ),
            ),
            SizedBox(width: unit),
            Expanded(
              child: Text(
                honesty,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: small,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The painted, softly animated backdrop.
class _Backdrop extends StatefulWidget {
  const _Backdrop({required this.kind});

  final FrameBackdrop kind;

  @override
  State<_Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<_Backdrop>
    with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(seconds: 6);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: loop == null
          ? CustomPaint(painter: _BackdropPainter(widget.kind, 0.25))
          : AnimatedBuilder(
              animation: loop!,
              builder: (context, _) => CustomPaint(
                painter: _BackdropPainter(widget.kind, loop!.value),
              ),
            ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.kind, this.t);

  final FrameBackdrop kind;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (kind) {
      case FrameBackdrop.ballroom:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topCenter,
              rect.bottomCenter,
              const [Color(0xFF2A0F22), Color(0xFF5A1F40), Color(0xFF1C0B16)],
              const [0, 0.55, 1],
            ),
        );
        _glow(
          canvas,
          size,
          Offset(size.width / 2, -size.height * 0.1),
          0.9,
          const Color(0xFFF3D9A4),
          0.32,
        );
        _bokeh(
          canvas,
          size,
          const [Color(0xFFF3D9A4), Color(0xFFE8A0B4), Color(0xFFFFFFFF)],
          34,
          11,
        );
        _floor(canvas, size, const Color(0xFF12060E), 0.5);
      case FrameBackdrop.stage:
        canvas.drawRect(rect, Paint()..color = const Color(0xFF1A0508));
        _glow(
          canvas,
          size,
          Offset(size.width / 2, size.height * 0.05),
          0.85,
          const Color(0xFFFFF1D6),
          0.38,
        );
        _curtains(canvas, size);
        _floor(canvas, size, const Color(0xFF3B2418), 0.85);
      case FrameBackdrop.garden:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topCenter,
              rect.bottomCenter,
              const [Color(0xFFF4F1E4), Color(0xFFD9E8D2), Color(0xFFB9D3B4)],
              const [0, 0.6, 1],
            ),
        );
        _glow(
          canvas,
          size,
          Offset(size.width * 0.82, size.height * 0.08),
          0.7,
          const Color(0xFFFFF0B8),
          0.55,
        );
        _bokeh(
          canvas,
          size,
          const [Color(0xFF8DB580), Color(0xFFFFF0B8), Color(0xFFFFFFFF)],
          26,
          23,
        );
        _floor(canvas, size, const Color(0xFF7FA374), 0.35);
      case FrameBackdrop.studio:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(size.width / 2, size.height * 0.42),
              size.longestSide * 0.75,
              const [Color(0xFFFFFCF8), Color(0xFFF1E8E1), Color(0xFFDCCFC6)],
              const [0, 0.6, 1],
            ),
        );
        _floor(canvas, size, const Color(0xFFCDBFB5), 0.45);
    }
  }

  void _glow(
    Canvas canvas,
    Size size,
    Offset center,
    double reach,
    Color color,
    double alpha,
  ) {
    canvas.drawCircle(
      center,
      size.longestSide * reach,
      Paint()
        ..shader = ui.Gradient.radial(center, size.longestSide * reach, [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]),
    );
  }

  /// Out-of-focus lights; positions are fixed by [seed], brightness twinkles with [t].
  void _bokeh(
    Canvas canvas,
    Size size,
    List<Color> colors,
    int count,
    int seed,
  ) {
    final random = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.75,
      );
      final radius = size.shortestSide * (0.012 + random.nextDouble() * 0.05);
      final phase = random.nextDouble();
      final base = 0.12 + random.nextDouble() * 0.3;
      final alpha = base * (0.6 + 0.4 * math.sin(2 * math.pi * (t + phase)));
      final color = colors[i % colors.length];
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.6),
              color.withValues(alpha: 0),
            ],
            const [0, 0.7, 1],
          ),
      );
    }
  }

  void _floor(Canvas canvas, Size size, Color color, double alpha) {
    final top = size.height * 0.78;
    final floor = Rect.fromLTRB(0, top, size.width, size.height);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = ui.Gradient.linear(floor.topCenter, floor.bottomCenter, [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha),
        ]),
    );
  }

  /// Red stage curtains on both sides and a scalloped valance on top.
  void _curtains(Canvas canvas, Size size) {
    final drape = size.width * 0.14;
    const folds = 5;
    for (final side in [0, 1]) {
      for (var f = 0; f < folds; f++) {
        final w = drape / folds;
        final x = side == 0 ? f * w : size.width - drape + f * w;
        final fold = Rect.fromLTWH(x, 0, w + 1, size.height);
        canvas.drawRect(
          fold,
          Paint()
            ..shader = ui.Gradient.linear(
              fold.centerLeft,
              fold.centerRight,
              const [Color(0xFF4A0811), Color(0xFF9B1C2E), Color(0xFF4A0811)],
            ),
        );
      }
    }
    final valance = size.height * 0.09;
    final scallops = 9;
    final path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, valance * 0.7);
    for (var i = scallops; i > 0; i--) {
      final x0 = size.width * i / scallops;
      final x1 = size.width * (i - 1) / scallops;
      path.quadraticBezierTo((x0 + x1) / 2, valance * 1.35, x1, valance * 0.7);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, valance * 1.2),
          const [Color(0xFF7E1524), Color(0xFF5A0D18)],
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.004
        ..color = const Color(0xFFD9B77E),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.kind != kind || old.t != t;
}
