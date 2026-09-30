import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../../widgets/tryon_status_view.dart';

/// Debug-only screen that runs one try-on through the backend and shows every state.
class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  TryOnStatus? _status;
  Object? _error;
  bool _running = false;

  Future<void> _run({required bool fail}) async {
    final api = AppScope.of(context).api;
    setState(() {
      _running = true;
      _status = null;
      _error = null;
    });
    try {
      final taskId = await api.startTryOn(
        kind: TryOnKind.apparel,
        photoRef: 'demo/participant.jpg',
        // The mock backend fails items whose ref starts with "mock-fail".
        itemRef: fail ? 'mock-fail-dress.jpg' : 'demo/dress.jpg',
      );
      final updates = api.watchTryOn(taskId, interval: const Duration(milliseconds: 500));
      await for (final status in updates) {
        if (!mounted) return;
        setState(() => _status = status);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _status;
    final error = _error;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pipelineTitle)),
      body: PageBody(
        children: [
          FilledButton(
            onPressed: _running ? null : () => _run(fail: false),
            child: Text(l10n.pipelineRunSuccess),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _running ? null : () => _run(fail: true),
            child: Text(l10n.pipelineRunFailure),
          ),
          const SizedBox(height: 24),
          if (status != null) TryOnStatusView(status: status),
          if (error != null)
            Text(
              error is TryOnTimeoutException ? l10n.tryOnTimeout : l10n.apiStatusOffline,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
