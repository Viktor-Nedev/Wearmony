import 'package:flutter/material.dart';

import '../../domain/event_template.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _name = TextEditingController();
  EventTemplate _template = EventTemplate.prom;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      EventTemplate.prom: l10n.templateProm,
      EventTemplate.theatre: l10n.templateTheatre,
      EventTemplate.group: l10n.templateGroup,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createEventTitle)),
      body: PageBody(
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.eventNameLabel),
          ),
          const SizedBox(height: 24),
          Text(l10n.templateLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final template in EventTemplate.values)
                ChoiceChip(
                  label: Text(labels[template]!),
                  selected: _template == template,
                  onSelected: (_) => setState(() => _template = template),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.notConnectedYet))),
            child: Text(l10n.createEventButton),
          ),
        ],
      ),
    );
  }
}
