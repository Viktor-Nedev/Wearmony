import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../util/harmony_text.dart';
import '../../widgets/common.dart';
import '../../widgets/finding_widgets.dart';
import '../../widgets/fix_suggestions.dart';
import '../../widgets/render_view.dart';
import 'board_loader.dart';

/// "Me next to my partner": both looks in one frame with their color relation.
class TogetherTab extends StatefulWidget {
  const TogetherTab({super.key, required this.event});

  final EventInfo event;

  @override
  State<TogetherTab> createState() => _TogetherTabState();
}

class _TogetherTabState extends State<TogetherTab> with BoardLoader {
  @override
  String get boardEventId => widget.event.id;

  Future<void> _choosePartner(String? userId) async {
    final api = AppScope.api(context);
    await runWithFeedback(
      context,
      () => api.updateMe(
        widget.event.id,
        pairWith: userId,
        unpair: userId == null,
      ),
    );
    await loadBoard();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = board;
    if (data == null) {
      return boardError == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Skeleton(height: 420, radius: 26),
            )
          : ErrorRetry(error: boardError!, onRetry: loadBoard);
    }
    final me = data.me;
    if (me == null) return Center(child: Text(l10n.errorGeneric));
    final partner = data.byId(me.pairWith);
    final others = data.participants.where((p) => !p.isMe).toList();
    final text = Theme.of(context).textTheme;

    final pairFinding = partner == null
        ? null
        : data.harmony.findings
              .where(
                (f) =>
                    f.scope == 'pair' &&
                    f.people.contains(me.userId) &&
                    f.people.contains(partner.userId),
              )
              .firstOrNull;
    final selfFindings = data.harmony.findings
        .where(
          (f) =>
              f.scope == 'self' &&
              (f.people.contains(me.userId) ||
                  (partner != null && f.people.contains(partner.userId))),
        )
        .toList();

    final selector = DropdownButtonFormField<String?>(
      initialValue: partner?.userId,
      decoration: InputDecoration(
        labelText: l10n.partnerLabel,
        prefixIcon: const Icon(Icons.favorite_border),
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(l10n.noPartner)),
        for (final p in others)
          DropdownMenuItem<String?>(
            value: p.userId,
            child: Text(p.displayName),
          ),
      ],
      onChanged: _choosePartner,
    );

    Widget person(BoardParticipant p) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(p.isMe ? l10n.you : p.displayName, style: text.titleLarge),
        const SizedBox(height: 8),
        RenderView(
          render: p.render,
          photoUrl: p.photoUrl,
          demo: data.event.demo,
          compact: true,
        ),
        const SizedBox(height: 8),
        Text(
          formatMoney(context, p.look.total, data.budget.currency),
          style: text.titleSmall,
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CelebrationBanner(visible: clashFixed, text: l10n.clashFixed),
                Reveal(child: selector),
                const SizedBox(height: 20),
                if (partner == null)
                  Reveal(
                    delay: const Duration(milliseconds: 100),
                    child: NoticeBar(
                      l10n.togetherNoPartner,
                      icon: Icons.favorite_border,
                    ),
                  )
                else ...[
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: GradientText(
                      l10n.youAndPartner(partner.displayName),
                      style: text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 520;
                      final link = _HarmonyLink(
                        key: ValueKey(
                          '${partner.userId}-${pairFinding?.relation}',
                        ),
                        finding: pairFinding,
                        horizontal: narrow,
                      );
                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Reveal(
                                    delay: const Duration(milliseconds: 120),
                                    child: person(me),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Reveal(
                                    key: ValueKey(partner.userId),
                                    delay: const Duration(milliseconds: 200),
                                    child: person(partner),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Center(child: link),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Reveal(
                              delay: const Duration(milliseconds: 120),
                              offset: const Offset(-24, 0),
                              child: person(me),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: link,
                          ),
                          Expanded(
                            child: Reveal(
                              key: ValueKey(partner.userId),
                              delay: const Duration(milliseconds: 200),
                              offset: const Offset(24, 0),
                              child: person(partner),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  if (pairFinding != null)
                    Reveal(
                      delay: const Duration(milliseconds: 260),
                      child: FindingCard(finding: pairFinding),
                    ),
                  if (pairFinding != null && pairFinding.isWarning) ...[
                    const SizedBox(height: 18),
                    FixSuggestionsPanel(
                      eventId: widget.event.id,
                      target: pairFinding,
                      user: me.userId,
                      myUserId: me.userId,
                      currency: data.budget.currency,
                      onChanged: loadBoard,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    l10n.lookTotal(
                      formatMoney(
                        context,
                        me.look.total + partner.look.total,
                        data.budget.currency,
                      ),
                    ),
                    style: text.titleMedium,
                  ),
                ],
                for (final finding in selfFindings) ...[
                  const SizedBox(height: 8),
                  FindingCard(finding: finding),
                ],
                const SizedBox(height: 10),
                Text(l10n.previewDisclaimer, style: text.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The color relation between two people, drawn between their pictures.
class _HarmonyLink extends StatelessWidget {
  const _HarmonyLink({
    super.key,
    required this.finding,
    this.horizontal = false,
  });

  final HarmonyFinding? finding;

  /// Below the pictures on narrow screens; between them otherwise.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = finding;
    if (f == null) {
      return const Icon(Icons.favorite, color: Brand.rose, size: 32);
    }
    final color = relationColor(f.relation);
    final pair = ColorPair(
      a: hexColor(f.colors[0].hex),
      b: hexColor(f.colors[1].hex),
      size: 30,
    );
    final pill = RelationPill(
      relation: f.relation,
      label: relationName(l10n, f.relation),
    );
    final delta = Text(
      'ΔE ${f.deltaE.toStringAsFixed(1)}',
      style: Theme.of(context).textTheme.labelMedium,
    );

    final radius = horizontal ? 40.0 : 24.0;
    return Reveal(
      delay: const Duration(milliseconds: 320),
      scale: 0.8,
      child: PulseGlow(
        color: color,
        radius: radius,
        active: f.isWarning,
        child: Container(
          width: horizontal ? null : 132,
          padding: horizontal
              ? const EdgeInsets.symmetric(vertical: 12, horizontal: 18)
              : const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: horizontal
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pair,
                    const SizedBox(width: 12),
                    pill,
                    const SizedBox(width: 10),
                    delta,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pair,
                    const SizedBox(height: 10),
                    FittedBox(fit: BoxFit.scaleDown, child: pill),
                    const SizedBox(height: 6),
                    delta,
                  ],
                ),
        ),
      ),
    );
  }
}
