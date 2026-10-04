import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models.dart';
import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../util/harmony_text.dart';
import '../../widgets/common.dart';

/// The hero tag shared by a person's picture on the board and in their details.
String personHeroTag(String userId) => 'person-picture-$userId';

/// One person's look in detail: the picture flies in from the board card, then
/// the items with prices and how their colors sit next to everyone else's.
Future<void> showPersonDetail(
  BuildContext context, {
  required BoardParticipant person,
  required Board board,
  VoidCallback? onOpenMyLook,
}) {
  final reduced = Motion.reduced(context);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: reduced ? Duration.zero : Motion.slow,
      reverseTransitionDuration: reduced ? Duration.zero : Motion.medium,
      pageBuilder: (context, animation, secondary) => PersonDetail(
        person: person,
        board: board,
        onOpenMyLook: onOpenMyLook,
      ),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Motion.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class PersonDetail extends StatelessWidget {
  const PersonDetail({
    super.key,
    required this.person,
    required this.board,
    this.onOpenMyLook,
  });

  final BoardParticipant person;
  final Board board;
  final VoidCallback? onOpenMyLook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;

    final picture = Hero(
      tag: personHeroTag(person.userId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: NetImage(person.pictureUrl),
        ),
      ),
    );
    final details = _Details(
      person: person,
      board: board,
      onOpenMyLook: onOpenMyLook,
    );

    final content = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: picture),
              const SizedBox(width: 28),
              Expanded(child: details),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: picture,
                ),
              ),
              const SizedBox(height: 20),
              details,
            ],
          );

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(wide ? 32 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: size.height - (wide ? 64 : 24),
            ),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              elevation: 12,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 28 : 18,
                      wide ? 28 : 52,
                      wide ? 28 : 18,
                      24,
                    ),
                    child: content,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.person,
    required this.board,
    required this.onOpenMyLook,
  });

  final BoardParticipant person;
  final Board board;
  final VoidCallback? onOpenMyLook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final look = person.look;
    final partner = board.byId(person.pairWith);
    final currency = board.budget.currency;
    final items = [
      (Icons.checkroom_outlined, look.garment),
      (Icons.brush_outlined, look.makeup),
      (Icons.content_cut, look.hair),
    ].where((entry) => entry.$2 != null).toList();
    final findings =
        board.harmony.findings
            .where((f) => f.people.contains(person.userId))
            .toList()
          ..sort((a, b) => a.score.compareTo(b.score));

    String otherSide(HarmonyFinding f) {
      if (f.scope == 'self') {
        final subject = f.subjects.first == 'hair'
            ? l10n.subjectHair
            : l10n.subjectLips;
        final label = l10n.personSelf(subject);
        return label.isEmpty
            ? label
            : label[0].toUpperCase() + label.substring(1);
      }
      final index = f.people.indexOf(person.userId) == 0 ? 1 : 0;
      final otherId = f.people.length > index ? f.people[index] : null;
      final other = board.byId(otherId);
      if (other?.isMe ?? false) return l10n.you;
      return f.names.length > index ? f.names[index] : '';
    }

    Widget chip(IconData icon, String label, {Color? color}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? scheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? scheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: text.labelMedium?.copyWith(color: color ?? scheme.primary),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          child: Text(
            person.isMe
                ? '${person.displayName} (${l10n.you})'
                : person.displayName,
            style: text.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        Reveal(
          delay: const Duration(milliseconds: 60),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (partner != null)
                chip(
                  Icons.favorite,
                  l10n.withPartner(
                    partner.isMe ? l10n.you : partner.displayName,
                  ),
                  color: Brand.berry,
                ),
              if (person.pose == Pose.seated)
                chip(Icons.accessible, l10n.seatedLabel),
              if (look.locked)
                chip(
                  Icons.lock_outline,
                  l10n.lockedLabel,
                  color: Brand.success,
                ),
              if (person.overBudget)
                chip(
                  Icons.savings_outlined,
                  l10n.overBudget,
                  color: scheme.error,
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(l10n.personLookTitle, style: text.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            person.hasPhoto ? l10n.noLookYet : l10n.noPhotoYet,
            style: text.bodyMedium,
          )
        else
          for (final (index, (icon, item)) in items.indexed)
            Reveal(
              delay: Motion.stagger(index + 1, stepMs: 70),
              offset: const Offset(16, 0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hexColor(item!.colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.name, style: text.bodyLarge)),
                    Text(
                      formatMoney(context, item.price, currency),
                      style: Brand.numbers(text.titleSmall),
                    ),
                  ],
                ),
              ),
            ),
        if (items.isNotEmpty) ...[
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.lookTotal(formatMoney(context, look.total, currency)),
              style: Brand.numbers(
                text.titleMedium,
              )?.copyWith(color: person.overBudget ? scheme.error : null),
            ),
          ),
        ],
        if (findings.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(l10n.personHarmonyTitle, style: text.titleMedium),
          const SizedBox(height: 10),
          for (final (index, f) in findings.indexed)
            Reveal(
              delay: Motion.stagger(index + 3, stepMs: 50),
              offset: const Offset(0, 10),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ColorPair(
                      a: hexColor(f.colors[0].hex),
                      b: hexColor(f.colors[1].hex),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        otherSide(f),
                        style: text.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RelationPill(
                      relation: f.relation,
                      label:
                          '${relationName(l10n, f.relation)} · ΔE ${f.deltaE.toStringAsFixed(1)}',
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (person.isMe && onOpenMyLook != null)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).maybePop();
                  onOpenMyLook!();
                },
                icon: const Icon(Icons.checkroom_outlined),
                label: Text(l10n.personOpenMyLook),
              ),
            if (board.event.isOrganizer && !person.isMe && !look.locked)
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: l10n.reminderText(
                        board.event.name,
                        appLink('/join/${board.event.joinCode}'),
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.reminderCopied)));
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(l10n.reminderCopy),
              ),
          ],
        ),
      ],
    );
  }
}
