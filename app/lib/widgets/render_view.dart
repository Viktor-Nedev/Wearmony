import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../ui/before_after.dart';
import '../ui/effects.dart';
import '../ui/motion.dart';
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
    final running = render.status == 'running';
    final compare =
        !compact &&
        render.status == 'success' &&
        render.resultUrl != null &&
        photoUrl != null;
    final notices = <Widget>[];

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
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
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

    final picture = compare
        ? BeforeAfter(
            key: ValueKey(render.resultUrl),
            before: NetImage(photoUrl),
            after: NetImage(render.resultUrl),
            beforeLabel: l10n.vendorBefore,
            afterLabel: l10n.vendorAfter,
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: Motion.slow,
                switchInCurve: Motion.emphasized,
                child: KeyedSubtree(key: ValueKey(url), child: NetImage(url)),
              ),
              if (running) const ScanningOverlay(),
              if (running)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _ProgressPill(
                    label: l10n.renderRunning(kindName(l10n, render.current)),
                    progress: render.progress,
                  ),
                ),
            ],
          );

    final radius = BorderRadius.circular(compact ? 20 : 26);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Brand.plum.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: AspectRatio(aspectRatio: 3 / 4, child: picture),
          ),
        ),
        if (render.steps.length > 1 && !compact) ...[
          const SizedBox(height: 14),
          RenderSteps(steps: render.steps),
        ],
        for (final notice in notices) ...[const SizedBox(height: 10), notice],
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (progress > 0)
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// Outfit → lip color → hair color, with each step's state.
class RenderSteps extends StatelessWidget {
  const RenderSteps({super.key, required this.steps});

  final List<RenderStep> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (index, step) in steps.indexed) ...[
          if (index > 0)
            Expanded(
              child: AnimatedContainer(
                duration: Motion.medium,
                height: 2,
                color: step.status == 'pending'
                    ? scheme.outlineVariant
                    : scheme.primary,
              ),
            ),
          _StepDot(step: step, label: kindName(l10n, step.kind)),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step, required this.label});

  final RenderStep step;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, icon) = switch (step.status) {
      'success' => (Brand.success, Icons.check),
      'failed' => (scheme.error, Icons.close),
      'running' => (scheme.primary, _kindIcon(step.kind)),
      _ => (scheme.outline, _kindIcon(step.kind)),
    };
    return Tooltip(
      message: label,
      child: AnimatedContainer(
        duration: Motion.medium,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: step.status == 'pending'
              ? Colors.transparent
              : color.withValues(alpha: 0.14),
          border: Border.all(color: color, width: 2),
        ),
        child: step.status == 'running'
            ? Padding(
                padding: const EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 17, color: color),
      ),
    );
  }

  IconData _kindIcon(String kind) => switch (kind) {
    'makeup' => Icons.brush_outlined,
    'hair' => Icons.content_cut,
    _ => Icons.checkroom,
  };
}
