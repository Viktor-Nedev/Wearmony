import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../widgets/common.dart';

/// The evaluation protocol in four steps.
class InclusionMethod extends StatelessWidget {
  const InclusionMethod({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final steps = [
      (Icons.checkroom_outlined, l10n.method1Title, l10n.method1Body),
      (Icons.accessible_forward, l10n.method2Title, l10n.method2Body),
      (Icons.fact_check_outlined, l10n.method3Title, l10n.method3Body),
      (Icons.public_outlined, l10n.method4Title, l10n.method4Body),
    ];
    return _Panel(
      icon: Icons.science_outlined,
      title: l10n.inclusionMethodTitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700
              ? 4
              : (constraints.maxWidth >= 420 ? 2 : 1);
          final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
          return Wrap(
            spacing: 14,
            runSpacing: 16,
            children: [
              for (final (index, (icon, title, body)) in steps.indexed)
                SizedBox(
                  width: width,
                  child: RevealOnScroll(
                    delay: Motion.stagger(index, stepMs: 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                gradient: Brand.gradient,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: Brand.numbers(
                                  text.labelMedium,
                                )?.copyWith(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(icon, size: 20, color: scheme.primary),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(title, style: text.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: text.bodySmall?.copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The table that will hold the results, with an empty, shimmering cell for every
/// number that has not been measured. No number is shown before it exists.
class PendingResultsTable extends StatelessWidget {
  const PendingResultsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final columns = [
      l10n.colApplied,
      l10n.colSilent,
      l10n.colFaceChanged,
      l10n.colMedianTime,
    ];
    final rows = [
      (Icons.accessibility_new, l10n.poseStanding),
      (Icons.accessible, l10n.poseSeated),
    ];
    Widget cell(Widget child, {bool header = false}) => Container(
      height: header ? 40 : 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: child,
    );
    return _Panel(
      icon: Icons.table_chart_outlined,
      title: l10n.inclusionTableTitle,
      subtitle: l10n.inclusionTableNote,
      // As wide as the card, and scrollable on narrow phones.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 560 ? 560 : constraints.maxWidth,
            child: Table(
              defaultColumnWidth: const FlexColumnWidth(),
              columnWidths: const {0: FixedColumnWidth(170)},
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              children: [
                TableRow(
                  children: [
                    cell(const SizedBox.shrink(), header: true),
                    for (final column in columns)
                      cell(Text(column, style: text.labelLarge), header: true),
                  ],
                ),
                for (final (icon, label) in rows)
                  TableRow(
                    children: [
                      cell(
                        Row(
                          children: [
                            Icon(icon, size: 18, color: scheme.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                label,
                                style: text.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var i = 0; i < columns.length; i++)
                        cell(
                          Tooltip(
                            message: l10n.inclusionNotMeasured,
                            child: const SizedBox(
                              width: 64,
                              child: Skeleton(height: 14, radius: 7),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What already helps seated participants, all of it in the app today.
class SeatedSupport extends StatelessWidget {
  const SeatedSupport({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final items = [l10n.built1, l10n.built2, l10n.built3, l10n.built4];
    return _Panel(
      icon: Icons.accessible_forward,
      title: l10n.inclusionBuiltTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in items.indexed)
            RevealOnScroll(
              delay: Motion.stagger(index, stepMs: 80),
              offset: const Offset(0, 10),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Brand.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: text.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _DemoButton(label: l10n.inclusionDemoCta),
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatefulWidget {
  const _DemoButton({required this.label});

  final String label;

  @override
  State<_DemoButton> createState() => _DemoButtonState();
}

class _DemoButtonState extends State<_DemoButton> {
  bool _busy = false;

  Future<void> _open() async {
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    final event = await runWithFeedback(
      context,
      () => AppScope.api(context).createDemo(template: EventTemplate.prom),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (event != null) router.go('/e/${event.id}?tab=board');
  }

  @override
  Widget build(BuildContext context) => BrandButton(
    label: widget.label,
    icon: Icons.groups_outlined,
    expand: false,
    onPressed: _busy ? null : _open,
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return RevealOnScroll(
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: text.titleLarge)),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: text.bodySmall),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
