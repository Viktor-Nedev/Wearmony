import '../api/models.dart';
import '../l10n/app_localizations.dart';

/// Localized color name from the backend's color key and modifier.
String colorName(AppLocalizations l10n, HarmonyColor color) {
  final base = switch (color.base) {
    'black' => l10n.colorBlack,
    'white' => l10n.colorWhite,
    'beige' => l10n.colorBeige,
    'brown' => l10n.colorBrown,
    'red' => l10n.colorRed,
    'burgundy' => l10n.colorBurgundy,
    'pink' => l10n.colorPink,
    'orange' => l10n.colorOrange,
    'yellow' => l10n.colorYellow,
    'olive' => l10n.colorOlive,
    'green' => l10n.colorGreen,
    'teal' => l10n.colorTeal,
    'blue' => l10n.colorBlue,
    'navy' => l10n.colorNavy,
    'purple' => l10n.colorPurple,
    'lavender' => l10n.colorLavender,
    'magenta' => l10n.colorMagenta,
    _ => l10n.colorGray,
  };
  return switch (color.modifier) {
    'light' => l10n.colorLight(base),
    'dark' => l10n.colorDark(base),
    'muted' => l10n.colorMuted(base),
    _ => base,
  };
}

String relationName(AppLocalizations l10n, String relation) =>
    switch (relation) {
      'matched' => l10n.relationMatched,
      'near_miss' => l10n.relationNearMiss,
      'complementary' => l10n.relationComplementary,
      _ => l10n.relationContrast,
    };

/// One plain sentence per finding, built from structured fields so it is localized.
String findingSentence(AppLocalizations l10n, HarmonyFinding f) {
  final colorA = colorName(l10n, f.colors[0]);
  final colorB = colorName(l10n, f.colors[1]);
  final de = f.deltaE.toStringAsFixed(1);
  final a = f.names.first;

  if (f.scope == 'self') {
    final subject = f.subjects.first == 'hair'
        ? l10n.subjectHair
        : l10n.subjectLips;
    return switch (f.relation) {
      'matched' => l10n.selfMatched(a, colorB, subject),
      'near_miss' => l10n.selfNearMiss(a, colorA, colorB, de, subject),
      'complementary' => l10n.selfComplementary(a, colorA, colorB, subject),
      _ => l10n.selfContrast(a, colorA, colorB, subject),
    };
  }

  final b = f.names.length > 1 ? f.names[1] : '';
  return switch (f.relation) {
    'matched' => l10n.pairMatched(a, b, colorA),
    'near_miss' => l10n.pairNearMiss(a, b, colorA, colorB, de),
    'complementary' => l10n.pairComplementary(a, b, colorA, colorB),
    _ => l10n.pairContrast(a, b, colorA, colorB),
  };
}
