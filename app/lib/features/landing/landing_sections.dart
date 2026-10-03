import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/motion.dart';
import '../../widgets/session_widgets.dart';

/// How YouCam builds each look: the photo, then outfit, lip color and hair
/// color as a chain, with a light that runs along it.
class PoweredByYouCam extends StatelessWidget {
  const PoweredByYouCam({super.key, required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final steps = [
      (Icons.portrait_outlined, l10n.chainPhotoTitle, l10n.chainPhotoBody),
      (Icons.checkroom, 'AI Clothes', l10n.chainClothesBody),
      (Icons.brush_outlined, 'AI Makeup', l10n.chainMakeupBody),
      (Icons.content_cut, 'AI Hair Color', l10n.chainHairBody),
    ];
    final facts = [
      (Icons.cached_rounded, l10n.factCache),
      (Icons.account_balance_wallet_outlined, l10n.factLedger),
      (Icons.label_outline, l10n.factLabels),
    ];

    return RevealOnScroll(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 44 : 22,
          vertical: wide ? 44 : 30,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A0F22), Brand.plum, Color(0xFF8E3361)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Brand.plum.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                l10n.poweredByEyebrow,
                style: text.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.poweredByTitle,
              style: text.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                l10n.poweredByBody,
                style: text.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: wide ? 32 : 24),
            _Chain(steps: steps, wide: wide),
            SizedBox(height: wide ? 30 : 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (index, (icon, label)) in facts.indexed)
                  RevealOnScroll(
                    delay: Motion.stagger(index + 2, stepMs: 90),
                    offset: const Offset(0, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: Brand.champagne),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              style: text.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chain extends StatefulWidget {
  const _Chain({required this.steps, required this.wide});

  final List<(IconData, String, String)> steps;
  final bool wide;

  @override
  State<_Chain> createState() => _ChainState();
}

class _ChainState extends State<_Chain>
    with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 3600);

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    Widget node(int index) {
      final (icon, title, body) = steps[index];
      return RevealOnScroll(
        delay: Motion.stagger(index, stepMs: 110),
        offset: const Offset(0, 16),
        child: _ChainNode(
          icon: icon,
          title: title,
          body: body,
          index: index,
          count: steps.length,
          loop: loop,
          vertical: widget.wide,
          last: index == steps.length - 1,
        ),
      );
    }

    if (!widget.wide) {
      return Column(children: [for (var i = 0; i < steps.length; i++) node(i)]);
    }
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: loop == null
                  ? CustomPaint(
                      painter: _ChainPainter(t: null, count: steps.length),
                    )
                  : AnimatedBuilder(
                      animation: loop!,
                      builder: (context, _) => CustomPaint(
                        painter: _ChainPainter(
                          t: loop!.value,
                          count: steps.length,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: node(i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One step of the chain. Its badge lights up when the travelling light reaches it.
/// Wide screens stack the badge over the text; phones put them side by side with
/// a short line down to the next step.
class _ChainNode extends StatelessWidget {
  const _ChainNode({
    required this.icon,
    required this.title,
    required this.body,
    required this.index,
    required this.count,
    required this.loop,
    required this.vertical,
    required this.last,
  });

  final IconData icon;
  final String title;
  final String body;
  final int index;
  final int count;
  final Animation<double>? loop;
  final bool vertical;
  final bool last;

  static const badgeSize = 58.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget badge(double glow) => Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          Colors.white.withValues(alpha: 0.12),
          Colors.white,
          glow,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Brand.champagne.withValues(alpha: 0.55 * glow),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Color.lerp(Colors.white, Brand.plum, glow),
        size: 26,
      ),
    );
    final animation = loop;
    final lit = animation == null
        ? badge(0)
        : AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              // The light passes this step at index / (count - 1) of 80% of the loop.
              final at = index / (count - 1) * 0.8;
              final distance = (animation.value - at).abs();
              final glow = (1 - distance / 0.12).clamp(0.0, 1.0);
              return badge(Curves.easeOut.transform(glow));
            },
          );
    final align = vertical ? TextAlign.center : TextAlign.start;
    final words = Column(
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: text.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: align,
          style: text.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            height: 1.45,
          ),
        ),
      ],
    );
    if (vertical) {
      return Column(children: [lit, const SizedBox(height: 14), words]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              lit,
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: last ? 0 : 22),
              child: words,
            ),
          ),
        ],
      ),
    );
  }
}

/// The line between the badges on wide screens, and the light running along it
/// for the first 80% of each loop.
class _ChainPainter extends CustomPainter {
  _ChainPainter({required this.t, required this.count});

  final double? t;
  final int count;

