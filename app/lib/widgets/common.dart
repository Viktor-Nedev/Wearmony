import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../util/format.dart';

/// Network image that accepts API-relative URLs and works on web without CORS setup.
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.person_outline,
  });

  final String? url;
  final BoxFit fit;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(placeholderIcon, size: 40, color: scheme.onSurfaceVariant),
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      AppScope.api(context).resolveUrl(url!),
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (context, error, stack) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

/// A round color swatch.
class ColorDot extends StatelessWidget {
  const ColorDot(this.hex, {super.key, this.size = 20});

  final String? hex;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hexColor(hex),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

/// Colored strip with an icon, for honest labels ("simulated", "demo data") and warnings.
class NoticeBar extends StatelessWidget {
  const NoticeBar(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.tone = NoticeTone.info,
  });

  final String text;
  final IconData icon;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      NoticeTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      NoticeTone.simulated => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      NoticeTone.warning => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

enum NoticeTone { info, simulated, warning }

/// Error with a retry button.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorText(context, error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs an action, shows its error in a snackbar, and returns its result (null on error).
Future<T?> runWithFeedback<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await action();
    if (success != null) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
    }
    return result;
  } catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(context, error))),
      );
    }
    return null;
  }
}

Future<bool> confirm(
  BuildContext context,
  String message, {
  String? action,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action ?? l10n.delete),
        ),
      ],
    ),
  );
  return result ?? false;
}
