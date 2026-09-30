import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../util/harmony_text.dart';
import 'common.dart';

/// A single harmony comparison with its two colors and a plain sentence.
class FindingTile extends StatelessWidget {
  const FindingTile({super.key, required this.finding});

  final HarmonyFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: SizedBox(
        width: 44,
        child: Stack(
          children: [
            ColorDot(finding.colors[0].hex, size: 28),
            Positioned(
              left: 16,
              top: 10,
              child: ColorDot(finding.colors[1].hex, size: 28),
            ),
          ],
        ),
      ),
      title: Text(findingSentence(l10n, finding)),
      subtitle: Text(
        '${relationName(l10n, finding.relation)} · ΔE ${finding.deltaE.toStringAsFixed(1)} · ${finding.score}/100',
      ),
    );
  }
}

/// A harmony comparison as a card, highlighted when it is a warning.
class FindingCard extends StatelessWidget {
  const FindingCard({super.key, required this.finding});

  final HarmonyFinding finding;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: finding.isWarning
          ? Theme.of(context).colorScheme.errorContainer
          : null,
      child: FindingTile(finding: finding),
    );
  }
}
