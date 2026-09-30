import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Wearmony'**
  String get appTitle;

  /// No description provided for @slogan.
  ///
  /// In en, this message translates to:
  /// **'Try it on together.'**
  String get slogan;

  /// No description provided for @landingPitch.
  ///
  /// In en, this message translates to:
  /// **'See how your group looks together before anyone buys an outfit: try-on, color harmony and a shared budget in one place.'**
  String get landingPitch;

  /// No description provided for @organizeEvent.
  ///
  /// In en, this message translates to:
  /// **'Organize an event'**
  String get organizeEvent;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCode;

  /// No description provided for @apiStatusMock.
  ///
  /// In en, this message translates to:
  /// **'API: mock mode'**
  String get apiStatusMock;

  /// No description provided for @apiStatusLive.
  ///
  /// In en, this message translates to:
  /// **'API: live'**
  String get apiStatusLive;

  /// No description provided for @apiStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'API offline'**
  String get apiStatusOffline;

  /// No description provided for @createEventTitle.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get createEventTitle;

  /// No description provided for @eventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventNameLabel;

  /// No description provided for @templateLabel.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get templateLabel;

  /// No description provided for @templateProm.
  ///
  /// In en, this message translates to:
  /// **'Prom'**
  String get templateProm;

  /// No description provided for @templateTheatre.
  ///
  /// In en, this message translates to:
  /// **'Theatre'**
  String get templateTheatre;

  /// No description provided for @templateGroup.
  ///
  /// In en, this message translates to:
  /// **'Group photo'**
  String get templateGroup;

  /// No description provided for @createEventButton.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get createEventButton;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join an event'**
  String get joinTitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event code'**
  String get joinCodeLabel;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @notConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet: saving arrives with account setup.'**
  String get notConnectedYet;

  /// No description provided for @vendorTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared look'**
  String get vendorTitle;

  /// No description provided for @vendorReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This page is read-only and the link expires.'**
  String get vendorReadOnly;

  /// No description provided for @pipelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Try-on pipeline check'**
  String get pipelineTitle;

  /// No description provided for @pipelineRunSuccess.
  ///
  /// In en, this message translates to:
  /// **'Run a successful try-on'**
  String get pipelineRunSuccess;

  /// No description provided for @pipelineRunFailure.
  ///
  /// In en, this message translates to:
  /// **'Run a failing try-on'**
  String get pipelineRunFailure;

  /// No description provided for @tryOnQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting in queue…'**
  String get tryOnQueued;

  /// No description provided for @tryOnRunning.
  ///
  /// In en, this message translates to:
  /// **'Rendering… {percent}%'**
  String tryOnRunning(int percent);

  /// No description provided for @tryOnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Render ready.'**
  String get tryOnSuccess;

  /// No description provided for @tryOnFailed.
  ///
  /// In en, this message translates to:
  /// **'Try-on failed'**
  String get tryOnFailed;

  /// No description provided for @tryOnTimeout.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long. Please try again.'**
  String get tryOnTimeout;

  /// No description provided for @failureGarmentNotApplied.
  ///
  /// In en, this message translates to:
  /// **'The outfit was not applied to the photo. This often happens when the original clothing is dark or bulky; try a photo in lighter, fitted clothing.'**
  String get failureGarmentNotApplied;

  /// No description provided for @failureGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with this render.'**
  String get failureGeneric;

  /// No description provided for @mockBadge.
  ///
  /// In en, this message translates to:
  /// **'Simulated result (mock mode, no YouCam call)'**
  String get mockBadge;

  /// No description provided for @previewDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Visual preview, not a fit guarantee.'**
  String get previewDisclaimer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bg', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
