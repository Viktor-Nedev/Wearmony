import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/figure.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/session_widgets.dart';
import 'inclusion_sections.dart';

/// Published, measured try-on results for standing versus seated photos.
class InclusionScreen extends StatefulWidget {
  const InclusionScreen({super.key});

  @override
  State<InclusionScreen> createState() => _InclusionScreenState();
}

class _InclusionScreenState extends State<InclusionScreen> {
  InclusionResults? _results;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_results == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final results = await AppScope.api(context).inclusion();
      if (mounted) {
        setState(() {
          _results = results;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final results = _results;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const BrandMark(size: 18, showName: false),
                onPressed: () => context.go('/'),
              ),
        actions: const [LanguageMenu(), SizedBox(width: 8)],
      ),
      body: AuroraBackground(
        intensity: 0.6,
        child: SafeArea(
          child: results == null
              ? (_error == null
                    ? const Center(child: CircularProgressIndicator())
                    : ErrorRetry(error: _error!, onRetry: _load))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Reveal(
                            child: GlassCard(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final figures = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Figure(
                                        clothing: Brand.berry,
                                        hair: Color(0xFF3B2A20),
                                        width: 70,
                                      ),
                                      SizedBox(width: 12),
                                      Figure(
                                        clothing: Color(0xFF1E7F5C),
                                        hair: Color(0xFF1E1612),
                                        skin: Color(0xFF8D5A3B),
                                        seated: true,
                                        width: 70,
                                      ),
                                    ],
                                  );
                                  final intro = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GradientText(
                                        l10n.inclusionTitle,
                                        style: text.headlineMedium,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.inclusionIntro,
                                        style: text.bodyLarge?.copyWith(
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.inclusionEngine(results.engine),
                                        style: text.bodySmall,
                                      ),
                                      if (results.measuredAt != null)
                                        Text(
                                          l10n.inclusionMeasuredAt(
                                            formatDate(
                                              context,
                                              DateTime.parse(
                                                results.measuredAt!,
                                              ),
                                            ),
                                          ),
                                          style: text.bodySmall,
                                        ),
                                    ],
                                  );
                                  return constraints.maxWidth >= 600
                                      ? Row(
                                          children: [
                                            Expanded(child: intro),
                                            const SizedBox(width: 24),
                                            figures,
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Center(child: figures),
                                            const SizedBox(height: 16),
                                            intro,
                                          ],
                                        );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Reveal(
                            delay: const Duration(milliseconds: 150),
                            child: results.groups.isEmpty
                                ? NoticeBar(
                                    l10n.inclusionNotMeasured,
                                    icon: Icons.hourglass_empty,
                                  )
                                : Card(
                                    margin: EdgeInsets.zero,
                                    clipBehavior: Clip.antiAlias,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingTextStyle: text.labelLarge,
                                        columns: [
                                          DataColumn(label: Text(l10n.colPose)),
                                          DataColumn(
                                            label: Text(l10n.colFraming),
                                          ),
                                          DataColumn(
                                            label: Text(l10n.colRuns),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text(l10n.colApplied),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text(l10n.colSilent),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text(l10n.colErrors),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text(l10n.colFaceChanged),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text(l10n.colMedianTime),
                                            numeric: true,
                                          ),
                                        ],
                                        rows: [
                                          for (final g in results.groups)
                                            DataRow(
                                              cells: [
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        g.pose == 'seated'
                                                            ? Icons.accessible
                                                            : Icons
                                                                  .accessibility_new,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        g.pose == 'seated'
                                                            ? l10n.poseSeated
                                                            : l10n.poseStanding,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    g.framing ==
                                                            'upper_body_fallback'
                                                        ? l10n.framingUpperBody
                                                        : l10n.framingAsCatalogued,
                                                  ),
                                                ),
                                                DataCell(Text('${g.runs}')),
                                                DataCell(
                                                  Text(
                                                    '${g.success} (${g.runs == 0 ? 0 : (g.success * 100 / g.runs).round()}%)',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text('${g.silentFailures}'),
                                                ),
                                                DataCell(Text('${g.errors}')),
                                                DataCell(
                                                  Text(
                                                    g.identityDrift
                                                            ?.toString() ??
                                                        l10n.notReviewed,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    g.medianLatencySeconds ==
                                                            null
                                                        ? '–'
                                                        : '${g.medianLatencySeconds!.toStringAsFixed(0)} s',
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          for (final (index, note) in results.notes.indexed)
                            Reveal(
                              delay: Motion.stagger(index + 3),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Brand.berry,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        note,
                                        style: text.bodyMedium?.copyWith(
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (results.groups.isEmpty) ...[
                            const PendingResultsTable(),
                            const SizedBox(height: 16),
                          ],
                          const InclusionMethod(),
                          const SizedBox(height: 16),
                          const SeatedSupport(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
