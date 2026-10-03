import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../api/models.dart';
import '../../app_scope.dart';

/// Loads the group board and refreshes it while the widget is on screen,
/// so renders that finish elsewhere show up without a manual reload.
/// Also notices when the last near-miss warning disappears, to celebrate it.
mixin BoardLoader<T extends StatefulWidget> on State<T> {
  Board? board;
  Object? boardError;

  /// True for a few seconds after the group's last near-miss clash was fixed.
  bool clashFixed = false;

  Timer? _timer;
  Timer? _celebration;
  int? _lastWarnings;

  String get boardEventId;

  Duration get refreshEvery => const Duration(seconds: 5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (board == null && boardError == null) {
      loadBoard();
      _timer = Timer.periodic(refreshEvery, (_) => loadBoard(quiet: true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _celebration?.cancel();
    super.dispose();
  }

  Future<void> loadBoard({bool quiet = false}) async {
    try {
      final result = await AppScope.api(context).board(boardEventId);
      if (!mounted) return;
      final warnings = result.harmony.warnings.length;
      final fixed = (_lastWarnings ?? 0) > 0 && warnings == 0;
      _lastWarnings = warnings;
      setState(() {
        board = result;
        boardError = null;
        if (fixed) clashFixed = true;
      });
      if (fixed) {
        _celebration?.cancel();
        _celebration = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => clashFixed = false);
        });
      }
    } catch (error) {
      if (mounted && (!quiet || board == null)) {
        setState(() => boardError = error);
      }
    }
  }
}
