import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/motion.dart';
import '../../widgets/common.dart';
import '../../widgets/event_date_field.dart';
import 'board_loader.dart';

/// Organizer settings: name, budgets, participants, and deleting the event with all media.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.event, required this.onChanged});

  final EventInfo event;
  final Future<void> Function() onChanged;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with BoardLoader {
  late final _name = TextEditingController(text: widget.event.name);
  late final _perPerson = TextEditingController(
    text: _format(widget.event.budgetPerPerson),
  );
  late final _total = TextEditingController(
    text: _format(widget.event.budgetTotal),
  );
  late DateTime? _date = widget.event.eventDate;

  @override
  String get boardEventId => widget.event.id;

  @override
  Duration get refreshEvery => const Duration(seconds: 30);

  static String _format(double? value) =>
      value == null ? '' : value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

  @override
  void dispose() {
    _name.dispose();
    _perPerson.dispose();
    _total.dispose();
    super.dispose();
  }

  double? _amount(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim());

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final api = AppScope.api(context);
    final saved = await runWithFeedback(
      context,
      () => api.updateEvent(
        widget.event.id,
        name: _name.text.trim(),
        budgetPerPerson: _amount(_perPerson),
        budgetTotal: _amount(_total),
        clearBudgets:
            _perPerson.text.trim().isEmpty || _total.text.trim().isEmpty,
        eventDate: _date,
        clearDate: _date == null,
      ),
      success: l10n.saved,
    );
    if (saved != null) await widget.onChanged();
  }

  Future<void> _remove(BoardParticipant person) async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(
          context,
          l10n.removeParticipantConfirm(person.displayName),
        ) ||
        !mounted) {
      return;
    }
    await runWithFeedback(
      context,
      () => AppScope.api(
        context,
      ).removeParticipant(widget.event.id, person.userId),
    );
    await loadBoard();
  }

  Future<void> _deleteEvent() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deleteEventConfirm(widget.event.name)) ||
        !mounted) {
      return;
    }
    final done = await runWithFeedback(
      context,
      () =>
          AppScope.api(context).deleteEvent(widget.event.id).then((_) => true),
    );
    if (done == true && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final people =
        board?.participants.where((p) => !p.isMe).toList() ??
        const <BoardParticipant>[];
    const red = Color(0xFFC0392B);

    Widget section({
      required IconData icon,
      required String title,
      required List<Widget> children,
      Color? accent,
    }) => Card(
      margin: EdgeInsets.zero,
      shape: accent == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accent.withValues(alpha: 0.4)),
            ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent ?? scheme.primary),
                const SizedBox(width: 10),
                Text(title, style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Reveal(
                  child: section(
                    icon: Icons.tune,
                    title: l10n.settingsTitle,
                    children: [
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: l10n.eventNameLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      EventDateField(
                        value: _date,
                        onChanged: (day) => setState(() => _date = day),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _perPerson,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.budgetPerPersonLabel,
                                suffixText: '€',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _total,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.budgetTotalLabel,
                                suffixText: '€',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check),
                          label: Text(l10n.saveChanges),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 100),
                  child: section(
                    icon: Icons.groups_outlined,
                    title: l10n.participantsTitle,
                    children: [
                      for (final person in people)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: Brand.gradient,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                person.displayName.isEmpty
                                    ? '?'
                                    : person.displayName.characters.first
                                          .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          title: Text(person.displayName),
                          subtitle: person.pose == Pose.seated
                              ? Text(l10n.seatedLabel)
                              : null,
                          trailing: IconButton(
                            tooltip: l10n.delete,
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () => _remove(person),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 200),
                  child: section(
                    icon: Icons.warning_amber_outlined,
                    title: l10n.deleteEvent,
                    accent: red,
                    children: [
                      Text(
                        l10n.deleteEventConfirm(widget.event.name),
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _deleteEvent,
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: Text(l10n.deleteEvent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
