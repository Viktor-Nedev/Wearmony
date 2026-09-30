enum TryOnKind { apparel, makeup, hair }

enum TaskState { queued, running, success, failed }

class ApiHealth {
  const ApiHealth({required this.ok, required this.youcamMode});

  factory ApiHealth.fromJson(Map<String, dynamic> json) => ApiHealth(
        ok: json['ok'] == true,
        youcamMode: json['youcamMode'] as String? ?? 'unknown',
      );

  final bool ok;
  final String youcamMode;

  bool get isMock => youcamMode == 'mock';
}

class TryOnStatus {
  const TryOnStatus({
    required this.taskId,
    required this.state,
    required this.progress,
    required this.mock,
    this.resultUrl,
    this.failureReason,
    this.failureMessage,
  });

  factory TryOnStatus.fromJson(Map<String, dynamic> json) {
    final failure = json['failure'] as Map<String, dynamic>?;
    return TryOnStatus(
      taskId: json['taskId'] as String,
      state: TaskState.values.byName(json['state'] as String),
      progress: (json['progress'] as num? ?? 0).toDouble(),
      mock: json['mock'] == true,
      resultUrl: json['resultUrl'] as String?,
      failureReason: failure?['reason'] as String?,
      failureMessage: failure?['message'] as String?,
    );
  }

  final String taskId;
  final TaskState state;

  /// 0..1, best effort.
  final double progress;

  /// True when no real API call was made. The UI must label these results.
  final bool mock;
  final String? resultUrl;
  final String? failureReason;
  final String? failureMessage;

  bool get isFinal => state == TaskState.success || state == TaskState.failed;
}
