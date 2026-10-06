import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models.dart';
import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';

/// Where the money goes: outfits, lip and hair colors, and each person against the cap.
class BudgetBreakdown extends StatelessWidget {
  const BudgetBreakdown({super.key, required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final budget = board.budget;
    double sum(ItemSummary? Function(BoardLook look) pick) => board.participants
        .map((p) => pick(p.look)?.price ?? 0)
        .fold(0.0, (a, b) => a + b);
    final parts = [
      (l10n.sectionOutfit, sum((l) => l.garment), Brand.plum),
      (l10n.sectionMakeup, sum((l) => l.makeup), Brand.berry),
      (l10n.sectionHair, sum((l) => l.hair), Brand.champagne),
    ];
    final people = [...board.participants]
      ..sort((a, b) => b.look.total.compareTo(a.look.total));
    final cap = budget.perPersonCap;
    final top = people.isEmpty ? 0.0 : people.first.look.total;
    final scale = math.max(math.max(cap ?? 0, top) * 1.12, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(icon: Icons.savings_outlined, title: l10n.budgetTitle),
            const SizedBox(height: 16),
            _SplitBar(parts: parts),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final (label, amount, color) in parts)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$label · ${formatMoney(context, amount, budget.currency)}',
                        style: text.labelMedium,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            for (final (index, person) in people.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PersonBudget(
                  person: person,
                  cap: cap,
                  scale: scale,
                  currency: budget.currency,
                  delay: Motion.stagger(index, stepMs: 70),
                ),
              ),
            if (cap != null)
              Text(
                l10n.budgetPerPersonCap(
                  formatMoney(context, cap, budget.currency),
                ),
                style: text.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
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
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    );
  }
}

/// One bar split into the three kinds of spending; the segments grow in.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.parts});

  final List<(String, double, Color)> parts;

