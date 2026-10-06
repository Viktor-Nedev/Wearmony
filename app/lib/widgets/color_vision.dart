import 'package:flutter/material.dart';

import '../api/models.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../ui/motion.dart';
import '../util/format.dart';
import 'common.dart';

/// The group's outfits as they might look to someone with a color vision
/// deficiency, and the outfits that would look alike to them. The simulation
/// is computed on the backend; it is informational and never changes a score.
class ColorVisionCard extends StatefulWidget {
  const ColorVisionCard({super.key, required this.board});

  final Board board;

  @override
  State<ColorVisionCard> createState() => _ColorVisionCardState();
}

class _ColorVisionCardState extends State<ColorVisionCard> {
  static const _modes = ['typical', 'protan', 'deutan', 'tritan'];

  String _mode = 'typical';
  List<VisionView>? _views;
  Object? _error;
  String? _loadedFor;

  /// Changes whenever someone's colors change, so the views are fetched again.
  String _signature(Board board) => [
    for (final p in board.participants)
      '${p.userId}:${p.look.garment?.colorHex}:${p.look.makeup?.colorHex}:${p.look.hair?.colorHex}',
  ].join('|');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(ColorVisionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    final signature = _signature(widget.board);
    if (signature == _loadedFor) return;
    _loadedFor = signature;
    try {
      final views = await AppScope.api(
        context,
      ).colorVision(widget.board.event.id);
      if (mounted) {
        setState(() {
          _views = views;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  String _modeLabel(AppLocalizations l10n, String mode) => switch (mode) {
    'protan' => l10n.visionProtan,
    'deutan' => l10n.visionDeutan,
    'tritan' => l10n.visionTritan,
    _ => l10n.visionTypical,
  };

  String _modeHint(AppLocalizations l10n, String mode) => switch (mode) {
    'protan' => l10n.visionProtanHint,
    'deutan' => l10n.visionDeutanHint,
    'tritan' => l10n.visionTritanHint,
    _ => l10n.visionTypicalHint,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final view = _views?.where((v) => v.mode == _mode).firstOrNull;
    final people = widget.board.participants
        .where((p) => p.look.garment != null)
        .toList();
    // Any view's alike-pairs, so the switcher can mark the views worth a look.
    bool hasAlike(String mode) =>
        _views?.any((v) => v.mode == mode && v.lookAlike.isNotEmpty) ?? false;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.visionTitle, style: text.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.visionSubtitle,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final mode in _modes)
                    ButtonSegment(
                      value: mode,
                      label: Text(_modeLabel(l10n, mode)),
                      icon: hasAlike(mode)
                          ? const Icon(Icons.error_outline, size: 16)
                          : null,
                    ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: Motion.fast,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                _modeHint(l10n, _mode),
                key: ValueKey(_mode),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              ErrorRetry(
                error: _error!,
                onRetry: () {
                  _loadedFor = null;
                  _load();
                },
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final person in people)
                    _PersonColors(
                      name: person.isMe ? l10n.you : person.displayName,
                      outfit: _mode == 'typical'
                          ? person.look.garment?.colorHex
                          : view?.byId(person.userId)?.outfit,
                      lips: _mode == 'typical'
                          ? person.look.makeup?.colorHex
                          : view?.byId(person.userId)?.lips,
                      hair: _mode == 'typical'
                          ? person.look.hair?.colorHex
                          : view?.byId(person.userId)?.hair,
                    ),
                ],
              ),
            const SizedBox(height: 16),
            if (_mode != 'typical' && view != null)
              AnimatedSwitcher(
                duration: Motion.medium,
                child: view.lookAlike.isEmpty
                    ? NoticeBar(
                        l10n.visionNoAlike,
                        key: ValueKey('none_$_mode'),
                        icon: Icons.check_circle_outline,
                      )
                    : Column(
                        key: ValueKey('alike_$_mode'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final pair in view.lookAlike)
                            _AlikeRow(pair: pair, view: view),
                        ],
                      ),
              ),
            const SizedBox(height: 10),
            Text(
              l10n.visionNote,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A person's outfit as a large disc with lip and hair dots; colors morph between views.
class _PersonColors extends StatelessWidget {
  const _PersonColors({
    required this.name,
    required this.outfit,
    required this.lips,
    required this.hair,
  });

  final String name;
  final String? outfit;
  final String? lips;
  final String? hair;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = Motion.reduced(context) ? Duration.zero : Motion.slow;
    Widget disc(String? hex, double size) => TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: hexColor(hex)),
      duration: duration,
      curve: Motion.curve,
      builder: (context, color, _) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.black).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: 78,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                disc(outfit, 60),
                if (hair != null)
                  Positioned(left: -4, top: -4, child: disc(hair, 22)),
                if (lips != null)
                  Positioned(right: -4, bottom: 0, child: disc(lips, 20)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _AlikeRow extends StatelessWidget {
  const _AlikeRow({required this.pair, required this.view});

  final LookAlikePair pair;
  final VisionView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final a = view.byId(pair.people[0])?.outfit;
    final b = view.byId(pair.people[1])?.outfit;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Brand.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Brand.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            ColorDot(a, size: 22),
            const SizedBox(width: 4),
            ColorDot(b, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.visionAlike(
                  pair.names[0],
                  pair.names[1],
                  pair.typicalDeltaE.toStringAsFixed(1),
                  pair.deltaE.toStringAsFixed(1),
                ),
                style: text.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
