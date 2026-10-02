import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/figure.dart';
import '../../ui/motion.dart';
import '../../widgets/form_scaffold.dart';

/// Photo capture with guidance, a pose tag chosen by the participant, and the quality gate result.
class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  Participant? _me;
  Pose _pose = Pose.standing;
  bool _busy = false;
  String? _rejection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_me == null) _load();
  }

  Future<void> _load() async {
    final event = await runWithFeedback(
      context,
      () => AppScope.api(context).event(widget.eventId),
    );
    if (!mounted || event?.me == null) return;
    if (!event!.me!.hasConsent) {
      context.pushReplacement('/e/${widget.eventId}/consent');
      return;
    }
    setState(() {
      _me = event.me;
      _pose = event.me!.pose ?? Pose.standing;
    });
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    setState(() {
      _busy = true;
      _rejection = null;
    });
    final api = AppScope.api(context);
    try {
      final me = await api.uploadPhoto(
        widget.eventId,
        await file.readAsBytes(),
        _pose,
      );
      if (mounted) setState(() => _me = me);
    } catch (error) {
      if (mounted) setState(() => _rejection = errorText(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deletePhotoConfirm)) return;
    if (!mounted) return;
    final me = await runWithFeedback(
      context,
      () => AppScope.api(context).deletePhoto(widget.eventId),
      success: l10n.deletedDone,
    );
    if (me != null && mounted) setState(() => _me = me);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final me = _me;
    final quality = me?.photoQuality;
    final hasCamera =
        !kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    final tips = [
      (Icons.wb_sunny_outlined, l10n.photoTipLight),
      (Icons.crop_portrait, l10n.photoTipFrame),
      (Icons.person_outline, l10n.photoTipAlone),
      (Icons.checkroom_outlined, l10n.photoTipClothes),
    ];

    Widget poseCard(Pose pose, String label) {
      final selected = _pose == pose;
      return Expanded(
        child: Hoverable(
          onTap: _busy ? null : () => setState(() => _pose = pose),
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.curve,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.08)
                  : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Figure(
                  clothing: selected ? Brand.berry : const Color(0xFFB9ABB3),
                  hair: const Color(0xFF3B2A20),
                  seated: pose == Pose.seated,
                  width: 62,
                ),
                const SizedBox(height: 8),
                Text(label, style: text.titleSmall),
              ],
            ),
          ),
        ),
      );
    }

    return FormScaffold(
      title: l10n.photoTitle,
      icon: Icons.photo_camera_outlined,
      maxWidth: 640,
      children: [
        Text(l10n.photoTipsTitle, style: text.titleSmall),
        const SizedBox(height: 10),
        for (final (index, (icon, tip)) in tips.indexed)
          Reveal(
            delay: Motion.stagger(index + 1, stepMs: 70),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(l10n.poseQuestion, style: text.titleSmall),
        const SizedBox(height: 10),
        Row(
          children: [
            poseCard(Pose.standing, l10n.poseStanding),
            const SizedBox(width: 12),
            poseCard(Pose.seated, l10n.poseSeated),
          ],
        ),
        AnimatedSize(
          duration: Motion.medium,
          child: _pose == Pose.seated
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: NoticeBar(l10n.poseSeatedNote, icon: Icons.accessible),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 20),
        if (me.hasPhoto || _busy)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (me.hasPhoto)
                        NetImage(me.photoUrl)
                      else
                        ColoredBox(color: scheme.surfaceContainerHigh),
                      if (_busy) const ScanningOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_busy) ...[
          const SizedBox(height: 12),
          Text(
            l10n.checkingPhoto,
            textAlign: TextAlign.center,
            style: text.titleSmall,
          ),
        ],
        if (_rejection != null) ...[
          const SizedBox(height: 16),
          Reveal(
            child: NoticeBar(
              _rejection!,
              icon: Icons.error_outline,
              tone: NoticeTone.warning,
            ),
          ),
        ],
        if (me.hasPhoto && quality != null && !_busy) ...[
          const SizedBox(height: 16),
          if (quality.issues.isEmpty && quality.warnings.isEmpty)
            Reveal(
              child: NoticeBar(
                l10n.photoReady,
                icon: Icons.check_circle_outline,
              ),
            )
          else
            for (final (index, issue) in [
              ...quality.issues,
              ...quality.warnings,
            ].indexed) ...[
              Reveal(
                delay: Motion.stagger(index),
                child: NoticeBar(
                  photoIssueText(l10n, issue),
                  icon: Icons.tips_and_updates_outlined,
                  tone: NoticeTone.warning,
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
        const SizedBox(height: 20),
        if (hasCamera) ...[
          BrandButton(
            label: l10n.takePhoto,
            icon: Icons.photo_camera_outlined,
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(me.hasPhoto ? l10n.replacePhoto : l10n.choosePhoto),
        ),
        if (me.hasPhoto) ...[
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _busy
                ? null
                : () => context.go('/e/${widget.eventId}?tab=myLook'),
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.photoNextStep),
          ),
          TextButton(
            onPressed: _busy ? null : _delete,
            child: Text(l10n.deletePhoto),
          ),
        ],
      ],
    );
  }
}
