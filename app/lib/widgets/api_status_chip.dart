import 'package:flutter/material.dart';

import '../api/models.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';

/// Shows whether the backend is reachable and whether it runs in mock mode.
class ApiStatusChip extends StatefulWidget {
  const ApiStatusChip({super.key});

  @override
  State<ApiStatusChip> createState() => _ApiStatusChipState();
}

class _ApiStatusChipState extends State<ApiStatusChip> {
  Future<ApiHealth>? _health;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _health ??= AppScope.of(context).api.health();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<ApiHealth>(
      future: _health,
      builder: (context, snapshot) {
        final String label;
        final IconData icon;
        if (snapshot.hasError) {
          label = l10n.apiStatusOffline;
          icon = Icons.cloud_off;
        } else if (snapshot.data case final health?) {
          label = health.isMock ? l10n.apiStatusMock : l10n.apiStatusLive;
          icon = health.isMock ? Icons.science_outlined : Icons.cloud_done_outlined;
        } else {
          return const SizedBox(height: 32);
        }
        return Center(
          child: Chip(avatar: Icon(icon, size: 18), label: Text(label)),
        );
      },
    );
  }
}
