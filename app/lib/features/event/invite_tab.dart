import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';

/// Join code, invite link and QR; catalogue links for shops and costume keepers.
class InviteTab extends StatefulWidget {
  const InviteTab({super.key, required this.event});

  final EventInfo event;

  @override
  State<InviteTab> createState() => _InviteTabState();
}

class _InviteTabState extends State<InviteTab> {
  final _vendorName = TextEditingController();
  VendorLinkCreated? _vendorLink;

  @override
  void dispose() {
    _vendorName.dispose();
    super.dispose();
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).linkCopied)),
    );
  }

  Future<void> _createVendorLink() async {
    final link = await runWithFeedback(
      context,
      () => AppScope.api(context).createVendorLink(
        widget.event.id,
        scope: 'catalogue',
        vendorName: _vendorName.text.trim(),
      ),
    );
    if (link != null && mounted) setState(() => _vendorLink = link);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final joinLink = appLink('/join/${widget.event.joinCode}');

    final codeCard = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.inviteTitle, style: text.headlineSmall),
            const SizedBox(height: 18),
            Text(
              l10n.inviteCode.toUpperCase(),
              style: text.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, char)
                    in widget.event.joinCode.split('').indexed)
                  Reveal(
                    delay: Motion.stagger(index, stepMs: 70),
                    offset: const Offset(0, 12),
                    child: Container(
                      width: 46,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: Brand.gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Brand.berry.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        char,
                        style: Brand.numbers(
                          text.headlineSmall,
                        )?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              l10n.inviteLinkLabel.toUpperCase(),
              style: text.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: SelectableText(joinLink, maxLines: 1)),
                  IconButton.filledTonal(
                    tooltip: l10n.copyLink,
                    onPressed: () => _copy(joinLink),
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final qrCard = Reveal(
      delay: const Duration(milliseconds: 200),
      scale: 0.92,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Brand.plum.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: joinLink,
                  size: 190,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Brand.plumDeep,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Brand.plum,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.inviteQrHint, style: text.titleSmall),
            ],
          ),
        ),
      ),
    );

    final vendorCard = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined, color: Brand.berry),
                const SizedBox(width: 10),
                Text(l10n.vendorLinksTitle, style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.vendorCatalogueExplain),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vendorName,
                    decoration: InputDecoration(
                      labelText: l10n.vendorNameLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: _createVendorLink,
                  child: Text(l10n.createLink),
                ),
              ],
            ),
            AnimatedSize(
              duration: Motion.medium,
              child: _vendorLink == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Reveal(
                        key: ValueKey(_vendorLink!.token),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.shareLinkReady(
                                formatDate(context, _vendorLink!.expiresAt),
                              ),
                              style: text.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      appLink(_vendorLink!.path),
                                      maxLines: 1,
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: l10n.copyLink,
                                    onPressed: () =>
                                        _copy(appLink(_vendorLink!.path)),
                                    icon: const Icon(Icons.copy),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: Reveal(child: codeCard)),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: qrCard),
                          ],
                        ),
                      )
                    else ...[
                      Reveal(child: codeCard),
                      const SizedBox(height: 16),
                      qrCard,
                    ],
                    const SizedBox(height: 16),
                    Reveal(
                      delay: const Duration(milliseconds: 300),
                      child: vendorCard,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
