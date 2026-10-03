import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../util/harmony_text.dart';
import '../../widgets/common.dart';
import 'board_loader.dart';

/// Everyone side by side with their current look, per-person and total budget,
/// render progress ("7 of 8 rendered") and the weakest color pair.
class BoardTab extends StatefulWidget {
  const BoardTab({super.key, required this.event});

  final EventInfo event;

  @override
  State<BoardTab> createState() => _BoardTabState();
}

class _BoardTabState extends State<BoardTab> with BoardLoader {
  @override
  String get boardEventId => widget.event.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = board;
    if (data == null) {
      return boardError == null
          ? const BoardSkeleton()
          : ErrorRetry(error: boardError!, onRetry: loadBoard);
    }
    final weakest = data.harmony.weakest;

    return RefreshIndicator(
      onRefresh: loadBoard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CelebrationBanner(visible: clashFixed, text: l10n.clashFixed),
                  _StatsRow(board: data),
                  if (weakest != null && weakest.isWarning) ...[
                    const SizedBox(height: 16),
                    Reveal(
                      delay: const Duration(milliseconds: 200),
                      child: PulseGlow(
                        color: const Color(0xFFC0392B),
                        radius: 20,
                        child: _WarningBanner(finding: weakest),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (data.participants.isEmpty)
                    NoticeBar(
                      l10n.addPeopleHint(data.event.joinCode),
                      icon: Icons.group_add_outlined,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = (constraints.maxWidth / 220)
                            .floor()
                            .clamp(2, 6);
                        final width =
                            (constraints.maxWidth - 14 * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final (index, person)
                                in data.participants.indexed)
                              SizedBox(
                                width: width,
                                child: Reveal(
                                  delay: Motion.stagger(index, stepMs: 70),
                                  child: _PersonCard(
                                    person: person,
                                    board: data,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final budget = board.budget;
    final scheme = Theme.of(context).colorScheme;
    final rendered = board.participantCount == 0
        ? 0.0
        : board.renderedCount / board.participantCount;

    final tiles = <Widget>[
      _StatTile(
        icon: Icons.auto_fix_high,
        label: l10n.statRendered,
        value: Text(
          l10n.boardRendered(board.renderedCount, board.participantCount),
          style: _valueStyle(context),
        ),
        footer: AnimatedBar(value: rendered, color: scheme.primary),
      ),
      _StatTile(
        icon: Icons.lock_outline,
        label: l10n.statLocked,
        value: CountUp(
          value: board.lockedCount.toDouble(),
          format: (v) => v.round().toString(),
          style: _valueStyle(context),
        ),
      ),
      if (board.harmony.groupScore != null)
        _StatTile(
          icon: Icons.palette_outlined,
          label: l10n.statHarmony,
          value: CountUp(
            value: board.harmony.groupScore!.toDouble(),
            format: (v) => '${v.round()}/100',
            style: _valueStyle(
              context,
            )?.copyWith(color: scoreColor(board.harmony.groupScore!)),
          ),
          footer: AnimatedBar(
            value: board.harmony.groupScore! / 100,
            color: scoreColor(board.harmony.groupScore!),
          ),
        ),
      _StatTile(
        icon: Icons.savings_outlined,
        label: l10n.statBudget,
        value: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            CountUp(
              value: budget.total,
              format: (v) => formatMoney(context, v, budget.currency),
              style: _valueStyle(
                context,
              )?.copyWith(color: budget.overTotal ? scheme.error : null),
            ),
            if (budget.totalCap != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.budgetOfCap(
                    formatMoney(context, budget.totalCap!, budget.currency),
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (budget.totalCap != null)
              AnimatedBar(
                value: budget.total / budget.totalCap!,
                color: budget.overTotal ? scheme.error : Brand.champagne,
              ),
            const SizedBox(height: 6),
            Text(
              [
                if (budget.perPersonCap != null)
                  l10n.budgetPerPersonCap(
                    formatMoney(context, budget.perPersonCap!, budget.currency),
                  ),
                if (budget.overBudgetCount > 0)
                  l10n.overBudgetCount(budget.overBudgetCount),
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: budget.overBudgetCount > 0 ? scheme.error : null,
              ),
            ),
            Text(
              board.units.mode == 'live'
                  ? l10n.unitsUsed(
                      board.units.cap.toStringAsFixed(0),
                      board.units.used.toStringAsFixed(0),
                    )
                  : l10n.unitsSimulated,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? tiles.length
            : (constraints.maxWidth >= 560 ? 2 : 1);
        // Rows of equal-height tiles, so the cards line up.
        return Column(
          children: [
            for (var start = 0; start < tiles.length; start += columns) ...[
              if (start > 0) const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < start + columns; i++) ...[
                      if (i > start) const SizedBox(width: 14),
                      Expanded(
                        child: i < tiles.length
                            ? Reveal(
                                delay: Motion.stagger(i, stepMs: 80),
                                child: tiles[i],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  TextStyle? _valueStyle(BuildContext context) =>
      Brand.numbers(Theme.of(context).textTheme.headlineSmall);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.footer,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            value,
            if (footer != null) ...[const SizedBox(height: 10), footer!],
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.finding});

  final HarmonyFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const red = Color(0xFFC0392B);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: red.withValues(alpha: dark ? 0.16 : 0.07),
        border: Border.all(color: red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          ColorPair(
            a: hexColor(finding.colors[0].hex),
            b: hexColor(finding.colors[1].hex),
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RelationPill(
                  relation: finding.relation,
                  label:
                      '${relationName(l10n, finding.relation)} · ΔE ${finding.deltaE.toStringAsFixed(1)}',
                ),
                const SizedBox(height: 8),
                Text(
                  findingSentence(l10n, finding),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.board});

  final BoardParticipant person;
  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final partner = board.byId(person.pairWith);
    final render = person.render;
    final look = person.look;

    return Hoverable(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(person.pictureUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xCC1A0F17),
                        ],
                        stops: [0, 0.55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.isMe
                              ? '${person.displayName} (${l10n.you})'
                              : person.displayName,
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (partner != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: Brand.rose,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  l10n.withPartner(partner.displayName),
                                  style: text.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        if (person.pose == Pose.seated)
                          _Badge(
                            icon: Icons.accessible,
                            tooltip: l10n.seatedLabel,
                          ),
                        if (look.locked)
                          _Badge(icon: Icons.lock, tooltip: l10n.lockedLabel),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        if (render.isRunning)
                          const _Badge(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        if (render.status == 'failed')
                          _Badge(
                            icon: Icons.error_outline,
                            tooltip: l10n.renderFailed,
                            color: scheme.error,
                          ),
                        if (render.status == 'success' && !render.mock)
                          const _Badge(icon: Icons.check, color: Brand.success),
                        if (render.resultUrl != null && render.mock)
                          _Badge(
                            icon: board.event.demo
                                ? Icons.brush_outlined
                                : Icons.science_outlined,
                            tooltip: board.event.demo
                                ? l10n.demoRenderBadge
                                : l10n.mockBadge,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room for all three items, so the cards in a row line up.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.textScalerOf(context).scale(57),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (look.garment == null &&
                            look.makeup == null &&
                            look.hair == null)
                          Text(
                            person.hasPhoto ? l10n.noLookYet : l10n.noPhotoYet,
                            style: text.bodySmall,
                          )
                        else
                          for (final item in [
                            look.garment,
                            look.makeup,
                            look.hair,
                          ])
                            if (item != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    ColorDot(item.colorHex, size: 12),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatMoney(context, look.total, board.budget.currency),
                        style: text.titleSmall?.copyWith(
                          color: person.overBudget ? scheme.error : null,
                        ),
                      ),
                      if (person.overBudget) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.overBudget,
                            style: text.labelSmall?.copyWith(
                              color: scheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({this.icon, this.child, this.tooltip, this.color});

  final IconData? icon;
  final Widget? child;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
        ],
      ),
      child: child ?? Icon(icon, size: 15, color: color ?? Brand.plum),
    );
    return tooltip == null ? badge : Tooltip(message: tooltip!, child: badge);
  }
}

/// Placeholder while the board loads.
class BoardSkeleton extends StatelessWidget {
  const BoardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < 4; i++)
              const SizedBox(width: 220, child: _SkeletonCard(height: 110)),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < 4; i++)
              const SizedBox(width: 200, child: _SkeletonCard(height: 300)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Skeleton(height: height, radius: 20);
}
