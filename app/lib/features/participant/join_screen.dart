import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: PageBody(
        children: [
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.joinCodeLabel),
            onChanged: (_) => _lookUp(),
          ),
          const SizedBox(height: 8),
          if (_preview != null)
            NoticeBar(
              '${l10n.joiningEvent(_preview!.name)} (${templateName(l10n, _preview!.template)})',
              icon: Icons.celebration_outlined,
            )
          else if (_previewError != null)
            NoticeBar(
              l10n.codeNotFound,
              icon: Icons.search_off,
              tone: NoticeTone.warning,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            decoration: InputDecoration(labelText: l10n.yourNameLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canJoin ? _join : null,
            child: Text(l10n.joinButton),
          ),
        ],
      ),
    );
  }
}
