import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../util/format.dart';
import 'common.dart';

/// A participant's current picture with every honest label it needs:
/// simulated or demo, progress, failures and render checks.
class RenderView extends StatelessWidget {
  const RenderView({
    super.key,
    required this.render,
    required this.photoUrl,
    required this.demo,
    this.onRetry,
    this.compact = false,
  });

  final RenderState render;
  final String? photoUrl;
  final bool demo;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = render.resultUrl ?? photoUrl;
    final notices = <Widget>[];

    if (render.status == 'running') {
      notices.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.renderRunning(kindName(l10n, render.current))),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: render.progress > 0 ? render.progress : null,
            ),
          ],
        ),
      );
    }
    if (render.status == 'failed' && render.failure != null) {
      notices.add(
        NoticeBar(
          failureText(l10n, render.failure!),
          icon: Icons.error_outline,
          tone: NoticeTone.warning,
        ),
      );
      if (render.failure!.retryable && onRetry != null) {
        notices.add(
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ),
        );
      }
    }
    if (render.checks != null && !render.checks!.garmentApplied) {
      notices.add(
        NoticeBar(
          l10n.checkNotApplied,
          icon: Icons.warning_amber_outlined,
          tone: NoticeTone.warning,
        ),
      );
    } else if (render.checks?.drift == true) {
      notices.add(NoticeBar(l10n.checkDrift, icon: Icons.palette_outlined));
    }
    if (render.resultUrl != null) {
      if (demo) {
        notices.add(
          NoticeBar(
            l10n.demoRenderBadge,
            icon: Icons.brush_outlined,
            tone: NoticeTone.simulated,
          ),
        );
      } else if (render.mock) {
        notices.add(
          NoticeBar(
            l10n.mockBadge,
            icon: Icons.science_outlined,
            tone: NoticeTone.simulated,
          ),
        );
      }
      if (!compact) {
        notices.add(
          Text(
            l10n.previewDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 3 / 4, child: NetImage(url)),
        ),
        for (final notice in notices) ...[const SizedBox(height: 8), notice],
      ],
    );
  }
}
