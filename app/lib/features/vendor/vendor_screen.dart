import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/before_after.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/item_form.dart';
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
    Widget body;
    if (view == null) {
      body = _error == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_off, size: 40, color: Brand.berry),
                      const SizedBox(height: 12),
                      Text(
                        _error is ApiException &&
                                (_error as ApiException).code == 'link_expired'
                            ? l10n.vendorExpired
                            : l10n.vendorNotFound,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
    } else {
      body = view.scope == 'catalogue'
          ? _catalogue(context, view)
          : _look(context, view);
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BrandMark(size: 22),
        actions: const [LanguageMenu(), SizedBox(width: 8)],
      ),
      body: AuroraBackground(intensity: 0.6, child: SafeArea(child: body)),
    );
  }

  Widget _frame(List<Widget> children) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Reveal(
          scale: 0.97,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _look(BuildContext context, VendorView view) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return _frame([
      Text(l10n.vendorTitle, style: text.headlineMedium),
      const SizedBox(height: 4),
      Text(
        l10n.vendorFor(view.eventName, view.participantName ?? ''),
        style: text.titleMedium,
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            avatar: const Icon(Icons.schedule, size: 16),
            label: Text(
              l10n.vendorExpires(formatDate(context, view.expiresAt)),
            ),
          ),
          Chip(
            avatar: const Icon(Icons.visibility_outlined, size: 16),
            label: Text(l10n.vendorReadOnly),
          ),
        ],
      ),
      if (view.demo) ...[
        const SizedBox(height: 10),
        NoticeBar(
          l10n.demoBanner,
          icon: Icons.brush_outlined,
          tone: NoticeTone.simulated,
        ),
      ],
      const SizedBox(height: 20),
      if (view.hair != null)
        _ColorHero(
          title: l10n.sectionHair,
          item: view.hair!,
          currency: view.currency,
        ),
      if (view.makeup != null)
        _ColorHero(
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
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: view.resultUrl != null && view.photoUrl != null
              ? BeforeAfter(
                  before: NetImage(view.photoUrl),
                  after: NetImage(view.resultUrl),
                  beforeLabel: l10n.vendorBefore,
                  afterLabel: l10n.vendorAfter,
                )
              : NetImage(view.photoUrl),
        ),
      ),
      if (view.resultUrl != null) ...[
        const SizedBox(height: 10),
        if (view.resultIsSimulated)
          NoticeBar(
            view.demo ? l10n.demoRenderBadge : l10n.mockBadge,
            icon: Icons.science_outlined,
            tone: NoticeTone.simulated,
          ),
        const SizedBox(height: 6),
        Text(l10n.previewDisclaimer, style: text.bodySmall),
      ],
    ]);
  }

  Widget _catalogue(BuildContext context, VendorView view) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return _frame([
      Text(
        l10n.vendorCatalogueTitle(view.eventName),
        style: text.headlineMedium,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: const Icon(Icons.schedule, size: 16),
          label: Text(l10n.vendorExpires(formatDate(context, view.expiresAt))),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 220,
            child: BrandButton(
              label: l10n.addGarment,
              icon: Icons.checkroom,
              onPressed: _busy ? null : () => _addItem(ItemType.garment),
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
            onPressed: _busy ? null : () => _addItem(ItemType.makeup),
            icon: const Icon(Icons.brush_outlined),
            label: Text(l10n.addMakeup),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
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
      const SizedBox(height: 20),
      Text(l10n.vendorItemsInEvent, style: text.titleLarge),
      const SizedBox(height: 8),
      for (final (index, item) in view.items.indexed)
        Reveal(
          delay: Motion.stagger(index),
          child: Card(
            child: ListTile(
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
          ),
        ),
    ]);
  }
}

/// A big glowing swatch: exactly the color the hairdresser or shop needs.
class _ColorHero extends StatelessWidget {
  const _ColorHero({
    required this.title,
    required this.item,
    required this.currency,
  });

  final String title;
  final CatalogItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = hexColor(item.colorHex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: Motion.reduced(context) ? 1 : 0.6, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: text.labelSmall?.copyWith(letterSpacing: 1.2),
                ),
                Text(item.name, style: text.headlineSmall),
                SelectableText(
                  '${item.colorHex ?? ''} · ${formatMoney(context, item.price, currency)}',
                  style: text.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
