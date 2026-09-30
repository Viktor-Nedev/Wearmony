import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : ErrorRetry(error: boardError!, onRetry: loadBoard);
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final budget = data.budget;
    final weakest = data.harmony.weakest;

    return RefreshIndicator(
      onRefresh: loadBoard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.auto_fix_high, size: 18),
                label: Text(
                  l10n.boardRendered(data.renderedCount, data.participantCount),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.lock_outline, size: 18),
                label: Text(l10n.boardLocked(data.lockedCount)),
              ),
              if (data.harmony.groupScore != null)
                Chip(
                  avatar: Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: scoreColor(context, data.harmony.groupScore!),
                  ),
                  label: Text(l10n.groupHarmony(data.harmony.groupScore!)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.budgetTitle, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    budget.totalCap == null
                        ? formatMoney(context, budget.total, budget.currency)
                        : l10n.budgetTotalOf(
                            formatMoney(
                              context,
                              budget.totalCap!,
                              budget.currency,
                            ),
                            formatMoney(context, budget.total, budget.currency),
                          ),
                    style: text.headlineSmall?.copyWith(
                      color: budget.overTotal ? scheme.error : null,
                    ),
                  ),
                  if (budget.totalCap != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (budget.total / budget.totalCap!)
                          .clamp(0, 1)
                          .toDouble(),
                      color: budget.overTotal ? scheme.error : null,
                    ),
                  ],
                  if (budget.perPersonCap != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.budgetPerPersonCap(
                        formatMoney(
                          context,
                          budget.perPersonCap!,
                          budget.currency,
                        ),
                      ),
                    ),
                  ],
                  if (budget.overBudgetCount > 0)
                    Text(
                      l10n.overBudgetCount(budget.overBudgetCount),
                      style: TextStyle(color: scheme.error),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    data.units.mode == 'live'
                        ? l10n.unitsUsed(
                            data.units.cap.toStringAsFixed(0),
                            data.units.used.toStringAsFixed(0),
                          )
                        : l10n.unitsSimulated,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (weakest != null && weakest.isWarning) ...[
            const SizedBox(height: 12),
            NoticeBar(
              findingSentence(l10n, weakest),
              icon: Icons.warning_amber_outlined,
              tone: NoticeTone.warning,
            ),
          ],
          const SizedBox(height: 16),
          if (data.participants.isEmpty)
            NoticeBar(l10n.addPeopleHint(data.event.joinCode))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in data.participants)
                  _PersonCard(person: p, board: data),
              ],
            ),
        ],
      ),
    );
  }
}

Color scoreColor(BuildContext context, int score) {
  if (score >= 80) return Colors.green.shade700;
  if (score >= 60) return Colors.orange.shade700;
  return Theme.of(context).colorScheme.error;
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

    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: NetImage(person.pictureUrl),
                ),
                Positioned(
                  top: 8,
                  right: 8,
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
                        const _Badge(
                          child: Icon(Icons.error_outline, size: 16),
                        ),
                      if (render.resultUrl != null && render.mock)
                        _Badge(
                          child: Tooltip(
                            message: board.event.demo
                                ? l10n.demoRenderBadge
                                : l10n.mockBadge,
                            child: Icon(
                              board.event.demo
                                  ? Icons.brush_outlined
                                  : Icons.science_outlined,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.isMe
                        ? '${person.displayName} (${l10n.you})'
                        : person.displayName,
                    style: text.titleSmall,
                  ),
                  if (partner != null)
                    Text(
                      l10n.withPartner(partner.displayName),
                      style: text.bodySmall,
                    ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (person.pose == Pose.seated)
                        _Tag(icon: Icons.accessible, label: l10n.seatedLabel),
                      if (look.locked)
                        _Tag(icon: Icons.lock_outline, label: l10n.lockedLabel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (look.garment == null &&
                      look.makeup == null &&
                      look.hair == null)
                    Text(
                      person.hasPhoto ? l10n.noLookYet : l10n.noPhotoYet,
                      style: text.bodySmall,
                    )
                  else
                    for (final item in [look.garment, look.makeup, look.hair])
                      if (item != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              ColorDot(item.colorHex, size: 12),
                              const SizedBox(width: 6),
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
                  const SizedBox(height: 6),
                  Text(
                    formatMoney(context, look.total, board.budget.currency) +
                        (person.overBudget ? ' · ${l10n.overBudget}' : ''),
                    style: text.labelLarge?.copyWith(
                      color: person.overBudget ? scheme.error : null,
                    ),
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
  const _Badge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 4),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      shape: BoxShape.circle,
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
