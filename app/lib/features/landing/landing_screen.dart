import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/models.dart';
import '../../app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/harmony_visuals.dart';
import '../../ui/motion.dart';
import '../../util/format.dart';
import '../../widgets/common.dart';
import '../../widgets/session_widgets.dart';
import 'how_it_works.dart';
import 'landing_sections.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Future<List<EventInfo>>? _events;
  EventTemplate? _openingDemo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _events ??= AppScope.api(context).myEvents();
  }

  Future<void> _openDemo(EventTemplate template) async {
    setState(() => _openingDemo = template);
    final event = await runWithFeedback(
      context,
      () => AppScope.api(context).createDemo(template: template),
    );
    if (!mounted) return;
    setState(() => _openingDemo = null);
    if (event != null) context.go('/e/${event.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BrandMark(size: 24, animated: true),
        actions: const [LanguageMenu(), SizedBox(width: 8)],
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final hero = _Hero(
                wide: wide,
                openingDemo: _openingDemo,
                onOpenDemo: _openDemo,
              );
              const showcase = Reveal(
                delay: Duration(milliseconds: 280),
                scale: 0.94,
                child: TiltOnHover(child: HarmonyShowcase()),
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: wide ? 56 : 8),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 11, child: hero),
                              const SizedBox(width: 56),
                              const Expanded(flex: 9, child: showcase),
                            ],
                          )
                        else ...[
                          hero,
                          const SizedBox(height: 32),
                          showcase,
                        ],
                        _YourEvents(events: _events),
                        SizedBox(height: wide ? 88 : 56),
                        HowItWorks(wide: wide),
                        SizedBox(height: wide ? 80 : 52),
                        _Features(wide: wide),
                        SizedBox(height: wide ? 88 : 56),
                        PoweredByYouCam(wide: wide),
                        SizedBox(height: wide ? 88 : 56),
                        PrivacySection(wide: wide),
                        SizedBox(height: wide ? 88 : 56),
                        const FaqSection(),
                        SizedBox(height: wide ? 72 : 48),
                        RevealOnScroll(
                          child: SiteFooter(onOpenDemo: _openDemo),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.wide,
    required this.openingDemo,
    required this.onOpenDemo,
  });

  final bool wide;

  /// The demo being opened, if any.
  final EventTemplate? openingDemo;
  final ValueChanged<EventTemplate> onOpenDemo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = wide ? TextAlign.start : TextAlign.center;
    final config = AppScope.of(context).config;

    final buttons = [
      BrandButton(
        label: l10n.organizeEvent,
        icon: Icons.event_outlined,
        onPressed: () => context.push('/create'),
        expand: !wide,
        attention: true,
      ),
      OutlinedButton.icon(
        onPressed: () => context.push('/join'),
        icon: const Icon(Icons.group_add_outlined),
        label: Text(l10n.joinWithCode),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
      ),
    ];

    return Column(
      crossAxisAlignment: align,
      children: [
        Reveal(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Brand.berry),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.heroEyebrow, style: text.labelLarge)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 80),
          child: GradientText(
            l10n.slogan,
            animated: true,
            textAlign: textAlign,
            style: (wide ? text.displayLarge : text.displayMedium)?.copyWith(
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: const Duration(milliseconds: 160),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              l10n.landingPitch,
              textAlign: textAlign,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Reveal(
          delay: const Duration(milliseconds: 240),
          child: wide
              ? Row(
                  children: [
                    SizedBox(width: 260, child: buttons[0]),
                    const SizedBox(width: 12),
                    buttons[1],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: 12),
                    buttons[1],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Reveal(
          delay: const Duration(milliseconds: 320),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Wrap(
                alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                children: [
                  for (final (template, icon, label) in [
                    (
                      EventTemplate.prom,
                      Icons.auto_awesome_outlined,
                      l10n.openDemo,
                    ),
                    (
                      EventTemplate.theatre,
                      Icons.theater_comedy_outlined,
                      l10n.openTheatreDemo,
                    ),
                  ])
                    TextButton.icon(
                      onPressed: openingDemo != null
                          ? null
                          : () => onOpenDemo(template),
                      icon: openingDemo == template
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(icon),
                      label: Text(label),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.demoHint,
                  style: text.bodySmall,
                  textAlign: textAlign,
                ),
              ),
            ],
          ),
        ),
        if (config?.isMock ?? false) ...[
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 400),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: NoticeBar(
                l10n.mockBanner,
                icon: Icons.science_outlined,
                tone: NoticeTone.simulated,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Features extends StatelessWidget {
  const _Features({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final features = [
      (Icons.checkroom_outlined, l10n.featureTryOnTitle, l10n.featureTryOnBody),
      (
        Icons.palette_outlined,
        l10n.featureHarmonyTitle,
        l10n.featureHarmonyBody,
      ),
      (Icons.auto_fix_high, l10n.featureFixTitle, l10n.featureFixBody),
      (
        Icons.photo_camera_front_outlined,
        l10n.featureFrameTitle,
        l10n.featureFrameBody,
      ),
      (Icons.savings_outlined, l10n.featureBudgetTitle, l10n.featureBudgetBody),
      (
        Icons.accessible_forward,
        l10n.featureInclusiveTitle,
        l10n.featureInclusiveBody,
      ),
      (Icons.how_to_vote_outlined, l10n.featurePollTitle, l10n.featurePollBody),
      (
        Icons.visibility_outlined,
        l10n.featureVisionTitle,
        l10n.featureVisionBody,
      ),
      (
        Icons.auto_awesome_outlined,
        l10n.featureShowcaseTitle,
        l10n.featureShowcaseBody,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : (constraints.maxWidth >= 560 ? 2 : 1);
        final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final (index, (icon, title, body)) in features.indexed)
              SizedBox(
                width: width,
                child: RevealOnScroll(
                  delay: Motion.stagger(index, stepMs: 90),
                  child: Hoverable(
                    child: HoverSpotlight(
                      radius: 22,
                      child: _FeatureCard(icon: icon, title: title, body: body),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: Brand.gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(title, style: text.titleLarge?.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            body,
            style: text.bodyMedium?.copyWith(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _YourEvents extends StatelessWidget {
  const _YourEvents({required this.events});

  final Future<List<EventInfo>>? events;

  IconData _icon(EventTemplate template) => switch (template) {
    EventTemplate.prom => Icons.school_outlined,
    EventTemplate.theatre => Icons.theater_comedy_outlined,
    EventTemplate.group => Icons.groups_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<List<EventInfo>>(
      future: events,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <EventInfo>[];
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevealOnScroll(
                child: Text(l10n.yourEvents, style: text.headlineSmall),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final (index, event) in list.indexed)
                    RevealOnScroll(
                      delay: Motion.stagger(index),
                      child: SizedBox(
                        width: 360,
                        child: Hoverable(
                          onTap: () => context.push('/e/${event.id}'),
                          child: GlassCard(
                            padding: const EdgeInsets.all(18),
                            radius: 22,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: event.demo
                                        ? null
                                        : Brand.gradient,
                                    color: event.demo
                                        ? Brand.champagne.withValues(
                                            alpha: 0.35,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    event.demo
                                        ? Icons.auto_awesome
                                        : _icon(event.template),
                                    color: event.demo
                                        ? Brand.plum
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.name,
                                        style: text.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          templateName(l10n, event.template),
                                          if (event.eventDate != null)
                                            countdownLabel(
                                              l10n,
                                              event.eventDate!,
                                            ),
                                          if (event.isOrganizer)
                                            l10n.organizerRole,
                                          if (event.isParticipant)
                                            l10n.participantRole,
                                        ].join(' · '),
                                        style: text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
