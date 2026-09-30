import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/session_widgets.dart';
import 'board_tab.dart';
import 'catalogue_tab.dart';
import 'harmony_tab.dart';
import 'invite_tab.dart';
import 'my_look_tab.dart';
import 'settings_tab.dart';
import 'together_tab.dart';

enum EventTab { myLook, together, board, harmony, catalogue, invite, settings }

/// One event: tabs depend on whether the user organizes it, takes part, or both.
class EventShell extends StatefulWidget {
  const EventShell({super.key, required this.eventId, this.initialTab});

  final String eventId;
  final String? initialTab;

  @override
  State<EventShell> createState() => _EventShellState();
}

class _EventShellState extends State<EventShell> {
  EventInfo? _event;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final event = await AppScope.api(context).event(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<EventTab> _tabs(EventInfo event) => [
    if (event.isParticipant) ...[EventTab.myLook, EventTab.together],
    EventTab.board,
    EventTab.harmony,
    if (event.isOrganizer) ...[
      EventTab.catalogue,
      EventTab.invite,
      EventTab.settings,
    ],
  ];

  String _label(AppLocalizations l10n, EventTab tab) => switch (tab) {
    EventTab.myLook => l10n.tabMyLook,
    EventTab.together => l10n.tabTogether,
    EventTab.board => l10n.tabBoard,
    EventTab.harmony => l10n.tabHarmony,
    EventTab.catalogue => l10n.tabCatalogue,
    EventTab.invite => l10n.tabInvite,
    EventTab.settings => l10n.tabSettings,
  };

  Widget _content(EventTab tab, EventInfo event) => switch (tab) {
    EventTab.myLook => MyLookTab(event: event, onEventChanged: _load),
    EventTab.together => TogetherTab(event: event),
    EventTab.board => BoardTab(event: event),
    EventTab.harmony => HarmonyTab(event: event),
    EventTab.catalogue => CatalogueTab(event: event),
    EventTab.invite => InviteTab(event: event),
    EventTab.settings => SettingsTab(event: event, onChanged: _load),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = _event;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error == null
            ? const Center(child: CircularProgressIndicator())
            : ErrorRetry(error: _error!, onRetry: _load),
      );
    }

    final tabs = _tabs(event);
    final initial = tabs.indexWhere((t) => t.name == widget.initialTab);
    final config = AppScope.of(context).config;

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initial < 0 ? 0 : initial,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/'),
          ),
          title: Text(event.name),
          actions: [
            if (event.isParticipant)
              IconButton(
                tooltip: l10n.myData,
                icon: const Icon(Icons.privacy_tip_outlined),
                onPressed: () =>
                    context.push('/e/${event.id}/data').then((_) => _load()),
              ),
            const LanguageMenu(),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final tab in tabs) Tab(text: _label(l10n, tab))],
          ),
        ),
        body: Column(
          children: [
            if (event.demo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: NoticeBar(
                  l10n.demoBanner,
                  icon: Icons.brush_outlined,
                  tone: NoticeTone.simulated,
                ),
              )
            else if (config?.isMock ?? false)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: NoticeBar(
                  l10n.mockBanner,
                  icon: Icons.science_outlined,
                  tone: NoticeTone.simulated,
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [for (final tab in tabs) _content(tab, event)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
