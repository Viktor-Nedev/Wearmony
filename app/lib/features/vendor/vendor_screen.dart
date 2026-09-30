import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/item_form.dart';
import '../../widgets/page_body.dart';
import '../../widgets/session_widgets.dart';

/// Opened from a tokenized, expiring link. No account needed.
/// Look and hair links are read-only; catalogue links let a vendor add items.
class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key, required this.token});

  final String token;

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  VendorView? _view;
  Object? _error;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_view == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final view = await AppScope.api(context).vendorView(widget.token);
      if (mounted) {
        setState(() {
          _view = view;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _addItem(ItemType type) async {
    final api = AppScope.api(context);
    final data = await showItemForm(context, type);
    if (data == null || !mounted) return;
    setState(() => _busy = true);
    await runWithFeedback(context, () async {
      final item = await api.vendorAddItem(widget.token, data.json);
      if (data.image != null) {
        await api.vendorSetItemImage(
          widget.token,
          item.id,
          Uint8List.fromList(data.image!),
        );
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = _view;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vendorTitle),
        actions: const [LanguageMenu()],
      ),
      body: view == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error is ApiException &&
                                (_error as ApiException).code == 'link_expired'
                            ? l10n.vendorExpired
                            : l10n.vendorNotFound,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ))
          : view.scope == 'catalogue'
          ? _catalogue(context, view)
          : _look(context, view),
    );
  }

  Widget _look(BuildContext context, VendorView view) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return PageBody(
      maxWidth: 760,
      children: [
        Text(
          l10n.vendorFor(view.eventName, view.participantName ?? ''),
          style: text.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.vendorExpires(formatDate(context, view.expiresAt)),
          style: text.bodySmall,
        ),
        const SizedBox(height: 8),
        NoticeBar(l10n.vendorReadOnly),
        if (view.demo) ...[
          const SizedBox(height: 8),
          NoticeBar(l10n.demoBanner, tone: NoticeTone.simulated),
        ],
        const SizedBox(height: 16),
        if (view.hair != null)
          _ColorCard(
            title: l10n.sectionHair,
            item: view.hair!,
            currency: view.currency,
          ),
        if (view.makeup != null)
          _ColorCard(
            title: l10n.sectionMakeup,
            item: view.makeup!,
            currency: view.currency,
          ),
        if (view.garment != null)
          Card(
            child: ListTile(
              leading: SizedBox(
                width: 48,
                height: 60,
                child: NetImage(view.garment!.imageUrl, fit: BoxFit.contain),
              ),
              title: Text(view.garment!.name),
              subtitle: Text(
                '${l10n.sectionOutfit} · ${formatMoney(context, view.garment!.price, view.currency)}',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Picture(label: l10n.vendorBefore, url: view.photoUrl),
            ),
            if (view.resultUrl != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _Picture(label: l10n.vendorAfter, url: view.resultUrl),
              ),
            ],
          ],
        ),
        if (view.resultUrl != null) ...[
          const SizedBox(height: 8),
          if (view.resultIsSimulated)
            NoticeBar(
              view.demo ? l10n.demoRenderBadge : l10n.mockBadge,
              tone: NoticeTone.simulated,
            ),
          const SizedBox(height: 4),
          Text(l10n.previewDisclaimer, style: text.bodySmall),
        ],
      ],
    );
  }

  Widget _catalogue(BuildContext context, VendorView view) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return PageBody(
      maxWidth: 760,
      children: [
        Text(l10n.vendorCatalogueTitle(view.eventName), style: text.titleLarge),
        const SizedBox(height: 4),
        Text(
          l10n.vendorExpires(formatDate(context, view.expiresAt)),
          style: text.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _addItem(ItemType.garment),
              icon: const Icon(Icons.checkroom),
              label: Text(l10n.addGarment),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _addItem(ItemType.makeup),
              icon: const Icon(Icons.brush_outlined),
              label: Text(l10n.addMakeup),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _addItem(ItemType.hair),
              icon: const Icon(Icons.content_cut),
              label: Text(l10n.addHair),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 16),
        Text(l10n.vendorItemsInEvent, style: text.titleMedium),
        for (final item in view.items)
          ListTile(
            leading: item.type == ItemType.garment
                ? SizedBox(
                    width: 40,
                    height: 50,
                    child: NetImage(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.checkroom,
                    ),
                  )
                : ColorDot(item.colorHex, size: 32),
            title: Text(item.name),
            subtitle: Text(
              [
                formatMoney(context, item.price, view.currency),
                if (item.vendorName != null) l10n.addedBy(item.vendorName!),
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({
    required this.title,
    required this.item,
    required this.currency,
  });

  final String title;
  final CatalogItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ColorDot(item.colorHex, size: 44),
        title: Text('$title: ${item.name}'),
        subtitle: SelectableText(
          '${item.colorHex ?? ''} · ${formatMoney(context, item.price, currency)}',
        ),
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(aspectRatio: 3 / 4, child: NetImage(url)),
      ),
    ],
  );
}
