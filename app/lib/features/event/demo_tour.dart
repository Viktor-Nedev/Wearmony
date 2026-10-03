import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../widgets/common.dart';
import 'event_shell.dart';

/// A short guided tour of a demo event: each step jumps to the screen that
/// shows one feature. The button glows until the tour has been opened once.
class DemoTourButton extends StatefulWidget {
  const DemoTourButton({super.key, required this.event, required this.tabs});

  final EventInfo event;
  final List<EventTab> tabs;

  @override
  State<DemoTourButton> createState() => _DemoTourButtonState();
}

class _TourStep {
  const _TourStep(this.icon, this.title, this.body, this.go);

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function(BuildContext context) go;
}

class _DemoTourButtonState extends State<DemoTourButton> {
  bool _opened = false;
  final _visited = <int>{};

  List<_TourStep> _steps(AppLocalizations l10n) {
    final event = widget.event;
    Future<void> tab(BuildContext context, EventTab tab) async {
      final index = widget.tabs.indexOf(tab);
      if (index >= 0) DefaultTabController.of(context).animateTo(index);
    }

    Future<void> frame(BuildContext context) =>
        context.push('/e/${event.id}/frame');

    Future<void> demo(BuildContext context, EventTemplate template) async {
      final router = GoRouter.of(context);
      final opened = await runWithFeedback(
        context,
        () => AppScope.api(context).createDemo(template: template),
      );
      if (opened != null) router.go('/e/${opened.id}');
    }

    if (event.template == EventTemplate.theatre) {
      return [
        _TourStep(
          Icons.palette_outlined,
          l10n.tourCostumesTitle,
          l10n.tourCostumesBody,
          (c) => tab(c, EventTab.harmony),
        ),
        _TourStep(
          Icons.theater_comedy_outlined,
          l10n.tourStageTitle,
          l10n.tourStageBody,
          frame,
        ),
        _TourStep(
          Icons.savings_outlined,
          l10n.tourBudgetTitle,
          l10n.tourBudgetBody,
          (c) => tab(c, EventTab.board),
        ),
        _TourStep(
          Icons.school_outlined,
          l10n.tourPromTitle,
          l10n.tourPromBody,
          (c) => demo(c, EventTemplate.prom),
        ),
      ];
    }
    return [
      if (widget.tabs.contains(EventTab.together))
        _TourStep(
          Icons.auto_fix_high,
          l10n.tourFixTitle,
          l10n.tourFixBody,
          (c) => tab(c, EventTab.together),
        ),
      _TourStep(
        Icons.photo_camera_front_outlined,
        l10n.tourPhotoTitle,
        l10n.tourPhotoBody,
        frame,
      ),
      _TourStep(
        Icons.hub_outlined,
        l10n.tourMapTitle,
        l10n.tourMapBody,
        (c) => tab(c, EventTab.harmony),
      ),
      _TourStep(
        Icons.savings_outlined,
        l10n.tourBudgetTitle,
        l10n.tourBudgetBody,
        (c) => tab(c, EventTab.board),
      ),
      _TourStep(
        Icons.theater_comedy_outlined,
        l10n.tourTheatreTitle,
        l10n.tourTheatreBody,
        (c) => demo(c, EventTemplate.theatre),
      ),
    ];
  }

  Future<void> _open() async {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(l10n);
    setState(() => _opened = true);
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _TourSheet(steps: steps, visited: Set.of(_visited)),
    );
    if (chosen == null || !mounted) return;
    setState(() => _visited.add(chosen));
    await steps[chosen].go(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return PulseGlow(
      color: Brand.berry,
      radius: 20,
      active: !_opened,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: FilledButton.tonalIcon(
          onPressed: _open,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
          ),
          icon: const Icon(Icons.explore_outlined, size: 18),
          label: Text(l10n.tourButton),
        ),
      ),
    );
  }
}

class _TourSheet extends StatelessWidget {
  const _TourSheet({required this.steps, required this.visited});

  final List<_TourStep> steps;
  final Set<int> visited;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.tourTitle, style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  l10n.tourSubtitle,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final (index, step) in steps.indexed)
                  Reveal(
                    delay: Motion.stagger(index, stepMs: 60),
                    offset: const Offset(0, 10),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Hoverable(
                        onTap: () => Navigator.pop(context, index),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: visited.contains(index)
                                      ? null
                                      : Brand.gradient,
                                  color: visited.contains(index)
                                      ? Brand.success.withValues(alpha: 0.15)
                                      : null,
                                ),
                                child: Icon(
                                  visited.contains(index)
                                      ? Icons.check_rounded
                                      : step.icon,
                                  color: visited.contains(index)
                                      ? Brand.success
                                      : Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(step.title, style: text.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.body,
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
