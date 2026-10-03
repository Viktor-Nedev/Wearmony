import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/group_frame.dart';
import '../../ui/motion.dart';
import '../../util/save_png.dart';
import '../../widgets/common.dart';
import 'board_loader.dart';

/// The group photo: everyone's current look in one frame, saved as an image.
class GroupFrameScreen extends StatefulWidget {
  const GroupFrameScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<GroupFrameScreen> createState() => _GroupFrameScreenState();
}

class _GroupFrameScreenState extends State<GroupFrameScreen> with BoardLoader {
  final _frame = GlobalKey();
  FrameBackdrop? _backdrop;
  bool _saving = false;

  @override
  String get boardEventId => widget.eventId;

  @override
  Duration get refreshEvery => const Duration(seconds: 20);

  static String _fileName(String eventName) {
    final slug = eventName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'wearmony-${slug.isEmpty ? 'group' : slug}.png';
  }

  Future<void> _save(String eventName) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final boundary =
          _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // About 2000 pixels wide, whatever the screen.
      final ratio = (2000 / boundary.size.width).clamp(1.0, 6.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await savePng(
        data!.buffer.asUint8List(),
        _fileName(eventName),
        text: l10n.frameShareText(eventName),
      );
      if (savesByDownload) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.frameSaved)));
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.frameSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final data = board;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/e/${widget.eventId}?tab=board'),
        ),
        title: Text(l10n.frameTitle),
      ),
      body: data == null
          ? (boardError == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Skeleton(height: 420, radius: 28),
                  )
                : ErrorRetry(error: boardError!, onRetry: loadBoard))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.frameSubtitle,
                          style: text.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Reveal(
                          scale: 0.97,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Brand.plum.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: RepaintBoundary(
                              key: _frame,
                              child: AnimatedSwitcher(
                                duration: Motion.medium,
                                child: GroupFrame(
                                  key: ValueKey(
                                    _backdrop ??
                                        FrameBackdrop.forTemplate(
                                          data.event.template,
                                        ),
                                  ),
                                  board: data,
                                  backdrop:
                                      _backdrop ??
                                      FrameBackdrop.forTemplate(
                                        data.event.template,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(l10n.frameBackdrop, style: text.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final backdrop in FrameBackdrop.values)
                              ChoiceChip(
                                avatar: _BackdropSwatch(backdrop: backdrop),
                                label: Text(backdropName(l10n, backdrop)),
                                selected:
                                    backdrop ==
                                    (_backdrop ??
                                        FrameBackdrop.forTemplate(
                                          data.event.template,
                                        )),
                                onSelected: (_) =>
                                    setState(() => _backdrop = backdrop),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: BrandButton(
                            label: savesByDownload
                                ? l10n.frameSave
                                : l10n.frameShare,
                            icon: savesByDownload
                                ? Icons.download_rounded
                                : Icons.ios_share_rounded,
                            expand: false,
                            onPressed: _saving
                                ? null
                                : () => _save(data.event.name),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.frameHint,
                          textAlign: TextAlign.center,
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BackdropSwatch extends StatelessWidget {
  const _BackdropSwatch({required this.backdrop});

  final FrameBackdrop backdrop;

  @override
  Widget build(BuildContext context) {
    final colors = switch (backdrop) {
      FrameBackdrop.ballroom => const [Color(0xFF2A0F22), Color(0xFFF3D9A4)],
      FrameBackdrop.stage => const [Color(0xFF9B1C2E), Color(0xFF4A0811)],
      FrameBackdrop.garden => const [Color(0xFFD9E8D2), Color(0xFF8DB580)],
      FrameBackdrop.studio => const [Color(0xFFFFFCF8), Color(0xFFDCCFC6)],
    };
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
