// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wearmony';

  @override
  String get slogan => 'Try it on together.';

  @override
  String get landingPitch =>
      'See how your group looks together before anyone buys an outfit: try-on, color harmony and a shared budget in one place.';

  @override
  String get organizeEvent => 'Organize an event';

  @override
  String get joinWithCode => 'Join with a code';

  @override
  String get apiStatusMock => 'API: mock mode';

  @override
  String get apiStatusLive => 'API: live';

  @override
  String get apiStatusOffline => 'API offline';

  @override
  String get createEventTitle => 'New event';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get templateLabel => 'Template';

  @override
  String get templateProm => 'Prom';

  @override
  String get templateTheatre => 'Theatre';

  @override
  String get templateGroup => 'Group photo';

  @override
  String get createEventButton => 'Create event';

  @override
  String get joinTitle => 'Join an event';

  @override
  String get joinCodeLabel => 'Event code';

  @override
  String get joinButton => 'Join';

  @override
  String get notConnectedYet =>
      'Not connected yet: saving arrives with account setup.';

  @override
  String get vendorTitle => 'Shared look';

  @override
  String get vendorReadOnly => 'This page is read-only and the link expires.';

  @override
  String get pipelineTitle => 'Try-on pipeline check';

  @override
  String get pipelineRunSuccess => 'Run a successful try-on';

  @override
  String get pipelineRunFailure => 'Run a failing try-on';

  @override
  String get tryOnQueued => 'Waiting in queue…';

  @override
  String tryOnRunning(int percent) {
    return 'Rendering… $percent%';
  }

  @override
  String get tryOnSuccess => 'Render ready.';

  @override
  String get tryOnFailed => 'Try-on failed';

  @override
  String get tryOnTimeout => 'This is taking too long. Please try again.';

  @override
  String get failureGarmentNotApplied =>
      'The outfit was not applied to the photo. This often happens when the original clothing is dark or bulky; try a photo in lighter, fitted clothing.';

  @override
  String get failureGeneric => 'Something went wrong with this render.';

  @override
  String get mockBadge => 'Simulated result (mock mode, no YouCam call)';

  @override
  String get previewDisclaimer => 'Visual preview, not a fit guarantee.';
}
