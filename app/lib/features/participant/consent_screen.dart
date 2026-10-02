import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../widgets/common.dart';
import '../../widgets/form_scaffold.dart';

/// Explicit consent before any photo is uploaded.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _checked = <int>{};
  bool _busy = false;

  Future<void> _agree() async {
    setState(() => _busy = true);
    final done = await runWithFeedback(
      context,
      () => AppScope.api(context).consent(widget.eventId),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (done != null) context.pushReplacement('/e/${widget.eventId}/photo');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final statements = [
      (Icons.verified_user_outlined, l10n.consentAdult),
      (Icons.lock_outline, l10n.consentPrivate),
      (Icons.delete_outline, l10n.consentDelete),
      (Icons.visibility_outlined, l10n.consentPreview),
    ];
    return FormScaffold(
      title: l10n.consentTitle,
      icon: Icons.shield_outlined,
      children: [
        for (final (index, (icon, statement)) in statements.indexed) ...[
          Reveal(
            delay: Motion.stagger(index + 1, stepMs: 80),
            child: Hoverable(
              onTap: () => setState(
                () => _checked.contains(index)
                    ? _checked.remove(index)
                    : _checked.add(index),
              ),
              child: AnimatedContainer(
                duration: Motion.medium,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _checked.contains(index)
                      ? scheme.primary.withValues(alpha: 0.08)
                      : scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _checked.contains(index)
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statement,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Checkbox(
                      value: _checked.contains(index),
                      onChanged: (value) => setState(
                        () => value == true
                            ? _checked.add(index)
                            : _checked.remove(index),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        BrandButton(
          label: l10n.consentButton,
          icon: Icons.check,
          onPressed: _checked.length == statements.length && !_busy
              ? _agree
              : null,
        ),
      ],
    );
  }
}
