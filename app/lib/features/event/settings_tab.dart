import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
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
    final people =
        board?.participants.where((p) => !p.isMe).toList() ??
        const <BoardParticipant>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.settingsTitle, style: text.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.eventNameLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _perPerson,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.budgetPerPersonLabel,
                    suffixText: '€',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _total,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.budgetTotalLabel,
                    suffixText: '€',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.saveChanges),
                  ),
                ),
                const Divider(height: 40),
                Text(l10n.participantsTitle, style: text.titleMedium),
                for (final person in people)
                  ListTile(
                    title: Text(person.displayName),
                    trailing: IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _remove(person),
                    ),
                  ),
                const Divider(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: _deleteEvent,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(l10n.deleteEvent),
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
