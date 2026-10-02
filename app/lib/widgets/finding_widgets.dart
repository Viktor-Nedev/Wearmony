import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/harmony_visuals.dart';
import '../util/format.dart';
import '../util/harmony_text.dart';

/// Color pair, relation pill and the plain sentence for one comparison.
class FindingSummary extends StatelessWidget {
  const FindingSummary({super.key, required this.finding, this.large = false});

  final HarmonyFinding finding;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColorPair(
          a: hexColor(finding.colors[0].hex),
          b: hexColor(finding.colors[1].hex),
          size: large ? 36 : 28,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RelationPill(
                    relation: finding.relation,
                    label: relationName(l10n, finding.relation),
                  ),
                  Text(
                    'ΔE ${finding.deltaE.toStringAsFixed(1)} · ${finding.score}/100',
                    style: text.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                findingSentence(l10n, finding),
                style: (large ? text.bodyLarge : text.bodyMedium)?.copyWith(
                  height: 1.45,
                  fontWeight: large ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single harmony comparison as a list row.
class FindingTile extends StatelessWidget {
  const FindingTile({super.key, required this.finding});

  final HarmonyFinding finding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: FindingSummary(finding: finding),
    );
  }
}

/// A harmony comparison as a card, highlighted when it is a warning.
class FindingCard extends StatelessWidget {
  const FindingCard({super.key, required this.finding});

  final HarmonyFinding finding;

  @override
  Widget build(BuildContext context) {
    final warning = finding.isWarning;
    final red = const Color(0xFFC0392B);
    return Card(
      color: warning
          ? red.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.16
                  : 0.06,
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: warning
              ? red.withValues(alpha: 0.25)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: FindingTile(finding: finding),
    );
  }
}
