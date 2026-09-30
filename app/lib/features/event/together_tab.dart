import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/finding_widgets.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : ErrorRetry(error: boardError!, onRetry: loadBoard);
    }
    final me = data.me;
    if (me == null) return Center(child: Text(l10n.errorGeneric));
    final partner = data.byId(me.pairWith);
    final others = data.participants.where((p) => !p.isMe).toList();

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
      decoration: InputDecoration(labelText: l10n.partnerLabel),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                selector,
                const SizedBox(height: 16),
                if (partner == null)
                  NoticeBar(l10n.togetherNoPartner)
                else ...[
                  Text(
                    l10n.youAndPartner(partner.displayName),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, person) in [me, partner].indexed) ...[
                        if (index > 0) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                person.isMe ? l10n.you : person.displayName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              RenderView(
                                render: person.render,
                                photoUrl: person.photoUrl,
                                demo: data.event.demo,
                                compact: true,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatMoney(
                                  context,
                                  person.look.total,
                                  data.budget.currency,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pairFinding != null) FindingCard(finding: pairFinding),
                  Text(
                    l10n.lookTotal(
                      formatMoney(
                        context,
                        me.look.total + partner.look.total,
                        data.budget.currency,
                      ),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                for (final finding in selfFindings) ...[
                  const SizedBox(height: 8),
                  FindingCard(finding: finding),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.previewDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
