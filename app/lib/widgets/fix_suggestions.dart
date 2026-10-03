import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/models.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../ui/effects.dart';
import '../ui/harmony_visuals.dart';
import '../ui/motion.dart';
import '../util/format.dart';
import '../util/harmony_text.dart';
import 'common.dart';

/// "How to fix it": swaps from the event catalogue that remove a near-miss.
/// The harmony engine tries each item and keeps only real fixes, so every card
/// states what the swap would change (relation, group score, price).
class FixSuggestionsPanel extends StatefulWidget {
  const FixSuggestionsPanel({
    super.key,
    required this.eventId,
    required this.target,
    required this.currency,
    required this.onChanged,
    this.user,
    this.myUserId,
  });

  final String eventId;

  /// The near-miss shown above the panel; suggestions reload when it changes.
  final HarmonyFinding target;
  final String currency;

  /// Called after the viewer switched their look, to refresh the page.
  final Future<void> Function() onChanged;

  /// Ask for the weakest near-miss involving this person instead of the group's.
  final String? user;

  /// The viewer, who can switch their own look from a card.
  final String? myUserId;

  @override
  State<FixSuggestionsPanel> createState() => _FixSuggestionsPanelState();
}

class _FixSuggestionsPanelState extends State<FixSuggestionsPanel> {
  Future<FixSuggestions>? _future;
  String? _busyItem;

