import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/finding_widgets.dart';
import 'board_loader.dart';
import 'board_tab.dart';

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
          ? const Center(child: CircularProgressIndicator())
          : ErrorRetry(error: boardError!, onRetry: loadBoard);
    }
    final report = data.harmony;
    final text = Theme.of(context).textTheme;
    final explainAvailable =
        AppScope.of(context).config?.explainAvailable ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.findings.isEmpty)
                  NoticeBar(l10n.harmonyNoData, icon: Icons.palette_outlined)
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.harmonyTitle, style: text.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            l10n.groupHarmony(report.groupScore ?? 0),
                            style: text.headlineMedium?.copyWith(
                              color: scoreColor(
                                context,
                                report.groupScore ?? 0,
                              ),
                            ),
                          ),
                          if (report.weakest != null) ...[
                            const SizedBox(height: 8),
                            Text(l10n.harmonyWeakest, style: text.labelLarge),
                            FindingTile(finding: report.weakest!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.warnings.isEmpty)
                    NoticeBar(
                      l10n.harmonyNoWarnings,
                      icon: Icons.check_circle_outline,
                    )
                  else ...[
                    Text(l10n.harmonyWarnings, style: text.titleMedium),
                    for (final finding in report.warnings)
                      FindingCard(finding: finding),
                  ],
                  if (explainAvailable) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _explaining ? null : _explain,
                        icon: _explaining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.explainButton),
                      ),
                    ),
                    if (_summary != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_summary!),
                              const SizedBox(height: 8),
                              Text(l10n.explainNote, style: text.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: Text(
                      '${l10n.harmonyAll} (${report.findings.length})',
                    ),
                    children: [
                      for (final finding in report.findings)
                        FindingTile(finding: finding),
                    ],
                  ),
                ],
                if (report.withoutOutfit.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.harmonyWithoutOutfit(report.withoutOutfit.join(', ')),
                    style: text.bodySmall,
                  ),
                ],
                ExpansionTile(
                  title: Text(l10n.harmonyMethodTitle),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [Text(l10n.harmonyMethod)],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
