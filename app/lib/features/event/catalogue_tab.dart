import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/item_form.dart';

/// Organizer's catalogue: garments with product photos (colors are extracted),
/// lip colors and hair colors with exact values.
class CatalogueTab extends StatefulWidget {
  const CatalogueTab({super.key, required this.event});

  final EventInfo event;

  @override
  State<CatalogueTab> createState() => _CatalogueTabState();
}

class _CatalogueTabState extends State<CatalogueTab> {
  List<CatalogItem>? _items;
  Object? _error;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final items = await AppScope.api(context).items(widget.event.id);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _add(ItemType type) async {
    final api = AppScope.api(context);
    final data = await showItemForm(context, type);
    if (data == null || !mounted) return;
    setState(() => _busy = true);
    await runWithFeedback(context, () async {
      final item = await api.addItem(widget.event.id, data.json);
      if (data.image != null) {
        await api.setItemImage(
          widget.event.id,
          item.id,
          Uint8List.fromList(data.image!),
        );
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    _load();
  }

  Future<void> _delete(CatalogItem item) async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deleteItemConfirm(item.name)) ||
        !mounted) {
      return;
    }
    await runWithFeedback(
      context,
      () => AppScope.api(context).deleteItem(widget.event.id, item.id),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _items;
    if (items == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : ErrorRetry(error: _error!, onRetry: _load);
    }
    final text = Theme.of(context).textTheme;
    final sections = [
      (l10n.sectionOutfit, ItemType.garment),
      (l10n.sectionMakeup, ItemType.makeup),
      (l10n.sectionHair, ItemType.hair),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _add(ItemType.garment),
              icon: const Icon(Icons.checkroom),
              label: Text(l10n.addGarment),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _add(ItemType.makeup),
              icon: const Icon(Icons.brush_outlined),
              label: Text(l10n.addMakeup),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _add(ItemType.hair),
              icon: const Icon(Icons.content_cut),
              label: Text(l10n.addHair),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        for (final (title, type) in sections)
          if (items.any((i) => i.type == type)) ...[
            const SizedBox(height: 20),
            Text(title, style: text.titleMedium),
            for (final item in items.where((i) => i.type == type))
              Card(
                child: ListTile(
                  leading: type == ItemType.garment
                      ? SizedBox(
                          width: 48,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ColoredBox(
                              color: Colors.white,
                              child: NetImage(
                                item.imageUrl,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.checkroom,
                              ),
                            ),
                          ),
                        )
                      : ColorDot(item.colorHex, size: 36),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          formatMoney(
                            context,
                            item.price,
                            widget.event.currency,
                          ),
                          if (item.category != null)
                            categoryName(l10n, item.category!),
                          if (item.vendorName != null)
                            l10n.addedBy(item.vendorName!),
                        ].join(' · '),
                      ),
                      if (type == ItemType.garment && !item.hasImage)
                        Text(
                          l10n.itemNeedsPhoto,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (item.colors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                '${l10n.colorsFound}: ',
                                style: text.bodySmall,
                              ),
                              for (final color in item.colors) ...[
                                ColorDot(color.hex, size: 14),
                                Text(
                                  ' ${(color.share * 100).round()}%  ',
                                  style: text.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(item),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}
