import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/figure.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/render_view.dart';
import 'group_polls.dart';
import 'look_previews.dart';

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
  final _sparkles = GlobalKey<SparkleBurstState>();
  Look? _look;
  List<CatalogItem> _items = const [];
  List<PreviewLook> _previews = const [];
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
      unawaited(_loadPreviews());
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Previews are a nice extra; if they fail to load the strip just stays hidden.
  Future<void> _loadPreviews() async {
    try {
      final previews = await AppScope.api(context).previews(_eventId);
      if (mounted) setState(() => _previews = previews);
    } catch (_) {}
  }

  Future<void> _compare(PreviewLook earlier) async {
    final look = _look;
    if (look == null) return;
    final current =
        _previews.where((p) => p.current).firstOrNull ??
        _previews.firstWhere((p) => p != earlier, orElse: () => earlier);
    final wear = await showCompareLooks(
      context,
      earlier: earlier,
      current: current,
      currency: look.currency,
      canSwitch: !look.locked,
    );
    if (!wear || !mounted) return;
    final api = AppScope.api(context);
    // Every step of that look is cached, so its preview comes back at once and costs nothing.
    await _apply(() async {
      await api.setLook(
        _eventId,
        garmentId: earlier.garment?.id,
        makeupId: earlier.makeup?.id,
        hairId: earlier.hair?.id,
        clear: {
          if (earlier.garment == null) ItemType.garment,
          if (earlier.makeup == null) ItemType.makeup,
          if (earlier.hair == null) ItemType.hair,
        },
      );
      return api.render(_eventId);
    });
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
      final finished =
          _look?.render.status != 'success' && look.render.status == 'success';
      setState(() => _look = look);
      _schedulePoll();
      if (finished) unawaited(_loadPreviews());
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
    // The current preview moves when the look changes or a render finishes.
    if (look != null) unawaited(_loadPreviews());
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

  Future<void> _toggleLock(Look look) async {
    final locking = !look.locked;
    final api = AppScope.api(context);
    await _apply(() => api.lock(_eventId, locking));
    if (locking && (_look?.locked ?? false)) _sparkles.currentState?.burst();
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
        icon: const Icon(Icons.link, color: Brand.berry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shareLinkReady(formatDate(context, link.expiresAt))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(url),
            ),
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
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Skeleton(height: 420, radius: 26),
                  SizedBox(height: 16),
                  Skeleton(height: 120, radius: 20),
                ],
              ),
            )
          : ErrorRetry(error: _error!, onRetry: _load);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final preview = Reveal(child: _preview(context, look));
        final builder = Reveal(
          delay: const Duration(milliseconds: 120),
          child: _builder(context, look),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 400, child: preview),
                        const SizedBox(width: 32),
                        Expanded(child: builder),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [preview, const SizedBox(height: 28), builder],
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
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Figure(
                clothing: Color(0xFFCFC3BD),
                hair: Color(0xFF9C8E87),
                skin: Color(0xFFE5D6CF),
                width: 110,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.renderNoPhoto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              BrandButton(
                label: l10n.addPhoto,
                icon: Icons.add_a_photo_outlined,
                onPressed: _goToPhoto,
              ),
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
        const SizedBox(height: 16),
        if (render.status == 'idle')
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.renderIdle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (render.status == 'empty')
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.renderEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        BrandButton(
          label: l10n.tryOnButton,
          icon: Icons.auto_fix_high,
          // A light sweep now and then while a changed look waits for its preview.
          attention: true,
          onPressed: render.status == 'idle' && !_busy
              ? () => _apply(() => AppScope.api(context).render(_eventId))
              : null,
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _goToPhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.replacePhoto),
        ),
        if (_previews.length >= 2) ...[
          const SizedBox(height: 18),
          PreviewStrip(previews: _previews, onCompare: _compare),
        ],
      ],
    );
  }

  Widget _builder(BuildContext context, Look look) {
    final l10n = AppLocalizations.of(context);
    final garments = _items.where((i) => i.type == ItemType.garment).toList();
    final makeup = _items.where((i) => i.type == ItemType.makeup).toList();
    final hair = _items.where((i) => i.type == ItemType.hair).toList();
    final enabled = !look.locked && !_busy;

    if (_items.isEmpty) {
      return NoticeBar(l10n.catalogueEmpty, icon: Icons.storefront_outlined);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          icon: Icons.checkroom_outlined,
          title: l10n.sectionOutfit,
          // Undecided between outfits: the group votes on the board.
          trailing: enabled && garments.where((g) => g.hasImage).length >= 2
              ? TextButton.icon(
                  onPressed: () => showAskGroupSheet(context, _eventId),
                  icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                  label: Text(l10n.pollTitle),
                )
              : null,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _NoneCard(
                selected: look.garmentId == null,
                onTap: enabled ? () => _select(ItemType.garment, null) : null,
              ),
              for (final (index, item) in garments.indexed)
                Reveal(
                  delay: Motion.stagger(index, stepMs: 50),
                  child: _GarmentCard(
                    item: item,
                    currency: look.currency,
                    selected: look.garmentId == item.id,
                    onTap: enabled && item.hasImage
                        ? () => _select(ItemType.garment, item.id)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        for (final (icon, title, type, list, selectedId) in [
          (
            Icons.brush_outlined,
            l10n.sectionMakeup,
            ItemType.makeup,
            makeup,
            look.makeupId,
          ),
          (
            Icons.content_cut,
            l10n.sectionHair,
            ItemType.hair,
            hair,
            look.hairId,
          ),
        ])
          if (list.isNotEmpty)
            _Section(
              icon: icon,
              title: title,
              child: Wrap(
                spacing: 10,
                runSpacing: 14,
                children: [
                  _Swatch(
                    label: l10n.none,
                    selected: selectedId == null,
                    onTap: enabled ? () => _select(type, null) : null,
                  ),
                  for (final item in list)
                    _Swatch(
                      color: item.colorHex,
                      label: item.name,
                      price: formatMoney(context, item.price, look.currency),
                      selected: selectedId == item.id,
                      onTap: enabled ? () => _select(type, item.id) : null,
                    ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        _SummaryCard(
          look: look,
          event: widget.event,
          busy: _busy,
          sparkles: _sparkles,
          onLock: () => _toggleLock(look),
          onShare: _share,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 158,
      child: Hoverable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
                          padding: const EdgeInsets.all(8),
                          child: NetImage(
                            item.imageUrl,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.checkroom,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: Motion.medium,
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final color in item.colors.take(3)) ...[
                            ColorDot(color.hex, size: 13),
                            const SizedBox(width: 3),
                          ],
                          const Spacer(),
                          Text(
                            formatMoney(context, item.price, currency),
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
      width: 110,
      height: 120,
      child: Hoverable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.medium,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, color: scheme.outline),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).none,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.price,
  });

  final String? color;
  final String label;
  final String? price;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 88,
      child: Hoverable(
        onTap: onTap,
        borderRadius: 44,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.curve,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color == null
                      ? scheme.surfaceContainerHigh
                      : hexColor(color),
                  boxShadow: color == null
                      ? null
                      : [
                          BoxShadow(
                            color: hexColor(color).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: color == null
                    ? Icon(Icons.block, color: scheme.outline, size: 20)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium,
            ),
            if (price != null)
              Text(
                price!,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.look,
    required this.event,
    required this.busy,
    required this.sparkles,
    required this.onLock,
    required this.onShare,
  });

  final Look look;
  final EventInfo event;
  final bool busy;
  final GlobalKey<SparkleBurstState> sparkles;
  final VoidCallback onLock;
  final void Function(String scope) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cap = event.budgetPerPerson;
    final over = cap != null && look.total > cap;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text(l10n.yourLook, style: text.titleLarge)),
                CountUp(
                  value: look.total,
                  format: (v) => formatMoney(context, v, look.currency),
                  style: Brand.numbers(
                    text.headlineSmall,
                  )?.copyWith(color: over ? scheme.error : scheme.primary),
                ),
              ],
            ),
            if (cap != null) ...[
              const SizedBox(height: 12),
              AnimatedBar(
                value: cap == 0 ? 1 : look.total / cap,
                color: over ? scheme.error : Brand.champagne,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.budgetPerPersonCap(
                  formatMoney(context, cap, look.currency),
                ),
                style: text.bodySmall?.copyWith(
                  color: over ? scheme.error : null,
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (look.locked) ...[
              Reveal(
                child: NoticeBar(l10n.lockedNote, icon: Icons.lock_outline),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SparkleBurst(
                  key: sparkles,
                  child: FilledButton.icon(
                    onPressed: busy || look.garmentId == null ? null : onLock,
                    icon: Icon(
                      look.locked ? Icons.lock_open : Icons.lock_outline,
                    ),
                    label: Text(look.locked ? l10n.unlockLook : l10n.lockLook),
                  ),
                ),
                if (look.hairId != null)
                  OutlinedButton.icon(
                    onPressed: () => onShare('hair'),
                    icon: const Icon(Icons.content_cut),
                    label: Text(l10n.shareHair),
                  ),
                if (!look.isEmpty)
                  OutlinedButton.icon(
                    onPressed: () => onShare('look'),
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(l10n.shareLook),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
