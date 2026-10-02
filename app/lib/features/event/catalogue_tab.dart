import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
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
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Skeleton(height: 260, radius: 22),
            )
          : ErrorRetry(error: _error!, onRetry: _load);
    }
    final text = Theme.of(context).textTheme;
    final sections = [
      (Icons.checkroom_outlined, l10n.sectionOutfit, ItemType.garment),
      (Icons.brush_outlined, l10n.sectionMakeup, ItemType.makeup),
      (Icons.content_cut, l10n.sectionHair, ItemType.hair),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Reveal(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 220,
                        child: BrandButton(
                          label: l10n.addGarment,
                          icon: Icons.checkroom,
                          onPressed: _busy
                              ? null
                              : () => _add(ItemType.garment),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                        ),
                        onPressed: _busy ? null : () => _add(ItemType.makeup),
                        icon: const Icon(Icons.brush_outlined),
                        label: Text(l10n.addMakeup),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                        ),
                        onPressed: _busy ? null : () => _add(ItemType.hair),
                        icon: const Icon(Icons.content_cut),
                        label: Text(l10n.addHair),
                      ),
                    ],
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                for (final (icon, title, type) in sections)
                  if (items.any((i) => i.type == type)) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(title, style: text.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (final (index, item)
                            in items.where((i) => i.type == type).indexed)
                          Reveal(
                            delay: Motion.stagger(index, stepMs: 50),
                            child: type == ItemType.garment
                                ? _GarmentTile(
                                    item: item,
                                    currency: widget.event.currency,
                                    onDelete: () => _delete(item),
                                  )
                                : _ColorTile(
                                    item: item,
                                    currency: widget.event.currency,
                                    onDelete: () => _delete(item),
                                  ),
                          ),
                      ],
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

class _GarmentTile extends StatelessWidget {
  const _GarmentTile({
    required this.item,
    required this.currency,
    required this.onDelete,
  });

  final CatalogItem item;
  final String currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 210,
      child: Hoverable(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: NetImage(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          placeholderIcon: Icons.checkroom,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filledTonal(
                      tooltip: l10n.delete,
                      iconSize: 18,
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
              if (item.colors.isNotEmpty) _ColorStrip(colors: item.colors),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        formatMoney(context, item.price, currency),
                        if (item.category != null)
                          categoryName(l10n, item.category!),
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                    if (item.vendorName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.addedBy(item.vendorName!),
                        style: text.labelSmall?.copyWith(color: scheme.primary),
                      ),
                    ],
                    if (!item.hasImage) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.itemNeedsPhoto,
                        style: text.bodySmall?.copyWith(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The extracted colors as one bar, each segment as wide as its share of the garment.
class _ColorStrip extends StatelessWidget {
  const _ColorStrip({required this.colors});

  final List<ColorShare> colors;

  @override
  Widget build(BuildContext context) {
    final total = colors.fold<double>(0, (sum, c) => sum + c.share);
    return Tooltip(
      message: colors
          .map((c) => '${c.hex} ${(c.share * 100).round()}%')
          .join('  '),
      child: SizedBox(
        height: 10,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final color in colors)
              Expanded(
                flex: ((color.share / (total == 0 ? 1 : total)) * 1000)
                    .round()
                    .clamp(1, 1000),
                child: ColoredBox(color: hexColor(color.hex)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.item,
    required this.currency,
    required this.onDelete,
  });

  final CatalogItem item;
  final String currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final color = hexColor(item.colorHex);
    return SizedBox(
      width: 210,
      child: Hoverable(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: text.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.colorHex ?? ''} · ${formatMoney(context, item.price, currency)}',
                        style: text.bodySmall,
                      ),
                      if (item.vendorName != null)
                        Text(
                          l10n.addedBy(item.vendorName!),
                          style: text.labelSmall?.copyWith(color: Brand.berry),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
