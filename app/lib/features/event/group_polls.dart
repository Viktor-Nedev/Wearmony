import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/confetti.dart';
import '../../ui/effects.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';

/// "Ask the group": open questions where a participant offers two or three
/// outfits, the others vote, and each option shows what it would do to the
/// group's colors. Votes are advice; only the person who asks changes their look.
class GroupPolls extends StatelessWidget {
  const GroupPolls({super.key, required this.board, required this.onChanged});

  final Board board;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final me = board.me;
    final canAsk =
        me != null && !me.look.locked && !board.polls.any((p) => p.isMine);
    if (board.polls.isEmpty && !canAsk) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: Brand.gradient,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.how_to_vote_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.pollTitle, style: text.titleLarge)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.pollHint,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            for (final (index, poll) in board.polls.indexed) ...[
              const SizedBox(height: 16),
              Reveal(
                delay: Motion.stagger(index, stepMs: 90),
                child: _PollCard(
                  key: ValueKey('poll_${poll.ownerId}'),
                  poll: poll,
                  board: board,
                  onChanged: onChanged,
                ),
              ),
            ],
            if (canAsk) ...[
              const SizedBox(height: 16),
              _AskPrompt(board: board, onChanged: onChanged),
            ],
          ],
        ),
      ),
    );
  }
}

class _AskPrompt extends StatelessWidget {
  const _AskPrompt({required this.board, required this.onChanged});

  final Board board;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pollAskCta,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.pollAskCtaHint,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
    final button = BrandButton(
      label: l10n.pollTitle,
      icon: Icons.how_to_vote_outlined,
      expand: narrow,
      onPressed: () async {
        final sent = await showAskGroupSheet(context, board.event.id);
        if (sent) await onChanged();
      },
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.rose.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          colors: [
            Brand.rose.withValues(alpha: 0.12),
            Brand.champagne.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 12), button],
            )
          : Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 16),
                button,
              ],
            ),
    );
  }
}

class _PollCard extends StatefulWidget {
  const _PollCard({
    super.key,
    required this.poll,
    required this.board,
    required this.onChanged,
  });

  final GroupPoll poll;
  final Board board;
  final Future<void> Function() onChanged;

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final done = await runWithFeedback(context, () async {
      await action();
      return true;
    }, success: success);
    if (done == true) await widget.onChanged();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _vote(PollOption option) {
    final api = AppScope.api(context);
    final eventId = widget.board.event.id;
    final poll = widget.poll;
    return _run(
      () => poll.myVote == option.itemId
          ? api.unvote(eventId, poll.ownerId)
          : api.vote(eventId, poll.ownerId, option.itemId),
    );
  }

  Future<void> _choose(PollOption option) async {
    final l10n = AppLocalizations.of(context);
    final api = AppScope.api(context);
    final confetti = ConfettiCannon.of(context);
    final eventId = widget.board.event.id;
    if (!await confirm(
      context,
      l10n.pollChooseConfirm(option.name),
      action: l10n.pollChoose,
    )) {
      return;
    }
    await _run(() async {
      await api.choosePollOption(eventId, option.itemId);
      confetti.burst(count: 70);
    }, success: l10n.pollChosen);
  }

