import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';
import '../../widgets/session_widgets.dart';

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
      appBar: AppBar(
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.home_outlined),
                onPressed: () => context.go('/'),
              ),
        title: Text(l10n.inclusionTitle),
        actions: const [LanguageMenu()],
      ),
      body: results == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : ErrorRetry(error: _error!, onRetry: _load))
          : PageBody(
              maxWidth: 900,
              children: [
                Text(l10n.inclusionIntro, style: text.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.inclusionEngine(results.engine),
                  style: text.bodySmall,
                ),
                if (results.measuredAt != null)
                  Text(
                    l10n.inclusionMeasuredAt(
                      formatDate(context, DateTime.parse(results.measuredAt!)),
                    ),
                    style: text.bodySmall,
                  ),
                const SizedBox(height: 16),
                if (results.groups.isEmpty)
                  NoticeBar(l10n.inclusionNotMeasured)
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(l10n.colPose)),
                        DataColumn(label: Text(l10n.colFraming)),
                        DataColumn(label: Text(l10n.colRuns), numeric: true),
                        DataColumn(label: Text(l10n.colApplied), numeric: true),
                        DataColumn(label: Text(l10n.colSilent), numeric: true),
                        DataColumn(label: Text(l10n.colErrors), numeric: true),
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
                                Text(
                                  g.pose == 'seated'
                                      ? l10n.poseSeated
                                      : l10n.poseStanding,
                                ),
                              ),
                              DataCell(
                                Text(
                                  g.framing == 'upper_body_fallback'
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
                              DataCell(Text('${g.silentFailures}')),
                              DataCell(Text('${g.errors}')),
                              DataCell(
                                Text(
                                  g.identityDrift?.toString() ??
                                      l10n.notReviewed,
                                ),
                              ),
                              DataCell(
                                Text(
                                  g.medianLatencySeconds == null
                                      ? '–'
                                      : '${g.medianLatencySeconds!.toStringAsFixed(0)} s',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                for (final note in results.notes) ...[
                  Text('•  $note', style: text.bodyMedium),
                  const SizedBox(height: 4),
                ],
              ],
            ),
    );
  }
}