  Offset _node(Size size, int i) {
    final column = size.width / count;
    return Offset(column * (i + 0.5), _ChainNode.badgeSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final from = _node(size, 0);
    final to = _node(size, count - 1);
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final progress = t;
    if (progress == null || progress > 0.8) return;
    final head = Offset.lerp(from, to, progress / 0.8)!;
    final tail = Offset.lerp(from, to, math.max(0, progress / 0.8 - 0.18))!;
    if ((head - tail).distance > 1) {
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [Brand.champagne.withValues(alpha: 0), Brand.champagne],
          ).createShader(Rect.fromPoints(tail, head).inflate(2)),
      );
    }
    canvas.drawCircle(
      head,
      5,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_ChainPainter old) => old.t != t || old.count != count;
}

/// Four promises about photos and data.
class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key, required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final items = [
      (
        Icons.lock_outline_rounded,
        l10n.privacyPrivateTitle,
        l10n.privacyPrivateBody,
      ),
      (
        Icons.delete_outline_rounded,
        l10n.privacyDeleteTitle,
        l10n.privacyDeleteBody,
      ),
      (Icons.timer_outlined, l10n.privacyLinksTitle, l10n.privacyLinksBody),
      (
        Icons.verified_user_outlined,
        l10n.privacyConsentTitle,
        l10n.privacyConsentBody,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RevealOnScroll(
          child: Text(
            l10n.privacyTitle,
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        RevealOnScroll(
          delay: const Duration(milliseconds: 80),
          child: Text(
            l10n.privacySubtitle,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : (constraints.maxWidth >= 520 ? 2 : 1);
            final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final (index, (icon, title, body)) in items.indexed)
                  SizedBox(
                    width: width,
                    child: RevealOnScroll(
                      delay: Motion.stagger(index, stepMs: 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: scheme.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: text.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Short answers to the questions people ask first.
class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final items = [
      (l10n.faqSeatedQ, l10n.faqSeatedA),
      (l10n.faqNearMissQ, l10n.faqNearMissA),
      (l10n.faqExactQ, l10n.faqExactA),
      (l10n.faqPhotoQ, l10n.faqPhotoA),
      (l10n.faqAccountQ, l10n.faqAccountA),
      (l10n.faqUnitsQ, l10n.faqUnitsA),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RevealOnScroll(
              child: Text(
                l10n.faqTitle,
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
            ),
            const SizedBox(height: 20),
            for (final (index, (question, answer)) in items.indexed) ...[
              if (index > 0) const SizedBox(height: 10),
              RevealOnScroll(
                delay: Motion.stagger(index, stepMs: 70),
                child: _FaqItem(question: question, answer: answer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final duration = Motion.reduced(context) ? Duration.zero : Motion.medium;
    final answer = _open
        ? Padding(
            padding: const EdgeInsets.only(top: 10, right: 30),
            child: Text(
              widget.answer,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          )
        : const SizedBox(width: double.infinity);
    return Hoverable(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedContainer(
        duration: duration,
        curve: Motion.curve,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _open
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Semantics(
          button: true,
          expanded: _open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.question, style: text.titleMedium),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: duration,
                      curve: Motion.curve,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                // AnimatedSize must not run with a zero duration (reduced motion).
                if (duration == Duration.zero)
                  answer
                else
                  AnimatedSize(
                    duration: duration,
                    curve: Motion.emphasized,
                    alignment: Alignment.topCenter,
                    child: answer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page footer: the brand, ways in, the inclusion results and the API status.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.onOpenDemo});

  final ValueChanged<EventTemplate> onOpenDemo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget link(String label, IconData icon, VoidCallback onTap) =>
        TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
    final columns = [
      (
        l10n.footerStart,
        [
          link(
            l10n.organizeEvent,
            Icons.event_outlined,
            () => context.push('/create'),
          ),
          link(
            l10n.joinWithCode,
            Icons.group_add_outlined,
            () => context.push('/join'),
          ),
        ],
      ),
      (
        l10n.footerDemos,
        [
          link(
            l10n.openDemo,
            Icons.auto_awesome_outlined,
            () => onOpenDemo(EventTemplate.prom),
          ),
          link(
            l10n.openTheatreDemo,
            Icons.theater_comedy_outlined,
            () => onOpenDemo(EventTemplate.theatre),
          ),
        ],
      ),
      (
        l10n.footerLearn,
        [
          link(
            l10n.inclusionLink,
            Icons.accessible_forward,
            () => context.push('/inclusion'),
          ),
        ],
      ),
    ];
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final brand = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 26),
                  const SizedBox(height: 10),
                  Text(
                    l10n.slogan,
                    style: text.titleMedium?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.footerTagline, style: text.bodySmall),
                ],
              );
              final lists = [
                for (final (title, links) in columns)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          title.toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ...links,
                    ],
                  ),
              ];
              if (constraints.maxWidth >= 860) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: brand),
                    for (final list in lists) Expanded(flex: 3, child: list),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  const SizedBox(height: 18),
                  Wrap(spacing: 28, runSpacing: 14, children: lists),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(l10n.footerHackathon, style: text.bodySmall),
              const ApiStatusChip(),
            ],
          ),
        ],
      ),
    );
  }
}
