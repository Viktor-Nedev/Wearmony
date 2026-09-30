import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/render_view.dart';

/// Look builder for one participant: catalogue browser, try-on, total price, lock and share.
class MyLookTab extends StatefulWidget {
  const MyLookTab({
    super.key,
    required this.event,
    required this.onEventChanged,
  });

  final EventInfo event;
  final Future<void> Function() onEventChanged;

  @override
  State<MyLookTab> createState() => _MyLookTabState();
}

class _MyLookTabState extends State<MyLookTab> {
  Look? _look;
  List<CatalogItem> _items = const [];
  Object? _error;
  bool _busy = false;
  Timer? _poll;

  String get _eventId => widget.event.id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_look == null && _error == null) _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = AppScope.api(context);
    try {
      final results = await Future.wait([
        api.look(_eventId),
        api.items(_eventId),
      ]);
      if (!mounted) return;
      setState(() {
        _look = results[0] as Look;
        _items = results[1] as List<CatalogItem>;
        _error = null;
      });
      _schedulePoll();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (_look?.render.isRunning ?? false) {
      _poll = Timer(const Duration(seconds: 2), _refresh);
    }
  }

  Future<void> _refresh() async {
    try {
      final look = await AppScope.api(context).look(_eventId);
      if (!mounted) return;
      setState(() => _look = look);
      _schedulePoll();
    } catch (_) {
      if (mounted) _poll = Timer(const Duration(seconds: 5), _refresh);
    }
  }

  Future<void> _apply(Future<Look> Function() action) async {
    setState(() => _busy = true);
    final look = await runWithFeedback(context, action);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (look != null) _look = look;
    });
    _schedulePoll();
  }

  void _select(ItemType type, String? id) {
    final api = AppScope.api(context);
    _apply(
      () => api.setLook(
        _eventId,
        garmentId: type == ItemType.garment ? id : null,
        makeupId: type == ItemType.makeup ? id : null,
        hairId: type == ItemType.hair ? id : null,
        clear: id == null ? {type} : const {},
      ),
    );
  }

  Future<void> _share(String scope) async {
    final l10n = AppLocalizations.of(context);
    final link = await runWithFeedback(
      context,
      () => AppScope.api(context).createVendorLink(_eventId, scope: scope),
    );
    if (link == null || !mounted) return;
    final url = appLink(link.path);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shareLinkReady(formatDate(context, link.expiresAt))),
            const SizedBox(height: 8),
            SelectableText(url),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.copyLink),
          ),
        ],
      ),
    );
  }

  Future<void> _goToPhoto() async {
    final me = widget.event.me;
    final path = me != null && me.hasConsent ? 'photo' : 'consent';
    await context.push('/e/$_eventId/$path');
    await widget.onEventChanged();
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final look = _look;
    if (look == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : ErrorRetry(error: _error!, onRetry: _load);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final preview = _preview(context, look);
        final builder = _builder(context, look);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 360, child: preview),
                        const SizedBox(width: 24),
                        Expanded(child: builder),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [preview, const SizedBox(height: 24), builder],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _preview(BuildContext context, Look look) {
    final l10n = AppLocalizations.of(context);
    final me = widget.event.me;
    if (me == null || !me.hasPhoto) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 48),
              const SizedBox(height: 12),
              Text(l10n.renderNoPhoto, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _goToPhoto, child: Text(l10n.addPhoto)),
            ],
          ),
        ),
      );
    }

    final render = look.render;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RenderView(
          render: render,
          photoUrl: me.photoUrl,
          demo: widget.event.demo,
          onRetry: () =>
              _apply(() => AppScope.api(context).render(_eventId, retry: true)),
        ),
        const SizedBox(height: 12),
        if (render.status == 'idle')
          Text(l10n.renderIdle, textAlign: TextAlign.center),
        if (render.status == 'empty')
          Text(l10n.renderEmpty, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: render.status == 'idle' && !_busy
              ? () => _apply(() => AppScope.api(context).render(_eventId))
              : null,
          icon: const Icon(Icons.auto_fix_high),
          label: Text(l10n.tryOnButton),
        ),
        TextButton.icon(
          onPressed: _goToPhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.replacePhoto),
        ),
      ],
    );
  }

  Widget _builder(BuildContext context, Look look) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final garments = _items.where((i) => i.type == ItemType.garment).toList();
    final makeup = _items.where((i) => i.type == ItemType.makeup).toList();
    final hair = _items.where((i) => i.type == ItemType.hair).toList();
    final enabled = !look.locked && !_busy;

    if (_items.isEmpty) return NoticeBar(l10n.catalogueEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sectionOutfit, style: text.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _NoneCard(
              selected: look.garmentId == null,
              onTap: enabled ? () => _select(ItemType.garment, null) : null,
            ),
            for (final item in garments)
              _GarmentCard(
                item: item,
                currency: look.currency,
                selected: look.garmentId == item.id,
                onTap: enabled && item.hasImage
                    ? () => _select(ItemType.garment, item.id)
                    : null,
              ),
          ],
        ),
        for (final (title, type, list, selectedId) in [
          (l10n.sectionMakeup, ItemType.makeup, makeup, look.makeupId),
          (l10n.sectionHair, ItemType.hair, hair, look.hairId),
        ])
          if (list.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.none),
                  selected: selectedId == null,
                  onSelected: enabled ? (_) => _select(type, null) : null,
                ),
                for (final item in list)
                  ChoiceChip(
                    avatar: ColorDot(item.colorHex, size: 18),
                    label: Text(
                      '${item.name} · ${formatMoney(context, item.price, look.currency)}',
                    ),
                    selected: selectedId == item.id,
                    onSelected: enabled ? (_) => _select(type, item.id) : null,
                  ),
              ],
            ),
          ],
        const SizedBox(height: 24),
        Text(
          l10n.lookTotal(formatMoney(context, look.total, look.currency)),
          style: text.titleLarge,
        ),
        if (widget.event.budgetPerPerson != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.budgetPerPersonCap(
              formatMoney(
                context,
                widget.event.budgetPerPerson!,
                look.currency,
              ),
            ),
            style: text.bodySmall?.copyWith(
              color: look.total > widget.event.budgetPerPerson!
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (look.locked) ...[
          NoticeBar(l10n.lockedNote, icon: Icons.lock_outline),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _busy || look.garmentId == null
                  ? null
                  : () => _apply(
                      () => AppScope.api(context).lock(_eventId, !look.locked),
                    ),
              icon: Icon(look.locked ? Icons.lock_open : Icons.lock_outline),
              label: Text(look.locked ? l10n.unlockLook : l10n.lockLook),
            ),
            if (look.hairId != null)
              OutlinedButton.icon(
                onPressed: () => _share('hair'),
                icon: const Icon(Icons.content_cut),
                label: Text(l10n.shareHair),
              ),
            if (!look.isEmpty)
              OutlinedButton.icon(
                onPressed: () => _share('look'),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(l10n.shareLook),
              ),
          ],
        ),
      ],
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({
    required this.item,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final CatalogItem item;
  final String currency;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ColoredBox(
                  color: Colors.white,
                  child: NetImage(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    placeholderIcon: Icons.checkroom,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final color in item.colors.take(3)) ...[
                          ColorDot(color.hex, size: 14),
                          const SizedBox(width: 4),
                        ],
                        const Spacer(),
                        Text(
                          formatMoney(context, item.price, currency),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
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

class _NoneCard extends StatelessWidget {
  const _NoneCard({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      height: 120,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Center(child: Text(AppLocalizations.of(context).none)),
        ),
      ),
    );
  }
}
