import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

/// Explicit consent before any photo is uploaded.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _checked = <int>{};
  bool _busy = false;

  Future<void> _agree() async {
    setState(() => _busy = true);
    final done = await runWithFeedback(
      context,
      () => AppScope.api(context).consent(widget.eventId),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (done != null) context.pushReplacement('/e/${widget.eventId}/photo');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statements = [
      l10n.consentAdult,
      l10n.consentPrivate,
      l10n.consentDelete,
      l10n.consentPreview,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consentTitle)),
      body: PageBody(
        children: [
          for (var i = 0; i < statements.length; i++)
            CheckboxListTile(
              value: _checked.contains(i),
              onChanged: (value) => setState(
                () => value == true ? _checked.add(i) : _checked.remove(i),
              ),
              title: Text(statements[i]),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _checked.length == statements.length && !_busy
                ? _agree
                : null,
            child: Text(l10n.consentButton),
          ),
        ],
      ),
    );
  }
}
