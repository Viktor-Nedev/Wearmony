import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

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
    final hints = {
      EventTemplate.prom: l10n.templatePromHint,
      EventTemplate.theatre: l10n.templateTheatreHint,
      EventTemplate.group: l10n.templateGroupHint,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createEventTitle)),
      body: PageBody(
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.eventNameLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.templateLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final template in EventTemplate.values)
                ChoiceChip(
                  label: Text(templateName(l10n, template)),
                  selected: _template == template,
                  onSelected: (_) => setState(() => _template = template),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(hints[_template]!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          TextField(
            controller: _perPerson,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.budgetPerPersonLabel,
              suffixText: '€',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _total,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.budgetTotalLabel,
              suffixText: '€',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.amountsInEuro,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _busy || _name.text.trim().isEmpty ? null : _create,
            child: Text(l10n.createEventButton),
          ),
        ],
      ),
    );
  }
}
