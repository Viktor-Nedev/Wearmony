import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../ui/effects.dart';
import '../../ui/figure.dart';
import '../../widgets/form_scaffold.dart';

/// Shown for links that do not match any page.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormScaffold(
      title: l10n.notFoundTitle,
      subtitle: l10n.notFoundBody,
      icon: Icons.explore_off_outlined,
      children: [
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Figure(clothing: Brand.berry, hair: Color(0xFF3B2A20), width: 72),
              SizedBox(width: 14),
              Figure(
                clothing: Brand.champagne,
                hair: Color(0xFF6B4A2E),
                skin: Color(0xFFB07A55),
                seated: true,
                width: 72,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BrandButton(
          label: l10n.goHome,
          icon: Icons.home_outlined,
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }
}
