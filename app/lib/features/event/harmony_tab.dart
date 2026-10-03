import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/harmony_map.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../widgets/common.dart';
import '../../widgets/finding_widgets.dart';
import 'board_loader.dart';

/// The harmony report: group score (weakest pair), warnings, every comparison,
/// an optional plain-language summary, and how the method works.
class HarmonyTab extends StatefulWidget {
  const HarmonyTab({super.key, required this.event});

  final EventInfo event;

  @override
  State<HarmonyTab> createState() => _HarmonyTabState();
}

class _HarmonyTabState extends State<HarmonyTab> with BoardLoader {
  String? _summary;
  bool _explaining = false;

  @override
  String get boardEventId => widget.event.id;

  @override
  Duration get refreshEvery => const Duration(seconds: 15);

  Future<void> _explain() async {
    final language = Localizations.localeOf(context).languageCode == 'bg'
        ? 'bg'
        : 'en';
    setState(() => _explaining = true);
    final text = await runWithFeedback(
      context,
      () => AppScope.api(context).explainHarmony(widget.event.id, language),
    );
    if (mounted) {
      setState(() {
        _summary = text ?? _summary;
        _explaining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = board;
    if (data == null) {
      return boardError == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Skeleton(height: 220, radius: 24),
            )
          : ErrorRetry(error: boardError!, onRetry: loadBoard);
    }
    final report = data.harmony;
    final text = Theme.of(context).textTheme;
    final explainAvailable =
        AppScope.of(context).config?.explainAvailable ?? false;
    final others = report.warnings.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CelebrationBanner(visible: clashFixed, text: l10n.clashFixed),
                if (report.findings.isEmpty)
                  Reveal(
                    child: NoticeBar(
                      l10n.harmonyNoData,
                      icon: Icons.palette_outlined,
                    ),
                  )
                else ...[
                  Reveal(child: _ScoreCard(report: report)),
                  const SizedBox(height: 16),
                  if (data.participants
                          .where((p) => p.look.garment != null)
                          .length >=
                      2) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RevealOnScroll(
                              child: Text(
                                l10n.harmonyMapTitle,
                                style: text.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 4),
                            HarmonyMap(board: data),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (report.warnings.isEmpty)
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: NoticeBar(
                        l10n.harmonyNoWarnings,
                        icon: Icons.check_circle_outline,
                      ),
                    )
                  else if (others.isNotEmpty) ...[
                    Text(l10n.harmonyWarnings, style: text.titleLarge),
                    const SizedBox(height: 8),
                    for (final (index, finding) in others.indexed)
                      Reveal(
                        delay: Motion.stagger(index + 2),
                        child: FindingCard(finding: finding),
                      ),
                  ],
                  if (explainAvailable) ...[
                    const SizedBox(height: 16),
                    Reveal(
                      delay: const Duration(milliseconds: 200),
                      child: _ExplainCard(
                        summary: _summary,
                        busy: _explaining,
                        onExplain: _explain,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: const Icon(Icons.compare_outlined),
                      title: Text(
                        '${l10n.harmonyAll} (${report.findings.length})',
                      ),
                      children: [
                        for (final finding in report.findings)
                          FindingTile(finding: finding),
                      ],
                    ),
                  ),
                ],
                if (report.withoutOutfit.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.harmonyWithoutOutfit(report.withoutOutfit.join(', ')),
                    style: text.bodySmall,
                  ),
                ],
                Card(
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: const Icon(Icons.science_outlined),
                    title: Text(l10n.harmonyMethodTitle),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      Text(
                        l10n.harmonyMethod,
                        style: text.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final HarmonyReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final weakest = report.weakest;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final gauge = ScoreGauge(
              score: report.groupScore ?? 0,
              size: 168,
              caption: l10n.statHarmony,
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.harmonyTitle, style: text.headlineSmall),
                if (weakest != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.harmonyWeakest.toUpperCase(),
                    style: text.labelSmall?.copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  FindingSummary(finding: weakest, large: true),
                ],
              ],
            );
            return wide
                ? Row(
                    children: [
                      gauge,
                      const SizedBox(width: 28),
                      Expanded(child: details),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: gauge),
                      const SizedBox(height: 16),
                      details,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  const _ExplainCard({
    required this.summary,
    required this.busy,
    required this.onExplain,
  });

  final String? summary;
  final bool busy;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Brand.plum.withValues(alpha: 0.08),
            Brand.champagne.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: Brand.champagne.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Brand.berry),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.explainButton, style: text.titleMedium),
              ),
              FilledButton.tonal(
                onPressed: busy ? null : onExplain,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.curve,
            child: summary == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Reveal(
                      key: ValueKey(summary),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary!,
                            style: text.bodyLarge?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.explainNote, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
