import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

/// Where a participant deletes their own data, at any time.
class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  EventInfo? _event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null) {
      AppScope.api(context)
          .event(widget.eventId)
          .then((event) {
            if (mounted) setState(() => _event = event);
          })
          .catchError((_) {});
    }
  }

  Future<void> _deletePhoto() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deletePhotoConfirm) || !mounted) return;
    await runWithFeedback(
      context,
      () => AppScope.api(context).deletePhoto(widget.eventId),
      success: l10n.deletedDone,
    );
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.leaveEventConfirm(_event?.name ?? '')) ||
        !mounted) {
      return;
    }
    final done = await runWithFeedback(
      context,
      () => AppScope.api(context).leaveEvent(widget.eventId).then((_) => true),
      success: l10n.deletedDone,
    );
    if (done == true && mounted) context.go('/');
  }

  Future<void> _deleteEverywhere() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deleteEverywhereConfirm) || !mounted) {
      return;
    }
    final done = await runWithFeedback(
      context,
      () => AppScope.api(context).deleteAllMyData(),
      success: l10n.deletedDone,
    );
    if (done != null && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myDataTitle)),
      body: PageBody(
        children: [
          Text(l10n.myDataExplain),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _deletePhoto,
            icon: const Icon(Icons.no_photography_outlined),
            label: Text(l10n.deletePhoto),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.logout),
            label: Text(l10n.leaveEvent),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _deleteEverywhere,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.deleteEverywhere),
          ),
        ],
      ),
    );
  }
}
