import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';

/// Progress, result and failure states of one try-on render.
class TryOnStatusView extends StatelessWidget {
  const TryOnStatusView({super.key, required this.status});

  final TryOnStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            switch (status.state) {
              TaskState.queued => Text(l10n.tryOnQueued),
              TaskState.running => Text(l10n.tryOnRunning((status.progress * 100).round())),
              TaskState.success => Text(l10n.tryOnSuccess, style: theme.textTheme.titleMedium),
              TaskState.failed => Text(
                  l10n.tryOnFailed,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                ),
            },
            if (!status.isFinal) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: status.state == TaskState.queued ? null : status.progress,
              ),
            ],
            if (status.state == TaskState.failed) ...[
              const SizedBox(height: 8),
              Text(_failureText(l10n)),
            ],
            if (status.state == TaskState.success) ...[
              const SizedBox(height: 4),
              Text(l10n.previewDisclaimer, style: theme.textTheme.bodySmall),
            ],
            if (status.mock) ...[
              const SizedBox(height: 12),
              _MockBadge(label: l10n.mockBadge),
            ],
          ],
        ),
      ),
    );
  }

  String _failureText(AppLocalizations l10n) => switch (status.failureReason) {
        'garment_not_applied' => l10n.failureGarmentNotApplied,
        _ => l10n.failureGeneric,
      };
}

class _MockBadge extends StatelessWidget {
  const _MockBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.science_outlined, size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(color: scheme.onTertiaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}