  @override
  Widget build(BuildContext context) {
    final total = parts.fold(0.0, (sum, p) => sum + p.$2);
    final track = Theme.of(context).colorScheme.surfaceContainerHigh;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: Motion.reduced(context) ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Motion.emphasized,
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 16,
          child: total <= 0
              ? ColoredBox(color: track)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (_, amount, color) in parts)
                      if (amount > 0)
                        Expanded(
                          flex: math.max(
                            1,
                            (amount / total * 1000 * t).round(),
                          ),
                          child: ColoredBox(color: color),
                        ),
                    Expanded(
                      flex: math.max(1, ((1 - t) * 1000).round()),
                      child: ColoredBox(color: track),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PersonBudget extends StatelessWidget {
  const _PersonBudget({
    required this.person,
    required this.cap,
    required this.scale,
    required this.currency,
    required this.delay,
  });

  final BoardParticipant person;
  final double? cap;
  final double scale;
  final String currency;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final total = person.look.total;
    final over = person.overBudget;
    return Row(
      children: [
        SizedBox(
          width: 108,
          child: Row(
            children: [
              ColorDot(person.look.garment?.colorHex, size: 12),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  person.isMe ? l10n.you : person.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 20,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    ScrollAnimated(
                      delay: delay,
                      duration: const Duration(milliseconds: 900),
                      builder: (context, t, _) => Container(
                        width: width * (total / scale).clamp(0.0, 1.0) * t,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            colors: over
                                ? [scheme.error, scheme.error]
                                : const [Brand.plum, Color(0xFFE38FA8)],
                          ),
                        ),
                      ),
                    ),
                    if (cap != null)
                      Positioned(
                        left: width * (cap! / scale) - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 86,
          child: Text(
            formatMoney(context, total, currency),
            textAlign: TextAlign.end,
            style: Brand.numbers(
              text.labelLarge,
            )?.copyWith(color: over ? scheme.error : null),
          ),
        ),
      ],
    );
  }
}

/// Who is ready for the night: photo, look, preview and locked, per person.
class ReadinessTracker extends StatelessWidget {
  const ReadinessTracker({super.key, required this.board});

  final Board board;

  static List<bool> steps(BoardParticipant p) => [
    p.hasPhoto,
    p.look.garment != null,
    p.render.status == 'success',
    p.look.locked,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final people = board.participants;
    final done = people.fold<int>(
      0,
      (sum, p) => sum + steps(p).where((s) => s).length,
    );
    final total = people.length * 4;
    final share = total == 0 ? 0.0 : done / total;
    final labels = [
      l10n.readinessPhoto,
      l10n.readinessLook,
      l10n.readinessPreview,
      l10n.readinessLocked,
    ];
    final notReady = people.any((p) => !p.look.locked);

    String next(BoardParticipant p) {
      final s = steps(p);
      if (!s[0]) return l10n.nextPhoto;
      if (!s[1]) return l10n.nextLook;
      if (!s[2]) return l10n.nextPreview;
      if (!s[3]) return l10n.nextLock;
      return l10n.nextDone;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(
              icon: Icons.task_alt_rounded,
              title: l10n.readinessTitle,
              trailing: CountUp(
                value: share * 100,
                format: (v) => '${v.round()}%',
                style: Brand.numbers(text.titleMedium),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBar(value: share, color: Brand.success),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                for (final label in labels)
                  SizedBox(
                    width: 58,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: text.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (final (index, person) in people.indexed)
              RevealOnScroll(
                delay: Motion.stagger(index, stepMs: 60),
                offset: const Offset(0, 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      ColorDot(person.look.garment?.colorHex, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.isMe ? l10n.you : person.displayName,
                              style: text.labelLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              next(person),
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      for (final (i, ok) in steps(person).indexed)
                        SizedBox(
                          width: 58,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: Motion.medium,
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Icon(
                                ok
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                key: ValueKey('$i-$ok'),
                                size: 20,
                                color: ok
                                    ? Brand.success
                                    : scheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (board.event.isOrganizer && notReady) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: l10n.reminderText(
                          board.event.name,
                          appLink('/join/${board.event.joinCode}'),
                        ),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.reminderCopied)),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(l10n.reminderCopy),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What happened lately, newest first, as a small timeline. New entries slide
/// in at the top when the board refreshes.
class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key, required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final me = board.me?.userId;

    String sentence(ActivityEntry entry) {
      final mine = entry.userId == me;
      final name = mine ? l10n.you : entry.name;
      return switch (entry.kind) {
        'look' => l10n.activityLook(entry.item ?? '', name),
        'locked' => mine ? l10n.activityLockedYou : l10n.activityLocked(name),
        'previewed' =>
          mine ? l10n.activityPreviewedYou : l10n.activityPreviewed(name),
        'asked' => mine ? l10n.activityAskedYou : l10n.activityAsked(name),
        'voted' =>
          mine
              ? l10n.activityVotedYou(entry.item ?? '')
              : l10n.activityVoted(name, entry.item ?? ''),
        _ => l10n.activityJoined(name),
      };
    }

    IconData icon(String kind) => switch (kind) {
      'look' => Icons.checkroom,
      'locked' => Icons.lock_outline_rounded,
      'previewed' => Icons.auto_fix_high,
      'asked' => Icons.how_to_vote_outlined,
      'voted' => Icons.favorite_border,
      _ => Icons.person_add_alt_1_outlined,
    };

    final entries = board.activity;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(icon: Icons.history_rounded, title: l10n.activityTitle),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Text(l10n.activityEmpty, style: text.bodySmall)
            else
              for (final (index, entry) in entries.indexed)
                Reveal(
                  key: ValueKey(
                    '${entry.kind}-${entry.userId}-${entry.at.toIso8601String()}',
                  ),
                  offset: const Offset(0, -10),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hexColor(
                                    board
                                        .byId(entry.userId)
                                        ?.look
                                        .garment
                                        ?.colorHex,
                                    fallback: scheme.primary,
                                  ).withValues(alpha: 0.18),
                                ),
                                child: Icon(
                                  icon(entry.kind),
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ),
                              if (index < entries.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 5,
                              bottom: index < entries.length - 1 ? 12 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sentence(entry), style: text.bodyMedium),
                                const SizedBox(height: 2),
                                Text(
                                  timeAgo(l10n, entry.at.toLocal()),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
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
          ],
        ),
      ),
    );
  }
}
