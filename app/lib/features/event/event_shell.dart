import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/effects.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/session_widgets.dart';
import 'board_tab.dart';
import 'catalogue_tab.dart';
import 'demo_tour.dart';
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
    final text = Theme.of(context).textTheme;

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initial < 0 ? 0 : initial,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          leading: IconButton(
            tooltip: l10n.appTitle,
            icon: const BrandMark(size: 18, showName: false),
            onPressed: () => context.go('/'),
          ),
          titleSpacing: 4,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _HeaderChip(
                      icon: _templateIcon(event.template),
                      label: templateName(l10n, event.template),
                    ),
                    if (event.eventDate != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: formatEventDay(context, event.eventDate!),
                        child: _HeaderChip(
                          icon: Icons.event_outlined,
                          label: countdownLabel(l10n, event.eventDate!),
                        ),
                      ),
                    ],
                    if (event.lockBy != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: l10n.lockByTooltip(
                          formatEventDay(context, event.lockBy!),
                        ),
                        child: _HeaderChip(
                          icon: Icons.lock_clock_outlined,
                          label: l10n.lockByChip(
                            countdownLabel(l10n, event.lockBy!),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    _HeaderChip(
                      icon: Icons.tag,
                      label: event.joinCode,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: event.joinCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.linkCopied)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (event.demo) DemoTourButton(event: event, tabs: tabs),
            if (event.isParticipant)
              IconButton(
                tooltip: l10n.myData,
                icon: const Icon(Icons.privacy_tip_outlined),
                onPressed: () =>
                    context.push('/e/${event.id}/data').then((_) => _load()),
              ),
            const LanguageMenu(),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: text.labelLarge,
            tabs: [
              for (final tab in tabs)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tabIcon(tab), size: 18),
                      const SizedBox(width: 8),
                      Text(_label(l10n, tab)),
                    ],
                  ),
                ),
            ],
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

  IconData _tabIcon(EventTab tab) => switch (tab) {
    EventTab.myLook => Icons.checkroom_outlined,
    EventTab.together => Icons.favorite_border,
    EventTab.board => Icons.groups_outlined,
    EventTab.harmony => Icons.palette_outlined,
    EventTab.catalogue => Icons.storefront_outlined,
    EventTab.invite => Icons.qr_code_2,
    EventTab.settings => Icons.tune,
  };

  IconData _templateIcon(EventTemplate template) => switch (template) {
    EventTemplate.prom => Icons.school_outlined,
    EventTemplate.theatre => Icons.theater_comedy_outlined,
    EventTemplate.group => Icons.groups_outlined,
  };
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