  Future<void> _close() async {
    final l10n = AppLocalizations.of(context);
    final api = AppScope.api(context);
    final eventId = widget.board.event.id;
    if (!await confirm(
      context,
      l10n.pollCloseConfirm,
      action: l10n.pollClose,
    )) {
      return;
    }
    await _run(() => api.closePoll(eventId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final poll = widget.poll;
    final owner = widget.board.byId(poll.ownerId);
    final maxVotes = poll.options.fold<int>(
      0,
      (m, o) => o.votes > m ? o.votes : m,
    );

    final tiles = [
      for (final (index, option) in poll.options.indexed)
        Reveal(
          delay: Motion.stagger(index, stepMs: 80),
          child: _OptionTile(
            option: option,
            poll: poll,
            maxVotes: maxVotes,
            currency: widget.board.budget.currency,
            busy: _busy,
            onVote: poll.canVote ? () => _vote(option) : null,
            onChoose: poll.isMine ? () => _choose(option) : null,
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: NetImage(owner?.photoUrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  poll.isMine ? l10n.pollYouAsk : l10n.pollAsks(poll.ownerName),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _VoteCount(count: poll.totalVotes),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, tile) in tiles.indexed) ...[
                      if (i > 0) const SizedBox(height: 10),
                      tile,
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, tile) in tiles.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: tile),
                    ],
                  ],
                ),
              );
            },
          ),
          if (poll.isMine)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _busy ? null : _close,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(l10n.pollClose),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VoteCount extends StatelessWidget {
  const _VoteCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: Motion.medium,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          l10n.pollVotes(count),
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.option,
    required this.poll,
    required this.maxVotes,
    required this.currency,
    required this.busy,
    required this.onVote,
    required this.onChoose,
  });

  final PollOption option;
  final GroupPoll poll;
  final int maxVotes;
  final String currency;
  final bool busy;
  final VoidCallback? onVote;
  final VoidCallback? onChoose;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  final _sparkles = GlobalKey<SparkleBurstState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final option = widget.option;
    final poll = widget.poll;
    final mine = poll.myVote == option.itemId;
    final current = poll.currentGarmentId == option.itemId;
    final highlight = mine || option.leading;

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.curve,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mine
              ? Brand.berry
              : option.leading
              ? Brand.champagne
              : scheme.outlineVariant,
          width: highlight ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: (mine ? Brand.berry : Brand.champagne).withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 130,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(
                  option.imageUrl,
                  fit: BoxFit.contain,
                  placeholderIcon: Icons.checkroom,
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  // Pops in and out, and is gone (not just invisible) when not leading.
                  child: _PopIn(
                    child: option.leading
                        ? _Tag(
                            icon: Icons.emoji_events_rounded,
                            label: l10n.pollLeading,
                            color: Brand.champagne,
                          )
                        : null,
                  ),
                ),
                if (current)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _Tag(
                      icon: Icons.checkroom,
                      label: l10n.pollCurrent,
                      color: scheme.primary,
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: ColorDot(option.colorHex, size: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  formatMoney(context, option.price, widget.currency),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _HarmonyHint(harmony: option.harmony),
                const SizedBox(height: 10),
                Tooltip(
                  message: option.voters.join(', '),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedBar(
                          value: widget.maxVotes == 0
                              ? 0
                              : option.votes / widget.maxVotes,
                          color: option.leading ? Brand.berry : Brand.rose,
                          height: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${option.votes}',
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onVote != null) ...[
                  const SizedBox(height: 10),
                  SparkleBurst(
                    key: _sparkles,
                    child: SizedBox(
                      width: double.infinity,
                      child: mine
                          ? FilledButton.icon(
                              onPressed: widget.busy ? null : widget.onVote,
                              icon: const Icon(Icons.favorite, size: 18),
                              label: Text(l10n.pollYourVote),
                            )
                          : OutlinedButton.icon(
                              onPressed: widget.busy
                                  ? null
                                  : () {
                                      _sparkles.currentState?.burst();
                                      widget.onVote!();
                                    },
                              icon: const Icon(Icons.favorite_border, size: 18),
                              label: Text(l10n.pollVote),
                            ),
                    ),
                  ),
                ],
                if (widget.onChoose != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.busy || current ? null : widget.onChoose,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.pollChoose),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the option would do to the group's colors, in a few words.
class _HarmonyHint extends StatelessWidget {
  const _HarmonyHint({required this.harmony});

  final PollOptionHarmony? harmony;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h = harmony;
    // Without colors to compare, say nothing rather than guess.
    if (h == null || (h.groupScore == null && h.ownWarnings == 0)) {
      return const SizedBox.shrink();
    }
    final (relation, label) = h.ownWarnings > 0
        ? ('near_miss', l10n.pollNearMisses(h.ownWarnings))
        : h.partnerRelation == 'matched'
        ? ('matched', l10n.pollMatchesPartner)
        : ('matched', l10n.pollNoNearMiss);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RelationPill(relation: relation, label: label),
        // The group score also covers pairs this option does not touch, so no warning color.
        if (h.groupScore != null)
          Text(
            l10n.pollGroupScore(h.groupScore!),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

/// Scales a badge in with a small overshoot and out again; null shows nothing.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the participant pick two or three catalogue outfits to ask the group about.
/// Returns true when the question was sent.
Future<bool> showAskGroupSheet(BuildContext context, String eventId) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _AskGroupSheet(eventId: eventId),
  );
  return sent ?? false;
}

class _AskGroupSheet extends StatefulWidget {
  const _AskGroupSheet({required this.eventId});

  final String eventId;

  @override
  State<_AskGroupSheet> createState() => _AskGroupSheetState();
}

class _AskGroupSheetState extends State<_AskGroupSheet> {
  static const _max = 3;
  late final Future<List<CatalogItem>> _items = AppScope.api(
    context,
  ).items(widget.eventId);
  final _picked = <String>[];
  bool _sending = false;

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final api = AppScope.api(context);
    setState(() => _sending = true);
    final ok = await runWithFeedback(context, () async {
      await api.askGroup(widget.eventId, _picked);
      return true;
    }, success: l10n.pollSent);
    if (!mounted) return;
    if (ok == true) {
      Navigator.pop(context, true);
    } else {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.pollPickTitle, style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.pollPickHint,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: FutureBuilder<List<CatalogItem>>(
                future: _items,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorRetry(
                      error: snapshot.error!,
                      onRetry: () => Navigator.pop(context, false),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final garments = snapshot.data!
                      .where((i) => i.type == ItemType.garment)
                      .toList();
                  if (garments.length < 2) {
                    return NoticeBar(
                      l10n.pollNeedGarments,
                      icon: Icons.checkroom,
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 170,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: garments.length,
                    itemBuilder: (context, index) {
                      final item = garments[index];
                      final order = _picked.indexOf(item.id);
                      final full = _picked.length >= _max;
                      return _PickTile(
                        item: item,
                        order: order,
                        enabled: order >= 0 || !full,
                        onTap: () => setState(() {
                          if (order >= 0) {
                            _picked.remove(item.id);
                          } else if (!full) {
                            _picked.add(item.id);
                          }
                        }),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.pollPicked(_picked.length),
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _picked.length >= 2 && !_sending ? _send : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(l10n.pollSend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.item,
    required this.order,
    required this.enabled,
    required this.onTap,
  });

  final CatalogItem item;

  /// Position in the selection (0-based), or -1 when not picked.
  final int order;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final picked = order >= 0;
    return Semantics(
      selected: picked,
      button: true,
      label: item.name,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: enabled ? 1 : 0.45,
        child: Hoverable(
          enabled: enabled,
          onTap: enabled ? onTap : null,
          borderRadius: 16,
          child: AnimatedContainer(
            duration: Motion.fast,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: picked ? Brand.berry : scheme.outlineVariant,
                width: picked ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.checkroom,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _PopIn(
                          child: picked
                              ? CircleAvatar(
                                  key: ValueKey(order),
                                  radius: 13,
                                  backgroundColor: Brand.berry,
                                  child: Text(
                                    '${order + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Row(
                    children: [
                      ColorDot(
                        item.colors.isEmpty ? null : item.colors.first.hex,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
