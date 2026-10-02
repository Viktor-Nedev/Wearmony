import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui/effects.dart';
import '../ui/motion.dart';
import 'session_widgets.dart';

/// Focused single-task pages (create, join, consent, photo): a frosted card over the aurora.
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.maxWidth = 560,
    this.actions = const [LanguageMenu()],
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final double maxWidth;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(actions: [...actions, const SizedBox(width: 8)]),
      body: AuroraBackground(
        intensity: 0.75,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Reveal(
                  scale: 0.97,
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (icon != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: Brand.gradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(title, style: text.headlineMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: text.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A large selectable card (templates, poses) with an animated selection state.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.leading,
  });

  final bool selected;
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Hoverable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.curve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: text.bodySmall),
                  ],
                ],
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: Motion.medium,
              curve: Curves.elasticOut,
              child: Icon(Icons.check_circle, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
