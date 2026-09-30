import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../config.dart';
import '../../l10n/app_localizations.dart';
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
    final joinLink = appLink('/join/${widget.event.joinCode}');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.inviteTitle, style: text.titleLarge),
                const SizedBox(height: 16),
                Text(l10n.inviteCode, style: text.labelLarge),
                SelectableText(
                  widget.event.joinCode,
                  style: text.displaySmall?.copyWith(letterSpacing: 6),
                ),
                const SizedBox(height: 16),
                Text(l10n.inviteLinkLabel, style: text.labelLarge),
                SelectableText(joinLink),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(joinLink),
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.copyLink),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(data: joinLink, size: 180),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.inviteQrHint, style: text.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 48),
                Text(l10n.vendorLinksTitle, style: text.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.vendorCatalogueExplain),
                const SizedBox(height: 12),
                TextField(
                  controller: _vendorName,
                  decoration: InputDecoration(labelText: l10n.vendorNameLabel),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: _createVendorLink,
                    child: Text(l10n.createLink),
                  ),
                ),
                if (_vendorLink != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.shareLinkReady(
                      formatDate(context, _vendorLink!.expiresAt),
                    ),
                  ),
                  SelectableText(appLink(_vendorLink!.path)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _copy(appLink(_vendorLink!.path)),
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.copyLink),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
