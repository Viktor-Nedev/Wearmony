import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/effects.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/form_scaffold.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _name = TextEditingController();
  final _perPerson = TextEditingController();
  final _total = TextEditingController();
  EventTemplate _template = EventTemplate.prom;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _perPerson.dispose();
    _total.dispose();
    super.dispose();
  }

  double? _amount(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.').trim());

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final event = await runWithFeedback(
      context,
      () => AppScope.api(context).createEvent(
        name: _name.text.trim(),
        template: _template,
        budgetPerPerson: _amount(_perPerson),
        budgetTotal: _amount(_total),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (event != null) context.go('/e/${event.id}?tab=invite');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final templates = [
      (EventTemplate.prom, Icons.school_outlined, l10n.templatePromHint),
      (
        EventTemplate.theatre,
        Icons.theater_comedy_outlined,
        l10n.templateTheatreHint,
      ),
      (EventTemplate.group, Icons.groups_outlined, l10n.templateGroupHint),
    ];

    return FormScaffold(
      title: l10n.createEventTitle,
      icon: Icons.event_outlined,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.eventNameLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 22),
        Text(l10n.templateLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        for (final (template, icon, hint) in templates) ...[
          ChoiceTile(
            selected: _template == template,
            onTap: () => setState(() => _template = template),
            title: templateName(l10n, template),
            subtitle: hint,
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _perPerson,
                keyboardType: const TextInputType.numberWithOptions(
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
                keyboardType: const TextInputType.numberWithOptions(
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
        const SizedBox(height: 6),
        Text(l10n.amountsInEuro, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 26),
        BrandButton(
          label: l10n.createEventButton,
          icon: Icons.arrow_forward,
          onPressed: _busy || _name.text.trim().isEmpty ? null : _create,
        ),
      ],
    );
  }
}
