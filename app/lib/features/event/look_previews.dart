import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/before_after.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';

String previewName(AppLocalizations l10n, PreviewLook look) =>
    look.garment?.name ??
    look.makeup?.name ??
    look.hair?.name ??
    l10n.lookUnnamed;

/// The looks already previewed on this photo; tap one to compare it with the
/// current one.
class PreviewStrip extends StatelessWidget {
  const PreviewStrip({
    super.key,
    required this.previews,
    required this.onCompare,
  });

  final List<PreviewLook> previews;
  final ValueChanged<PreviewLook> onCompare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.previewsTitle, style: text.titleMedium),
        const SizedBox(height: 2),
        Text(l10n.previewsHint, style: text.bodySmall),
        const SizedBox(height: 10),
        SizedBox(
          height: 166,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previews.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preview = previews[index];
              return Reveal(
                delay: Motion.stagger(index, stepMs: 60),
                offset: const Offset(12, 0),
                child: Hoverable(
                  borderRadius: 14,
                  onTap: preview.current ? null : () => onCompare(preview),
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 128,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: preview.current
                                  ? Brand.berry
                                  : scheme.outlineVariant,
                              width: preview.current ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NetImage(preview.imageUrl),
                              if (preview.current)
                                Positioned(
                                  left: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Brand.berry,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.previewsNow,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ColorDot(preview.garment?.colorHex, size: 9),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                previewName(l10n, preview),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Two previews in one frame with a slider between them, and a way back to the
/// earlier one. Returns true if the participant chose to wear it again.
Future<bool> showCompareLooks(
  BuildContext context, {
  required PreviewLook earlier,
  required PreviewLook current,
  required String currency,
  required bool canSwitch,
}) async {
  final l10n = AppLocalizations.of(context);
  final text = Theme.of(context).textTheme;
  double total(PreviewLook look) => [
    look.garment,
    look.makeup,
    look.hair,
  ].fold(0.0, (sum, item) => sum + (item?.price ?? 0));
  final chosen = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.compareTitle, style: text.headlineSmall),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: BeforeAfter(
                    before: NetImage(earlier.imageUrl),
                    after: NetImage(current.imageUrl),
                    beforeLabel: previewName(l10n, earlier),
                    afterLabel: previewName(l10n, current),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${previewName(l10n, earlier)} · ${formatMoney(context, total(earlier), currency)}',
                      style: text.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${previewName(l10n, current)} · ${formatMoney(context, total(current), currency)}',
                      textAlign: TextAlign.end,
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.compareNote, style: text.bodySmall),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.close),
                  ),
                  if (canSwitch)
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.history_rounded),
                      label: Text(l10n.compareWear(previewName(l10n, earlier))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return chosen ?? false;
}