  static String _signature(HarmonyFinding f) =>
      '${f.scope}|${f.people.join(',')}|${f.subjects.join(',')}|${f.deltaE}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(FixSuggestionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.target) != _signature(widget.target)) {
      setState(() => _future = _load());
    }
  }

  Future<FixSuggestions> _load() =>
      AppScope.api(context).suggestions(widget.eventId, user: widget.user);

  Future<void> _apply(FixSuggestion s) async {
    final l10n = AppLocalizations.of(context);
    final api = AppScope.api(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyItem = s.itemId);
    final look = await runWithFeedback(
      context,
      () => api.setLook(
        widget.eventId,
        garmentId: s.itemType == ItemType.garment ? s.itemId : null,
        makeupId: s.itemType == ItemType.makeup ? s.itemId : null,
        hairId: s.itemType == ItemType.hair ? s.itemId : null,
      ),
    );
    if (!mounted) return;
    setState(() => _busyItem = null);
    if (look == null) return;
    await widget.onChanged();
    // Previewing is a separate, explicit step: in live mode a render spends units.
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.fixApplied),
        action: SnackBarAction(
          label: l10n.fixPreview,
          onPressed: () => unawaited(
            api
                .render(widget.eventId)
                .then((_) => widget.onChanged())
                .catchError((Object _) {}),
          ),
        ),
      ),
    );
  }

  void _copy(FixSuggestion s) {
    final l10n = AppLocalizations.of(context);
    final relation = relationName(l10n, s.relationAfter);
    final String text;
    if (s.otherName == null) {
      text = l10n.fixShareTextSelf(s.itemName, s.name, relation);
    } else if (s.otherUserId == widget.myUserId) {
      text = l10n.fixShareTextMe(s.itemName, s.name, relation);
    } else {
      text = l10n.fixShareText(s.itemName, s.name, s.otherName!, relation);
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.fixCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<FixSuggestions>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final data = snapshot.data;
        final header = Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: Brand.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_fix_high,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.fixTitle, style: text.titleLarge)),
          ],
        );
        Widget body;
        if (data == null) {
          body = const Row(
            children: [
              Expanded(child: Skeleton(height: 150, radius: 20)),
              SizedBox(width: 12),
              Expanded(child: Skeleton(height: 150, radius: 20)),
            ],
          );
        } else if (data.suggestions.isEmpty) {
          body = NoticeBar(l10n.fixNone, icon: Icons.lightbulb_outline);
        } else {
          body = _Cards(
            suggestions: data.suggestions,
            myUserId: widget.myUserId,
            currency: widget.currency,
            busyItem: _busyItem,
            onApply: _apply,
            onCopy: _copy,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 6),
            Text(l10n.fixSubtitle, style: text.bodySmall),
            const SizedBox(height: 14),
            AnimatedSwitcher(duration: Motion.medium, child: body),
          ],
        );
      },
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({
    required this.suggestions,
    required this.myUserId,
    required this.currency,
    required this.busyItem,
    required this.onApply,
    required this.onCopy,
  });

  final List<FixSuggestion> suggestions;
  final String? myUserId;
  final String currency;
  final String? busyItem;
  final ValueChanged<FixSuggestion> onApply;
  final ValueChanged<FixSuggestion> onCopy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : (constraints.maxWidth >= 500 ? 2 : 1);
        final rows = <Widget>[];
        for (var start = 0; start < suggestions.length; start += columns) {
          if (start > 0) rows.add(const SizedBox(height: 12));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < start + columns; i++) ...[
                    if (i > start) const SizedBox(width: 12),
                    Expanded(
                      child: i < suggestions.length
                          ? Reveal(
                              delay: Motion.stagger(i, stepMs: 90),
                              child: _SuggestionCard(
                                suggestion: suggestions[i],
                                mine: suggestions[i].userId == myUserId,
                                otherIsMe:
                                    suggestions[i].otherUserId != null &&
                                    suggestions[i].otherUserId == myUserId,
                                currency: currency,
                                busy: busyItem == suggestions[i].itemId,
                                disabled: busyItem != null,
                                onApply: () => onApply(suggestions[i]),
                                onCopy: () => onCopy(suggestions[i]),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.mine,
    required this.otherIsMe,
    required this.currency,
    required this.busy,
    required this.disabled,
    required this.onApply,
    required this.onCopy,
  });

  final FixSuggestion suggestion;
  final bool mine;
  final bool otherIsMe;
  final String currency;
  final bool busy;
  final bool disabled;
  final VoidCallback onApply;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = suggestion;
    final color = hexColor(s.colorHex);
    final relation = relationName(l10n, s.relationAfter);

    final String price;
    if (s.priceDelta.abs() < 0.005) {
      price = l10n.fixSamePrice;
    } else {
      final amount = formatMoney(context, s.priceDelta.abs(), currency);
      price = s.priceDelta > 0 ? '+$amount' : '−$amount';
    }

    final thumbnail = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: s.itemType == ItemType.garment && s.imageUrl != null
          ? Padding(
              padding: const EdgeInsets.all(5),
              child: NetImage(
                s.imageUrl,
                fit: BoxFit.contain,
                placeholderIcon: Icons.checkroom,
              ),
            )
          : Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
    );

    return Hoverable(
      child: HoverSpotlight(
        radius: 20,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    thumbnail,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ColorDot(s.colorHex, size: 10),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  mine ? l10n.you : s.name,
                                  style: text.labelLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.itemName,
                            style: text.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RelationPill(
                  relation: s.relationAfter,
                  label:
                      '${s.otherName == null ? l10n.fixWithOutfit(relation) : (otherIsMe ? l10n.fixWithYou(relation) : l10n.fixWith(s.otherName!, relation))} · ΔE ${s.deltaEAfter.toStringAsFixed(1)}',
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (s.groupScoreBefore != null && s.groupScoreAfter != null)
                      Expanded(
                        child: _ScoreChange(
                          before: s.groupScoreBefore!,
                          after: s.groupScoreAfter!,
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      price,
                      style: Brand.numbers(
                        text.titleSmall,
                      )?.copyWith(color: s.withinBudget ? null : scheme.error),
                    ),
                  ],
                ),
                if (s.warningsAfter > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.fixOthersLeft(s.warningsAfter),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!s.withinBudget) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.fixOverBudget,
                      style: text.labelSmall?.copyWith(color: scheme.error),
                    ),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: mine
                      ? FilledButton.icon(
                          onPressed: disabled ? null : onApply,
                          icon: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.swap_horiz_rounded),
                          label: Text(l10n.fixApply),
                        )
                      : OutlinedButton.icon(
                          onPressed: onCopy,
                          icon: const Icon(
                            Icons.content_copy_rounded,
                            size: 18,
                          ),
                          label: Text(l10n.fixCopy),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "46 → 100": the group score before and after, counting up to the new value.
class _ScoreChange extends StatelessWidget {
  const _ScoreChange({required this.before, required this.after});

  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final style = Brand.numbers(text.titleMedium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.fixScore, style: text.labelSmall),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              '$before',
              style: style?.copyWith(
                color: scoreColor(before),
                decoration: TextDecoration.lineThrough,
                decorationColor: scoreColor(before).withValues(alpha: 0.6),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.east_rounded, size: 16),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: Motion.reduced(context)
                    ? after.toDouble()
                    : before.toDouble(),
                end: after.toDouble(),
              ),
              duration: const Duration(milliseconds: 1100),
              curve: Motion.emphasized,
              builder: (context, v, _) => Text(
                '${v.round()}',
                style: style?.copyWith(color: scoreColor(v.round())),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
