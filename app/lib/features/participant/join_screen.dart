import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../widgets/form_scaffold.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late final _code = TextEditingController(
    text: widget.initialCode?.toUpperCase(),
  );
  final _name = TextEditingController();
  JoinPreview? _preview;
  Object? _previewError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialCode ?? '').length >= 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookUp());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _lookUp() async {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _preview = null);
      return;
    }
    try {
      final preview = await AppScope.api(context).joinPreview(code);
      if (mounted) {
        setState(() {
          _preview = preview;
          _previewError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _preview = null;
          _previewError = error;
        });
      }
    }
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    final eventId = await runWithFeedback(
      context,
      () => AppScope.api(context).join(_code.text.trim(), _name.text.trim()),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (eventId != null) context.go('/e/$eventId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canJoin = _preview != null && _name.text.trim().isNotEmpty && !_busy;
    final text = Theme.of(context).textTheme;
    return FormScaffold(
      title: l10n.joinTitle,
      icon: Icons.group_add_outlined,
      children: [
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(labelText: l10n.joinCodeLabel),
          onChanged: (_) => _lookUp(),
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.curve,
          child: _preview != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Reveal(
                    key: ValueKey(_preview!.name),
                    child: NoticeBar(
                      '${l10n.joiningEvent(_preview!.name)} (${templateName(l10n, _preview!.template)})',
                      icon: Icons.celebration_outlined,
                    ),
                  ),
                )
              : _previewError != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: NoticeBar(
                    l10n.codeNotFound,
                    icon: Icons.search_off,
                    tone: NoticeTone.warning,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          decoration: InputDecoration(
            labelText: l10n.yourNameLabel,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        BrandButton(
          label: l10n.joinButton,
          icon: Icons.arrow_forward,
          onPressed: canJoin ? _join : null,
        ),
      ],
    );
  }
}
