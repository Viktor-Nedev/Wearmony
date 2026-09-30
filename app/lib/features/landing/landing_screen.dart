import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';
import '../../widgets/session_widgets.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Future<List<EventInfo>>? _events;
  bool _openingDemo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _events ??= AppScope.api(context).myEvents();
  }

  Future<void> _openDemo() async {
    setState(() => _openingDemo = true);
    final event = await runWithFeedback(
      context,
      () => AppScope.api(context).createDemo(),
    );
    if (!mounted) return;
    setState(() => _openingDemo = false);
    if (event != null) context.go('/e/${event.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final config = AppScope.of(context).config;

    return Scaffold(
      appBar: AppBar(actions: const [LanguageMenu()]),
      body: PageBody(
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            style: text.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.slogan,
            style: text.titleLarge?.copyWith(color: scheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.landingPitch,
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
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
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _openingDemo ? null : _openDemo,
            icon: _openingDemo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(l10n.openDemo),
          ),
          Text(
            l10n.demoHint,
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (config?.isMock ?? false) ...[
            NoticeBar(
              l10n.mockBanner,
              icon: Icons.science_outlined,
              tone: NoticeTone.simulated,
            ),
            const SizedBox(height: 12),
          ],
          const ApiStatusChip(),
          const SizedBox(height: 24),
          FutureBuilder<List<EventInfo>>(
            future: _events,
            builder: (context, snapshot) {
              final events = snapshot.data ?? const [];
              if (events.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.yourEvents, style: text.titleMedium),
                  const SizedBox(height: 8),
                  for (final event in events)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          event.demo
                              ? Icons.auto_awesome_outlined
                              : Icons.celebration_outlined,
                        ),
                        title: Text(event.name),
                        subtitle: Text(
                          [
                            templateName(l10n, event.template),
                            if (event.isOrganizer) l10n.organizerRole,
                            if (event.isParticipant) l10n.participantRole,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/e/${event.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.push('/inclusion'),
            icon: const Icon(Icons.accessible_forward),
            label: Text(l10n.inclusionLink),
          ),
        ],
      ),
    );
  }
}
