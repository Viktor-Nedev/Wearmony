import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/app_localizations.dart';

String formatMoney(BuildContext context, double amount, String currency) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.simpleCurrency(
    locale: locale,
    name: currency,
  ).format(amount);
}

String formatDate(BuildContext context, DateTime date) => DateFormat.yMMMd(
  Localizations.localeOf(context).toLanguageTag(),
).add_Hm().format(date.toLocal());

/// The day of an event, e.g. "23 May 2027".
String formatEventDay(BuildContext context, DateTime day) => DateFormat.yMMMd(
  Localizations.localeOf(context).toLanguageTag(),
).format(day);

/// Whole calendar days from today until [day]; negative once it has passed.
int daysUntil(DateTime day, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
}

/// "just now", "5 min ago", "3 h ago", "yesterday", "4 days ago".
String timeAgo(AppLocalizations l10n, DateTime at, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(at);
  if (elapsed.inMinutes < 1) return l10n.timeJustNow;
  if (elapsed.inHours < 1) return l10n.timeMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.timeHours(elapsed.inHours);
  return l10n.timeDays(elapsed.inDays);
}

/// "in 12 days", "Today" or "3 days ago".
String countdownLabel(AppLocalizations l10n, DateTime day, {DateTime? now}) {
  final days = daysUntil(day, now: now);
  if (days == 0) return l10n.countdownToday;
  return days > 0 ? l10n.countdownDays(days) : l10n.countdownPast(-days);
}

Color hexColor(String? hex, {Color fallback = const Color(0xFF9E9E9E)}) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return fallback;
  }
  return Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
}

/// A readable message for any error, using the API's stable codes where possible.
String errorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is ApiException) {
    switch (error.code) {
      case 'event_not_found':
        return l10n.codeNotFound;
      case 'link_expired':
        return l10n.vendorExpired;
      case 'link_not_found':
        return l10n.vendorNotFound;
      case 'lock_after_event':
        return l10n.errorLockAfterEvent;
      case 'photo_rejected':
        final issues =
            (error.details is Map ? (error.details as Map)['issues'] : null)
                as List?;
        final texts = (issues ?? const [])
            .whereType<String>()
            .map((i) => photoIssueText(l10n, i))
            .toList();
        return texts.isEmpty ? error.message : texts.join('\n');
      case 'error':
        return l10n.errorGeneric;
    }
    return error.message;
  }
  return l10n.errorOffline;
}

String templateName(AppLocalizations l10n, EventTemplate template) =>
    switch (template) {
      EventTemplate.prom => l10n.templateProm,
      EventTemplate.theatre => l10n.templateTheatre,
      EventTemplate.group => l10n.templateGroup,
    };

String categoryName(AppLocalizations l10n, GarmentCategory category) =>
    switch (category) {
      GarmentCategory.fullBody => l10n.categoryFullBody,
      GarmentCategory.upperBody => l10n.categoryUpperBody,
      GarmentCategory.lowerBody => l10n.categoryLowerBody,
      GarmentCategory.outer => l10n.categoryOuter,
    };

String photoIssueText(AppLocalizations l10n, String issue) => switch (issue) {
  'too_small' => l10n.issue_too_small,
  'unusual_ratio' => l10n.issue_unusual_ratio,
  'too_dark' => l10n.issue_too_dark,
  'too_bright' => l10n.issue_too_bright,
  'low_contrast' => l10n.issue_low_contrast,
  'dark_clothing' => l10n.warning_dark_clothing,
  _ => issue,
};

String failureText(AppLocalizations l10n, RenderFailure failure) =>
    switch (failure.reason) {
      'garment_not_applied' => l10n.failure_garment_not_applied,
      'pose_not_supported' => l10n.failure_pose_not_supported,
      'face_not_found' => l10n.failure_face_not_found,
      'multiple_people' => l10n.failure_multiple_people,
      'image_invalid' => l10n.failure_image_invalid,
      'content_rejected' => l10n.failure_content_rejected,
      'budget_exhausted' => l10n.failure_budget_exhausted,
      'timeout' => l10n.failure_timeout,
      _ => l10n.failure_provider_error,
    };

String kindName(AppLocalizations l10n, String? kind) => switch (kind) {
  'makeup' => l10n.kindMakeup,
  'hair' => l10n.kindHair,
  _ => l10n.kindApparel,
};
