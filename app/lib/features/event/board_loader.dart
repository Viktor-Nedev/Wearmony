import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../api/models.dart';
import '../../app_scope.dart';

/// Loads the group board and refreshes it while the widget is on screen,
/// so renders that finish elsewhere show up without a manual reload.
mixin BoardLoader<T extends StatefulWidget> on State<T> {
  Board? board;
  Object? boardError;
  Timer? _timer;

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
    super.dispose();
  }

  Future<void> loadBoard({bool quiet = false}) async {
    try {
      final result = await AppScope.api(context).board(boardEventId);
      if (mounted) {
        setState(() {
          board = result;
          boardError = null;
        });
      }
    } catch (error) {
      if (mounted && (!quiet || board == null)) {
        setState(() => boardError = error);
      }
    }
  }
}
