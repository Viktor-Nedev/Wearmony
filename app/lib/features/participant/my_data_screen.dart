import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/motion.dart';
import '../../widgets/common.dart';
import '../../widgets/form_scaffold.dart';

/// Where a participant deletes their own data, at any time.
class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  EventInfo? _event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null) {
      AppScope.api(context)
          .event(widget.eventId)
          .then((event) {
            if (mounted) setState(() => _event = event);
          })
          .catchError((_) {});
    }
  }

  Future<void> _deletePhoto() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deletePhotoConfirm) || !mounted) return;
    await runWithFeedback(
      context,
      () => AppScope.api(context).deletePhoto(widget.eventId),
      success: l10n.deletedDone,
    );
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.leaveEventConfirm(_event?.name ?? '')) ||
        !mounted) {
      return;
    }
    final done = await runWithFeedback(
      context,
      () => AppScope.api(context).leaveEvent(widget.eventId).then((_) => true),
      success: l10n.deletedDone,
    );
    if (done == true && mounted) context.go('/');
  }

  Future<void> _deleteEverywhere() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(context, l10n.deleteEverywhereConfirm) || !mounted) {
      return;
    }
    final done = await runWithFeedback(
      context,
      () => AppScope.api(context).deleteAllMyData(),
      success: l10n.deletedDone,
    );
    if (done != null && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const red = Color(0xFFC0392B);
    final scheme = Theme.of(context).colorScheme;
    final actions = [
      (Icons.no_photography_outlined, l10n.deletePhoto, _deletePhoto, false),
      (Icons.logout, l10n.leaveEvent, _leave, false),
      (
        Icons.delete_forever_outlined,
        l10n.deleteEverywhere,
        _deleteEverywhere,
        true,
      ),
    ];
    return FormScaffold(
      title: l10n.myDataTitle,
      icon: Icons.privacy_tip_outlined,
      subtitle: l10n.myDataExplain,
      children: [
        for (final (index, (icon, label, action, danger))
            in actions.indexed) ...[
          Reveal(
            delay: Motion.stagger(index + 1, stepMs: 80),
            child: Hoverable(
              onTap: action,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: danger
                      ? red.withValues(alpha: 0.07)
                      : scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: danger
                        ? red.withValues(alpha: 0.4)
                        : scheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: danger ? red : scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: danger ? red : null,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: danger ? red : null),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
