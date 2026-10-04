import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../ui/motion.dart';
import '../util/format.dart';

/// Event-friendly colors to build a dress code from.
const dressCodeSwatches = [
  '#1C1C1E',
  '#F7F7F2',
  '#EFE6D2',
  '#E9D8B8',
  '#C9A24B',
  '#BFC4CA',
  '#E8A0B4',
  '#C9577A',
  '#B3263A',
  '#8E1B2A',
  '#6D1F33',
  '#B9A6D6',
  '#8EC3E6',
  '#2647A8',
  '#1F2A44',
  '#1F6F78',
  '#1E7F5C',
  '#9CB59A',
  '#C99A2E',
];

/// The name of a dress-code swatch, or its hex code for any other color.
String swatchName(AppLocalizations l10n, String hex) =>
    switch (hex.toUpperCase()) {
      '#1C1C1E' => l10n.swatchBlack,
      '#F7F7F2' => l10n.swatchWhite,
      '#EFE6D2' => l10n.swatchIvory,
      '#E9D8B8' => l10n.swatchChampagne,
      '#C9A24B' => l10n.swatchGold,
      '#BFC4CA' => l10n.swatchSilver,
      '#E8A0B4' => l10n.swatchBlush,
      '#C9577A' => l10n.swatchRose,
      '#B3263A' => l10n.swatchRed,
      '#8E1B2A' => l10n.swatchCrimson,
      '#6D1F33' => l10n.swatchBurgundy,
      '#B9A6D6' => l10n.swatchLavender,
      '#8EC3E6' => l10n.swatchSky,
      '#2647A8' => l10n.swatchRoyal,
      '#1F2A44' => l10n.swatchNavy,
      '#1F6F78' => l10n.swatchTeal,
      '#1E7F5C' => l10n.swatchEmerald,
      '#9CB59A' => l10n.swatchSage,
      '#C99A2E' => l10n.swatchMustard,
      _ => hex.toUpperCase(),
    };

Color fitColor(DressCodeFit fit) => switch (fit) {
  DressCodeFit.on => Brand.success,
  DressCodeFit.close => Brand.warning,
  DressCodeFit.off => const Color(0xFFC0392B),
};

String fitLabel(AppLocalizations l10n, DressCodeFit fit) => switch (fit) {
  DressCodeFit.on => l10n.dressFitOn,
  DressCodeFit.close => l10n.dressFitClose,
  DressCodeFit.off => l10n.dressFitOff,
};

IconData fitIcon(DressCodeFit fit) => switch (fit) {
  DressCodeFit.on => Icons.check_rounded,
  DressCodeFit.close => Icons.more_horiz_rounded,
  DressCodeFit.off => Icons.close_rounded,
};

/// A round color swatch with a soft shadow; [selected] adds a ring.
class Swatch extends StatelessWidget {
  const Swatch(this.hex, {super.key, this.size = 34, this.selected = false});

  final String hex;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = hexColor(hex);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: Motion.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: size / 3,
            offset: Offset(0, size / 10),
          ),
        ],
      ),
    );
  }
}

/// Picks up to four dress-code colors: the chosen ones on top, all swatches below.
class DressCodePicker extends StatelessWidget {
  const DressCodePicker({
    super.key,
    required this.colors,
    required this.onChanged,
  });

  final List<String> colors;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final full = colors.length >= 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.dressCodeTitle, style: text.titleSmall),
        const SizedBox(height: 2),
        Text(l10n.dressCodeHint, style: text.bodySmall),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: Motion.medium,
          alignment: Alignment.topLeft,
          child: colors.isEmpty
              ? Text(l10n.dressCodeEmpty, style: text.bodyMedium)
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final hex in colors)
                      InputChip(
                        avatar: Swatch(hex, size: 22),
                        label: Text(swatchName(l10n, hex)),
                        onDeleted: () => onChanged([...colors]..remove(hex)),
                        deleteButtonTooltipMessage: l10n.delete,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hex in dressCodeSwatches)
              Tooltip(
                message: swatchName(l10n, hex),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: colors.contains(hex)
                      ? () => onChanged([...colors]..remove(hex))
                      : (full ? null : () => onChanged([...colors, hex])),
                  child: Opacity(
                    opacity: full && !colors.contains(hex) ? 0.35 : 1,
                    child: Swatch(hex, selected: colors.contains(hex)),
                  ),
                ),
              ),
          ],
        ),
        if (full) ...[
          const SizedBox(height: 8),
          Text(l10n.dressCodeFull, style: text.bodySmall),
        ],
      ],
    );
  }
}

/// The group against the dress code: the colors, and each person's nearest match.
class DressCodeCard extends StatelessWidget {
  const DressCodeCard({super.key, required this.report, required this.board});

  final DressCodeReport report;
  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.dressCodeTitle, style: text.titleLarge),
                ),
                for (final hex in report.palette)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Swatch(hex, size: 26),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dressCodeOnCount(report.onCount, report.total),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            for (final (index, person) in report.people.indexed)
              RevealOnScroll(
                delay: Motion.stagger(index, stepMs: 60),
                offset: const Offset(0, 10),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Swatch(person.outfit, size: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.east_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Swatch(person.nearest, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          board.byId(person.userId)?.isMe ?? false
                              ? l10n.you
                              : person.name,
                          style: text.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: fitColor(person.fit).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: fitColor(person.fit).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              fitIcon(person.fit),
                              size: 14,
                              color: fitColor(person.fit),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${fitLabel(l10n, person.fit)} · ΔE ${person.deltaE.toStringAsFixed(1)}',
                              style: text.labelMedium?.copyWith(
                                color: fitColor(person.fit),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
