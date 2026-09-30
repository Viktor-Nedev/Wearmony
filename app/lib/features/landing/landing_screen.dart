import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/api_status_chip.dart';
import '../../widgets/page_body.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageBody(
        children: [
          const SizedBox(height: 48),
          Text(l10n.appTitle, style: text.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l10n.slogan,
            style: text.titleLarge?.copyWith(color: scheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(l10n.landingPitch, style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.event_outlined),
            label: Text(l10n.organizeEvent),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/join'),
            icon: const Icon(Icons.group_add_outlined),
            label: Text(l10n.joinWithCode),
          ),
          const SizedBox(height: 32),
          const ApiStatusChip(),
          if (kDebugMode)
            TextButton(
              onPressed: () => context.push('/dev/pipeline'),
              child: Text(l10n.pipelineTitle),
            ),
        ],
      ),
    );
  }
}
