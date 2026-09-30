import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.photoTitle)),
      body: me == null
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.photoTipsTitle, style: text.titleMedium),
                        const SizedBox(height: 8),
                        for (final tip in [
                          l10n.photoTipLight,
                          l10n.photoTipFrame,
                          l10n.photoTipAlone,
                          l10n.photoTipClothes,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  '),
                                Expanded(child: Text(tip)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.poseQuestion, style: text.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<Pose>(
                  segments: [
                    ButtonSegment(
                      value: Pose.standing,
                      label: Text(l10n.poseStanding),
                      icon: const Icon(Icons.accessibility_new),
                    ),
                    ButtonSegment(
                      value: Pose.seated,
                      label: Text(l10n.poseSeated),
                      icon: const Icon(Icons.accessible),
                    ),
                  ],
                  selected: {_pose},
                  onSelectionChanged: _busy
                      ? null
                      : (value) => setState(() => _pose = value.first),
                ),
                if (_pose == Pose.seated) ...[
                  const SizedBox(height: 8),
                  NoticeBar(l10n.poseSeatedNote, icon: Icons.accessible),
                ],
                const SizedBox(height: 16),
                if (me.hasPhoto)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: NetImage(me.photoUrl),
                        ),
                      ),
                    ),
                  ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(l10n.checkingPhoto, textAlign: TextAlign.center),
                ],
                if (_rejection != null) ...[
                  const SizedBox(height: 16),
                  NoticeBar(
                    _rejection!,
                    icon: Icons.error_outline,
                    tone: NoticeTone.warning,
                  ),
                ],
                if (me.hasPhoto && quality != null && !_busy) ...[
                  const SizedBox(height: 16),
                  if (quality.issues.isEmpty && quality.warnings.isEmpty)
                    NoticeBar(l10n.photoReady, icon: Icons.check_circle_outline)
                  else
                    for (final issue in [
                      ...quality.issues,
                      ...quality.warnings,
                    ]) ...[
                      NoticeBar(
                        photoIssueText(l10n, issue),
                        icon: Icons.tips_and_updates_outlined,
                        tone: NoticeTone.warning,
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
                const SizedBox(height: 16),
                if (hasCamera)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.takePhoto),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    me.hasPhoto ? l10n.replacePhoto : l10n.choosePhoto,
                  ),
                ),
                if (me.hasPhoto) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => context.go('/e/${widget.eventId}?tab=myLook'),
                    child: Text(l10n.photoNextStep),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    child: Text(l10n.deletePhoto),
                  ),
                ],
              ],
            ),
    );
  }
}
