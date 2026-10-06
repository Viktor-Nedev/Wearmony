import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/group_frame.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../util/save_png.dart';
import '../../widgets/common.dart';
import 'board_loader.dart';

/// Digital High-Fashion Editorial Lookbook & Press Kit:
/// Magazine cover, partner spreads, ensemble catalogue, color story,
/// and high-resolution image export.
class LookbookScreen extends StatefulWidget {
  const LookbookScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends State<LookbookScreen> with BoardLoader {
  @override
  String get boardEventId => widget.eventId;

  int _currentSpread = 0;
  final _spreadKey = GlobalKey();
  bool _saving = false;

  Future<void> _exportSpread(String eventName) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final boundary =
          _spreadKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await savePng(
        data!.buffer.asUint8List(),
        'wearmony-lookbook-${eventName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-p${_currentSpread + 1}.png',
        text: 'Wearmony Lookbook: $eventName',
      );
      if (savesByDownload) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final b = board;

    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.lookbookTitle)),
        body: boardError == null
            ? const Center(child: CircularProgressIndicator())
            : ErrorRetry(error: boardError!, onRetry: loadBoard),
      );
    }

    final spreads = [
      _MagazineCoverSpread(board: b),
      _PartnerSpotlightSpread(board: b),
      _EnsembleSpread(board: b),
      _ColorStorySpread(board: b),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/e/${widget.eventId}?tab=board'),
        ),
        title: Text(l10n.lookbookTitle),
        actions: [
          IconButton(
            tooltip: l10n.lookbookExportSpread,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _saving ? null : () => _exportSpread(b.event.name),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Spread Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _SpreadTab(
                      index: 0,
                      label: l10n.lookbookSpreadCover,
                      selected: _currentSpread == 0,
                      onTap: () => setState(() => _currentSpread = 0),
                    ),
                    const SizedBox(width: 8),
                    _SpreadTab(
                      index: 1,
                      label: l10n.lookbookSpreadPairs,
                      selected: _currentSpread == 1,
                      onTap: () => setState(() => _currentSpread = 1),
                    ),
                    const SizedBox(width: 8),
                    _SpreadTab(
                      index: 2,
                      label: l10n.lookbookSpreadCollection,
                      selected: _currentSpread == 2,
                      onTap: () => setState(() => _currentSpread = 2),
                    ),
                    const SizedBox(width: 8),
                    _SpreadTab(
                      index: 3,
                      label: l10n.lookbookSpreadStory,
                      selected: _currentSpread == 3,
                      onTap: () => setState(() => _currentSpread = 3),
                    ),
                  ],
                ),
              ),

              // Spread Viewport
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: RepaintBoundary(
                        key: _spreadKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            key: ValueKey(_currentSpread),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B121C),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 32,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: spreads[_currentSpread],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom spread pagination controls
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentSpread > 0
                          ? () => setState(() => _currentSpread--)
                          : null,
                    ),
                    Text(
                      '${_currentSpread + 1} / ${spreads.length}',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentSpread < spreads.length - 1
                          ? () => setState(() => _currentSpread++)
                          : null,
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

class _SpreadTab extends StatelessWidget {
  const _SpreadTab({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Brand.berry
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Brand.rose
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// SPREAD 1: HIGH FASHION MAGAZINE COVER
class _MagazineCoverSpread extends StatelessWidget {
  const _MagazineCoverSpread({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final score = board.harmony.groupScore;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Magazine Masthead
          // Scales down on phones instead of breaking the name over two lines.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'WEARMONY',
              maxLines: 1,
              style: TextStyle(
                fontFamily: Brand.displayFont,
                fontWeight: FontWeight.w900,
                fontSize: 48,
                letterSpacing: 8,
                foreground: Paint()
                  ..shader = Brand.gradient.createShader(
                    const Rect.fromLTWH(0, 0, 400, 50),
                  ),
              ),
            ),
          ),
          Center(
            child: Text(
              l10n.lookbookMasthead.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Main Hero Showcase Frame
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: GroupFrame(
                    board: board,
                    backdrop: FrameBackdrop.ballroom,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Headlines & Editorial Articles Callout
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.event.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: Brand.displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.landingPitch,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // The harmony seal sits beside the stamp, so the cover's labels stay visible.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE5C07B),
                      Color(0xFFC49746),
                      Color(0xFFE5C07B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n.lookbookSeal.toUpperCase(),
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 7,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Simulated barcode & issue stamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        12,
                        (i) => Container(
                          width: (i % 3 == 0) ? 3 : 1.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.lookbookIssue("${DateTime.now().year}").toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// SPREAD 2: COUPLE & PARTNER EDITORIAL SPOTLIGHT
class _PartnerSpotlightSpread extends StatelessWidget {
  const _PartnerSpotlightSpread({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Find couples with partners
    final pairs = <(BoardParticipant, BoardParticipant)>[];
    final seen = <String>{};
    for (final p in board.participants) {
      if (p.pairWith != null && !seen.contains(p.userId)) {
        final partner = board.byId(p.pairWith);
        if (partner != null) {
          pairs.add((p, partner));
          seen.add(p.userId);
          seen.add(partner.userId);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lookbookSpreadPairs.toUpperCase(),
            style: const TextStyle(
              fontFamily: Brand.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.lookbookPairsHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (pairs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  l10n.togetherNoPartner,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            for (final (a, b) in pairs) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    // Person A photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 80,
                        height: 105,
                        child: NetImage(a.pictureUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Person B photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 80,
                        height: 105,
                        child: NetImage(b.pictureUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Names and dialogue
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.displayName} & ${b.displayName}',
                            style: const TextStyle(
                              fontFamily: Brand.displayFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (a.look.garment != null) ...[
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: hexColor(a.look.garment!.colorHex),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    a.look.garment!.name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const Text(
                                '  +  ',
                                style: TextStyle(color: Colors.white54),
                              ),
                              if (b.look.garment != null) ...[
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: hexColor(b.look.garment!.colorHex),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    b.look.garment!.name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lookbookPairNote,
                            style: TextStyle(
                              color: Brand.champagne.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

/// SPREAD 3: THE ENSEMBLE WARDROBE CATALOGUE
class _EnsembleSpread extends StatelessWidget {
  const _EnsembleSpread({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalBudget = board.budget.total;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.lookbookSpreadCollection.toUpperCase(),
                style: const TextStyle(
                  fontFamily: Brand.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: Colors.white,
                ),
              ),
              Text(
                'TOTAL: ${formatMoney(context, totalBudget, board.budget.currency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Brand.champagne,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.lookbookCollectionHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final p in board.participants)
                Container(
                  width: 170,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: NetImage(p.pictureUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (p.look.garment != null) ...[
                        Text(
                          p.look.garment!.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(
                            context,
                            p.look.garment!.price,
                            board.budget.currency,
                          ),
                          style: const TextStyle(
                            color: Brand.champagne,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ] else
                        Text(
                          l10n.noLookYet,
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// SPREAD 4: COLOR STORY & INCLUSION COMMITMENT
class _ColorStorySpread extends StatelessWidget {
  const _ColorStorySpread({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lookbookSpreadStory.toUpperCase(),
            style: const TextStyle(
              fontFamily: Brand.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.lookbookStoryHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Palette Swatches strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lookbookChords.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Brand.rose,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final p in board.participants)
                      if (p.look.garment != null &&
                          p.look.garment!.colorHex != null) ...[
                        Expanded(
                          child: Container(
                            height: 38,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: hexColor(p.look.garment!.colorHex),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Who Wearmony is built for, stated without claiming results not yet measured.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Brand.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.accessible_forward,
                  color: Brand.success,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.lookbookInclusionTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Brand.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.lookbookInclusionBody,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Editorial closing signature
          Center(
            child: Text(
              'Wearmony • Try it on together.',
              style: TextStyle(
                fontFamily: Brand.displayFont,
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
