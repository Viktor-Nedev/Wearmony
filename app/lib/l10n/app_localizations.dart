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

  /// No description provided for @openDemo.
  ///
  /// In en, this message translates to:
  /// **'Prom demo'**
  String get openDemo;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Ready-made events with illustrated people: a prom and a school play. No photos needed.'**
  String get demoHint;

  /// No description provided for @yourEvents.
  ///
  /// In en, this message translates to:
  /// **'Your events'**
  String get yourEvents;

  /// No description provided for @organizerRole.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizerRole;

  /// No description provided for @participantRole.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get participantRole;

  /// No description provided for @inclusionLink.
  ///
  /// In en, this message translates to:
  /// **'Inclusion results: standing vs seated'**
  String get inclusionLink;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @apiStatusMock.
  ///
  /// In en, this message translates to:
  /// **'Try-on: simulated (mock mode)'**
  String get apiStatusMock;

  /// No description provided for @apiStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Try-on: live YouCam API'**
  String get apiStatusLive;

  /// No description provided for @apiStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Wearmony'**
  String get apiStatusOffline;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Wearmony. Check your connection and try again.'**
  String get errorOffline;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInExplain.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email to create or join events.'**
  String get signInExplain;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get checkEmail;

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
  /// **'Theatre cast'**
  String get templateTheatre;

  /// No description provided for @templateGroup.
  ///
  /// In en, this message translates to:
  /// **'Group photo'**
  String get templateGroup;

  /// No description provided for @templatePromHint.
  ///
  /// In en, this message translates to:
  /// **'Couples and friends coordinating for the prom.'**
  String get templatePromHint;

  /// No description provided for @templateTheatreHint.
  ///
  /// In en, this message translates to:
  /// **'A cast trying costumes together.'**
  String get templateTheatreHint;

  /// No description provided for @templateGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Weddings, family photos, any group.'**
  String get templateGroupHint;

  /// No description provided for @budgetPerPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget per person (optional)'**
  String get budgetPerPersonLabel;

  /// No description provided for @budgetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total budget (optional)'**
  String get budgetTotalLabel;

  /// No description provided for @amountsInEuro.
  ///
  /// In en, this message translates to:
  /// **'Amounts in euro.'**
  String get amountsInEuro;

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

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name, as the group will see it'**
  String get yourNameLabel;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @joiningEvent.
  ///
  /// In en, this message translates to:
  /// **'You are joining {name}.'**
  String joiningEvent(Object name);

  /// No description provided for @codeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No event uses this code.'**
  String get codeNotFound;

  /// No description provided for @tabBoard.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get tabBoard;

  /// No description provided for @tabMyLook.
  ///
  /// In en, this message translates to:
  /// **'My look'**
  String get tabMyLook;

  /// No description provided for @tabTogether.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get tabTogether;

  /// No description provided for @tabCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get tabCatalogue;

  /// No description provided for @tabHarmony.
  ///
  /// In en, this message translates to:
  /// **'Harmony'**
  String get tabHarmony;

  /// No description provided for @tabInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get tabInvite;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo event: the people and renders are illustrations, not real photos.'**
  String get demoBanner;

  /// No description provided for @mockBanner.
  ///
  /// In en, this message translates to:
  /// **'Mock mode: try-on results are simulated, no YouCam calls are made.'**
  String get mockBanner;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you add a photo'**
  String get consentTitle;

  /// No description provided for @consentAdult.
  ///
  /// In en, this message translates to:
  /// **'I am 18 or older.'**
  String get consentAdult;

  /// No description provided for @consentPrivate.
  ///
  /// In en, this message translates to:
  /// **'My photo is visible only to people in this event and to vendors I choose to share it with.'**
  String get consentPrivate;

  /// No description provided for @consentDelete.
  ///
  /// In en, this message translates to:
  /// **'I can delete my photo and every render at any time.'**
  String get consentDelete;

  /// No description provided for @consentPreview.
  ///
  /// In en, this message translates to:
  /// **'Try-on is a visual preview, not a fit guarantee.'**
  String get consentPreview;

  /// No description provided for @consentButton.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get consentButton;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get photoTitle;

  /// No description provided for @photoTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'For the best result'**
  String get photoTipsTitle;

  /// No description provided for @photoTipLight.
  ///
  /// In en, this message translates to:
  /// **'Even, bright light.'**
  String get photoTipLight;

  /// No description provided for @photoTipFrame.
  ///
  /// In en, this message translates to:
  /// **'Face and shoulders fully visible; include as much of your outfit area as you can.'**
  String get photoTipFrame;

  /// No description provided for @photoTipAlone.
  ///
  /// In en, this message translates to:
  /// **'Only you in the photo.'**
  String get photoTipAlone;

  /// No description provided for @photoTipClothes.
  ///
  /// In en, this message translates to:
  /// **'Lighter, fitted clothing works better than dark or bulky clothes.'**
  String get photoTipClothes;

  /// No description provided for @poseQuestion.
  ///
  /// In en, this message translates to:
  /// **'In this photo I am'**
  String get poseQuestion;

  /// No description provided for @poseStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get poseStanding;

  /// No description provided for @poseSeated.
  ///
  /// In en, this message translates to:
  /// **'Seated'**
  String get poseSeated;

  /// No description provided for @poseSeatedNote.
  ///
  /// In en, this message translates to:
  /// **'Seated photos are welcome. If a full-length outfit does not apply, Wearmony retries with upper-body framing automatically.'**
  String get poseSeatedNote;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @checkingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Checking your photo…'**
  String get checkingPhoto;

  /// No description provided for @photoReady.
  ///
  /// In en, this message translates to:
  /// **'Your photo is ready.'**
  String get photoReady;

  /// No description provided for @replacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get replacePhoto;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @photoNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next: pick your look'**
  String get photoNextStep;

  /// No description provided for @issue_too_small.
  ///
  /// In en, this message translates to:
  /// **'The photo is too small. Use a larger, sharper photo.'**
  String get issue_too_small;

  /// No description provided for @issue_unusual_ratio.
  ///
  /// In en, this message translates to:
  /// **'The photo is very tall or very wide. Use a normal portrait photo.'**
  String get issue_unusual_ratio;

  /// No description provided for @issue_too_dark.
  ///
  /// In en, this message translates to:
  /// **'The photo is quite dark; try brighter light.'**
  String get issue_too_dark;

  /// No description provided for @issue_too_bright.
  ///
  /// In en, this message translates to:
  /// **'The photo is very bright; try softer light.'**
  String get issue_too_bright;

  /// No description provided for @issue_low_contrast.
  ///
  /// In en, this message translates to:
  /// **'The photo looks flat or washed out.'**
  String get issue_low_contrast;

  /// No description provided for @warning_dark_clothing.
  ///
  /// In en, this message translates to:
  /// **'Dark clothing on the photo can stop the outfit from applying. A photo in lighter clothing works better.'**
  String get warning_dark_clothing;

  /// No description provided for @sectionOutfit.
  ///
  /// In en, this message translates to:
  /// **'Outfit'**
  String get sectionOutfit;

  /// No description provided for @sectionMakeup.
  ///
  /// In en, this message translates to:
  /// **'Lip color'**
  String get sectionMakeup;

  /// No description provided for @sectionHair.
  ///
  /// In en, this message translates to:
  /// **'Hair color'**
  String get sectionHair;

  /// No description provided for @catalogueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The organizer has not added items yet.'**
  String get catalogueEmpty;

  /// No description provided for @lookTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String lookTotal(Object amount);

  /// No description provided for @tryOnButton.
  ///
  /// In en, this message translates to:
  /// **'Try it on'**
  String get tryOnButton;

  /// No description provided for @kindApparel.
  ///
  /// In en, this message translates to:
  /// **'outfit'**
  String get kindApparel;

  /// No description provided for @kindMakeup.
  ///
  /// In en, this message translates to:
  /// **'lip color'**
  String get kindMakeup;

  /// No description provided for @kindHair.
  ///
  /// In en, this message translates to:
  /// **'hair color'**
  String get kindHair;

  /// No description provided for @renderRunning.
  ///
  /// In en, this message translates to:
  /// **'Trying on the {kind}…'**
  String renderRunning(Object kind);

  /// No description provided for @renderIdle.
  ///
  /// In en, this message translates to:
  /// **'Press \"Try it on\" to see this look on your photo.'**
  String get renderIdle;

  /// No description provided for @renderNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add your photo to try looks on.'**
  String get renderNoPhoto;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add my photo'**
  String get addPhoto;

  /// No description provided for @renderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick an outfit, a lip color or a hair color.'**
  String get renderEmpty;

  /// No description provided for @renderFailed.
  ///
  /// In en, this message translates to:
  /// **'Try-on did not work'**
  String get renderFailed;

  /// No description provided for @mockBadge.
  ///
  /// In en, this message translates to:
  /// **'Simulated result (mock mode, no YouCam call)'**
  String get mockBadge;

  /// No description provided for @demoRenderBadge.
  ///
  /// In en, this message translates to:
  /// **'Illustration (demo data), not a real render'**
  String get demoRenderBadge;

  /// No description provided for @previewDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Visual preview, not a fit guarantee.'**
  String get previewDisclaimer;

  /// No description provided for @checkNotApplied.
  ///
  /// In en, this message translates to:
  /// **'The outfit may not have been applied to this photo. A photo in lighter, fitted clothing usually helps.'**
  String get checkNotApplied;

  /// No description provided for @checkDrift.
  ///
  /// In en, this message translates to:
  /// **'Check this render: its colors differ from the catalogue photo.'**
  String get checkDrift;

  /// No description provided for @failure_garment_not_applied.
  ///
  /// In en, this message translates to:
  /// **'The outfit was not applied to the photo. This often happens when the clothing on the photo is dark or bulky; try a photo in lighter, fitted clothing.'**
  String get failure_garment_not_applied;

  /// No description provided for @failure_pose_not_supported.
  ///
  /// In en, this message translates to:
  /// **'The try-on engine could not read the pose in this photo. Use a photo where your shoulders and upper body are clearly visible.'**
  String get failure_pose_not_supported;

  /// No description provided for @failure_face_not_found.
  ///
  /// In en, this message translates to:
  /// **'No face was found. Use a photo with your face fully visible, facing the camera.'**
  String get failure_face_not_found;

  /// No description provided for @failure_multiple_people.
  ///
  /// In en, this message translates to:
  /// **'More than one person is in the photo. Use a photo of just you.'**
  String get failure_multiple_people;

  /// No description provided for @failure_image_invalid.
  ///
  /// In en, this message translates to:
  /// **'This photo or item image cannot be used. Try a different one.'**
  String get failure_image_invalid;

  /// No description provided for @failure_content_rejected.
  ///
  /// In en, this message translates to:
  /// **'The try-on engine rejected this image.'**
  String get failure_content_rejected;

  /// No description provided for @failure_budget_exhausted.
  ///
  /// In en, this message translates to:
  /// **'The render budget is used up. Your look is saved, and the organizer can raise the budget.'**
  String get failure_budget_exhausted;

  /// No description provided for @failure_provider_error.
  ///
  /// In en, this message translates to:
  /// **'The try-on service had a problem.'**
  String get failure_provider_error;

  /// No description provided for @failure_timeout.
  ///
  /// In en, this message translates to:
  /// **'The try-on took too long.'**
  String get failure_timeout;

  /// No description provided for @lockLook.
  ///
  /// In en, this message translates to:
  /// **'Lock my look'**
  String get lockLook;

  /// No description provided for @unlockLook.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockLook;

  /// No description provided for @lockedNote.
  ///
  /// In en, this message translates to:
  /// **'Locked: this is your final look.'**
  String get lockedNote;

  /// No description provided for @shareHair.
  ///
  /// In en, this message translates to:
  /// **'Share hair color with my hairdresser'**
  String get shareHair;

  /// No description provided for @shareLook.
  ///
  /// In en, this message translates to:
  /// **'Share my look with a shop'**
  String get shareLook;

  /// No description provided for @shareLinkReady.
  ///
  /// In en, this message translates to:
  /// **'Read-only link, valid until {date}:'**
  String shareLinkReady(Object date);

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @myData.
  ///
  /// In en, this message translates to:
  /// **'My data'**
  String get myData;

  /// No description provided for @togetherNoPartner.
  ///
  /// In en, this message translates to:
  /// **'Choose your partner to see yourselves side by side.'**
  String get togetherNoPartner;

  /// No description provided for @partnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partnerLabel;

  /// No description provided for @noPartner.
  ///
  /// In en, this message translates to:
  /// **'No partner'**
  String get noPartner;

  /// No description provided for @youAndPartner.
  ///
  /// In en, this message translates to:
  /// **'You and {name}'**
  String youAndPartner(Object name);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @boardRendered.
  ///
  /// In en, this message translates to:
  /// **'{rendered} of {total} rendered'**
  String boardRendered(Object rendered, Object total);

  /// No description provided for @boardLocked.
  ///
  /// In en, this message translates to:
  /// **'{locked} locked'**
  String boardLocked(Object locked);

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @budgetOfCap.
  ///
  /// In en, this message translates to:
  /// **'of {cap}'**
  String budgetOfCap(Object cap);

  /// No description provided for @budgetPerPersonCap.
  ///
  /// In en, this message translates to:
  /// **'Up to {amount} per person'**
  String budgetPerPersonCap(Object amount);

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get overBudget;

  /// No description provided for @overBudgetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} over the per-person budget'**
  String overBudgetCount(Object count);

  /// No description provided for @unitsUsed.
  ///
  /// In en, this message translates to:
  /// **'Try-on units used: {used} of {cap}'**
  String unitsUsed(Object cap, Object used);

  /// No description provided for @unitsSimulated.
  ///
  /// In en, this message translates to:
  /// **'Renders here are simulated and use no units.'**
  String get unitsSimulated;

  /// No description provided for @noLookYet.
  ///
  /// In en, this message translates to:
  /// **'No look yet'**
  String get noLookYet;

  /// No description provided for @noPhotoYet.
  ///
  /// In en, this message translates to:
  /// **'No photo yet'**
  String get noPhotoYet;

  /// No description provided for @withPartner.
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String withPartner(Object name);

  /// No description provided for @seatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seated'**
  String get seatedLabel;

  /// No description provided for @lockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabel;

  /// No description provided for @groupHarmony.
  ///
  /// In en, this message translates to:
  /// **'Group harmony {score}/100'**
  String groupHarmony(Object score);

  /// No description provided for @addPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Invite people with the code {code}.'**
  String addPeopleHint(Object code);

  /// No description provided for @harmonyTitle.
  ///
  /// In en, this message translates to:
  /// **'Color harmony'**
  String get harmonyTitle;

  /// No description provided for @harmonyWeakest.
  ///
  /// In en, this message translates to:
  /// **'Weakest pair'**
  String get harmonyWeakest;

  /// No description provided for @harmonyNoData.
  ///
  /// In en, this message translates to:
  /// **'Add outfits to see how the group\'s colors work together.'**
  String get harmonyNoData;

  /// No description provided for @harmonyNoWarnings.
  ///
  /// In en, this message translates to:
  /// **'No near-miss colors. The group reads as intentional.'**
  String get harmonyNoWarnings;

  /// No description provided for @harmonyWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get harmonyWarnings;

  /// No description provided for @harmonyAll.
  ///
  /// In en, this message translates to:
  /// **'All comparisons'**
  String get harmonyAll;

  /// No description provided for @harmonyWithoutOutfit.
  ///
  /// In en, this message translates to:
  /// **'No outfit yet: {names}'**
  String harmonyWithoutOutfit(Object names);

  /// No description provided for @relationMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get relationMatched;

  /// No description provided for @relationNearMiss.
  ///
  /// In en, this message translates to:
  /// **'Near-miss'**
  String get relationNearMiss;

  /// No description provided for @relationComplementary.
  ///
  /// In en, this message translates to:
  /// **'Complementary'**
  String get relationComplementary;

  /// No description provided for @relationContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get relationContrast;

  /// No description provided for @pairMatched.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} match: both wear {color}.'**
  String pairMatched(Object a, Object b, Object color);

  /// No description provided for @pairNearMiss.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {colorA} and {b}\'s {colorB} are close but not the same shade (ΔE {de}). Side by side this can look like a mistake: match them exactly or pick clearly different colors.'**
  String pairNearMiss(
    Object a,
    Object b,
    Object colorA,
    Object colorB,
    Object de,
  );

  /// No description provided for @pairComplementary.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {colorA} and {b}\'s {colorB} are complementary colors that set each other off.'**
  String pairComplementary(Object a, Object b, Object colorA, Object colorB);

  /// No description provided for @pairContrast.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {colorA} and {b}\'s {colorB} are clearly different, which reads as intentional.'**
  String pairContrast(Object a, Object b, Object colorA, Object colorB);

  /// No description provided for @selfMatched.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {subject} matches the {color} outfit.'**
  String selfMatched(Object a, Object color, Object subject);

  /// No description provided for @selfNearMiss.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {colorA} {subject} is close to, but not the same as, the {colorB} outfit (ΔE {de}). Match it or choose a clearly different shade.'**
  String selfNearMiss(
    Object a,
    Object colorA,
    Object colorB,
    Object de,
    Object subject,
  );

  /// No description provided for @selfComplementary.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {colorA} {subject} is complementary to the {colorB} outfit.'**
  String selfComplementary(
    Object a,
    Object colorA,
    Object colorB,
    Object subject,
  );

  /// No description provided for @selfContrast.
  ///
  /// In en, this message translates to:
  /// **'{a}\'s {colorA} {subject} stands apart from the {colorB} outfit, which reads as intentional.'**
  String selfContrast(Object a, Object colorA, Object colorB, Object subject);

  /// No description provided for @subjectLips.
  ///
  /// In en, this message translates to:
  /// **'lip color'**
  String get subjectLips;

  /// No description provided for @subjectHair.
  ///
  /// In en, this message translates to:
  /// **'hair color'**
  String get subjectHair;

  /// No description provided for @explainButton.
  ///
  /// In en, this message translates to:
  /// **'Explain in plain words'**
  String get explainButton;

  /// No description provided for @explainNote.
  ///
  /// In en, this message translates to:
  /// **'Written by Gemini from the results above. Scores come only from the color rules.'**
  String get explainNote;

  /// No description provided for @harmonyMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get harmonyMethodTitle;

  /// No description provided for @harmonyMethod.
  ///
  /// In en, this message translates to:
  /// **'Garment colors come from the catalogue photos (background removed, k-means clustering in CIELAB). Every pair is compared with CIEDE2000: under 2 is a match, 2 to 8 is a near-miss that can look like a mistake, and opposite hues are complementary. Lip and hair colors are compared with the same person\'s outfit. The group score is the weakest pair, not an average. Harmony is about colors only, never about bodies or skin.'**
  String get harmonyMethod;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'black'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'white'**
  String get colorWhite;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'gray'**
  String get colorGray;

  /// No description provided for @colorBeige.
  ///
  /// In en, this message translates to:
  /// **'beige'**
  String get colorBeige;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'brown'**
  String get colorBrown;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get colorRed;

  /// No description provided for @colorBurgundy.
  ///
  /// In en, this message translates to:
  /// **'burgundy'**
  String get colorBurgundy;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'pink'**
  String get colorPink;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'orange'**
  String get colorOrange;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'yellow'**
  String get colorYellow;

  /// No description provided for @colorOlive.
  ///
  /// In en, this message translates to:
  /// **'olive'**
  String get colorOlive;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get colorGreen;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'teal'**
  String get colorTeal;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get colorBlue;

  /// No description provided for @colorNavy.
  ///
  /// In en, this message translates to:
  /// **'navy'**
  String get colorNavy;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'purple'**
  String get colorPurple;

  /// No description provided for @colorLavender.
  ///
  /// In en, this message translates to:
  /// **'lavender'**
  String get colorLavender;

  /// No description provided for @colorMagenta.
  ///
  /// In en, this message translates to:
  /// **'magenta'**
  String get colorMagenta;

  /// No description provided for @colorLight.
  ///
  /// In en, this message translates to:
  /// **'light {color}'**
  String colorLight(Object color);

  /// No description provided for @colorDark.
  ///
  /// In en, this message translates to:
  /// **'dark {color}'**
  String colorDark(Object color);

  /// No description provided for @colorMuted.
  ///
  /// In en, this message translates to:
  /// **'muted {color}'**
  String colorMuted(Object color);

  /// No description provided for @catalogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get catalogueTitle;

  /// No description provided for @addGarment.
  ///
  /// In en, this message translates to:
  /// **'Add outfit'**
  String get addGarment;

  /// No description provided for @addMakeup.
  ///
  /// In en, this message translates to:
  /// **'Add lip color'**
  String get addMakeup;

  /// No description provided for @addHair.
  ///
  /// In en, this message translates to:
  /// **'Add hair color'**
  String get addHair;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get itemName;

  /// No description provided for @itemPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get itemPrice;

  /// No description provided for @itemCategory.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get itemCategory;

  /// No description provided for @categoryFullBody.
  ///
  /// In en, this message translates to:
  /// **'Full outfit'**
  String get categoryFullBody;

  /// No description provided for @categoryUpperBody.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get categoryUpperBody;

  /// No description provided for @categoryLowerBody.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get categoryLowerBody;

  /// No description provided for @categoryOuter.
  ///
  /// In en, this message translates to:
  /// **'Jacket or outerwear'**
  String get categoryOuter;

  /// No description provided for @itemColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get itemColor;

  /// No description provided for @chooseItemPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose product photo'**
  String get chooseItemPhoto;

  /// No description provided for @itemPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'A front-facing product photo of one garment on a plain background works best.'**
  String get itemPhotoHint;

  /// No description provided for @itemNeedsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a product photo so the outfit can be tried on.'**
  String get itemNeedsPhoto;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {vendor}'**
  String addedBy(Object vendor);

  /// No description provided for @colorsFound.
  ///
  /// In en, this message translates to:
  /// **'Colors found'**
  String get colorsFound;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Looks that use it lose this item.'**
  String deleteItemConfirm(Object name);

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite people'**
  String get inviteTitle;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Event code'**
  String get inviteCode;

  /// No description provided for @inviteLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get inviteLinkLabel;

  /// No description provided for @inviteQrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan to join'**
  String get inviteQrHint;

  /// No description provided for @vendorLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendorLinksTitle;

  /// No description provided for @vendorCatalogueExplain.
  ///
  /// In en, this message translates to:
  /// **'Let a shop or costume keeper add items to this catalogue, without an account.'**
  String get vendorCatalogueExplain;

  /// No description provided for @vendorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor name (optional)'**
  String get vendorNameLabel;

  /// No description provided for @createLink.
  ///
  /// In en, this message translates to:
  /// **'Create link'**
  String get createLink;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event settings'**
  String get settingsTitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEvent;

  /// No description provided for @deleteEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} with all photos, renders and links? This cannot be undone.'**
  String deleteEventConfirm(Object name);

  /// No description provided for @participantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsTitle;

  /// No description provided for @removeParticipantConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} and delete their photo and renders?'**
  String removeParticipantConfirm(Object name);

  /// No description provided for @myDataTitle.
  ///
  /// In en, this message translates to:
  /// **'My data'**
  String get myDataTitle;

  /// No description provided for @myDataExplain.
  ///
  /// In en, this message translates to:
  /// **'Your photo and renders are stored only for this event. Photos are resized and stripped of location data before anything is sent to the try-on engine.'**
  String get myDataExplain;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your photo and every render made from it?'**
  String get deletePhotoConfirm;

  /// No description provided for @leaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Leave this event and delete my data'**
  String get leaveEvent;

  /// No description provided for @leaveEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}? Your photo, look and renders are deleted.'**
  String leaveEventConfirm(Object name);

  /// No description provided for @deleteEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Delete my data in all events'**
  String get deleteEverywhere;

  /// No description provided for @deleteEverywhereConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave every event you joined and delete all your photos, looks and renders?'**
  String get deleteEverywhereConfirm;

  /// No description provided for @deletedDone.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get deletedDone;

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

  /// No description provided for @vendorFor.
  ///
  /// In en, this message translates to:
  /// **'From {name} for {event}'**
  String vendorFor(Object event, Object name);

  /// No description provided for @vendorBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get vendorBefore;

  /// No description provided for @vendorAfter.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get vendorAfter;

  /// No description provided for @vendorExpires.
  ///
  /// In en, this message translates to:
  /// **'Link valid until {date}'**
  String vendorExpires(Object date);

  /// No description provided for @vendorExpired.
  ///
  /// In en, this message translates to:
  /// **'This link has expired.'**
  String get vendorExpired;

  /// No description provided for @vendorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This link does not exist or was revoked.'**
  String get vendorNotFound;

  /// No description provided for @vendorCatalogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Add items to {event}'**
  String vendorCatalogueTitle(Object event);

  /// No description provided for @vendorAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get vendorAddItem;

  /// No description provided for @vendorItemsInEvent.
  ///
  /// In en, this message translates to:
  /// **'Items in this catalogue'**
  String get vendorItemsInEvent;

  /// No description provided for @inclusionTitle.
  ///
  /// In en, this message translates to:
  /// **'Inclusion: standing vs seated'**
  String get inclusionTitle;

  /// No description provided for @inclusionIntro.
  ///
  /// In en, this message translates to:
  /// **'Virtual try-on is usually tested on standing models. We measure how Wearmony works for seated people, such as wheelchair users, and publish the numbers as they are.'**
  String get inclusionIntro;

  /// No description provided for @inclusionNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet.'**
  String get inclusionNotMeasured;

  /// No description provided for @inclusionEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine: {engine}'**
  String inclusionEngine(Object engine);

  /// No description provided for @inclusionMeasuredAt.
  ///
  /// In en, this message translates to:
  /// **'Measured {date}'**
  String inclusionMeasuredAt(Object date);

  /// No description provided for @colPose.
  ///
  /// In en, this message translates to:
  /// **'Pose'**
  String get colPose;

  /// No description provided for @colFraming.
  ///
  /// In en, this message translates to:
  /// **'Framing'**
  String get colFraming;

  /// No description provided for @colRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get colRuns;

  /// No description provided for @colApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get colApplied;

  /// No description provided for @colSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent failures'**
  String get colSilent;

  /// No description provided for @colErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get colErrors;

  /// No description provided for @colFaceChanged.
  ///
  /// In en, this message translates to:
  /// **'Face changed'**
  String get colFaceChanged;

  /// No description provided for @colMedianTime.
  ///
  /// In en, this message translates to:
  /// **'Median time'**
  String get colMedianTime;

  /// No description provided for @framingAsCatalogued.
  ///
  /// In en, this message translates to:
  /// **'As catalogued'**
  String get framingAsCatalogued;

  /// No description provided for @framingUpperBody.
  ///
  /// In en, this message translates to:
  /// **'Upper-body fallback'**
  String get framingUpperBody;

  /// No description provided for @notReviewed.
  ///
  /// In en, this message translates to:
  /// **'not reviewed'**
  String get notReviewed;

  /// No description provided for @heroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Group virtual try-on for events'**
  String get heroEyebrow;

  /// No description provided for @featureTryOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Try it on, together'**
  String get featureTryOnTitle;

  /// No description provided for @featureTryOnBody.
  ///
  /// In en, this message translates to:
  /// **'Outfit, lip color and hair color on your own photo, then everyone side by side.'**
  String get featureTryOnBody;

  /// No description provided for @featureHarmonyTitle.
  ///
  /// In en, this message translates to:
  /// **'Color harmony'**
  String get featureHarmonyTitle;

  /// No description provided for @featureHarmonyBody.
  ///
  /// In en, this message translates to:
  /// **'Spots almost-matching colors before the night, explained in one sentence.'**
  String get featureHarmonyBody;

  /// No description provided for @featureBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared budget'**
  String get featureBudgetTitle;

  /// No description provided for @featureBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Per-person and group totals, so nobody is surprised.'**
  String get featureBudgetBody;

  /// No description provided for @featureInclusiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Made for everyone'**
  String get featureInclusiveTitle;

  /// No description provided for @featureInclusiveBody.
  ///
  /// In en, this message translates to:
  /// **'Seated photos are supported, and how well they work is measured.'**
  String get featureInclusiveBody;

  /// No description provided for @statRendered.
  ///
  /// In en, this message translates to:
  /// **'Rendered'**
  String get statRendered;

  /// No description provided for @statLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked looks'**
  String get statLocked;

  /// No description provided for @statHarmony.
  ///
  /// In en, this message translates to:
  /// **'Harmony'**
  String get statHarmony;

  /// No description provided for @statBudget.
  ///
  /// In en, this message translates to:
  /// **'Group total'**
  String get statBudget;

  /// No description provided for @yourLook.
  ///
  /// In en, this message translates to:
  /// **'Your look'**
  String get yourLook;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @stepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Try-on steps'**
  String get stepsTitle;

  /// No description provided for @badgeIllustration.
  ///
  /// In en, this message translates to:
  /// **'Illustration'**
  String get badgeIllustration;

  /// No description provided for @badgeSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get badgeSimulated;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This page does not exist'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The link may be old or mistyped.'**
  String get notFoundBody;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Wearmony'**
  String get goHome;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Invite the group'**
  String get step1Title;

  /// No description provided for @step1Body.
  ///
  /// In en, this message translates to:
  /// **'Create the event and share a code, a link or a QR code.'**
  String get step1Body;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Everyone tries on'**
  String get step2Title;

  /// No description provided for @step2Body.
  ///
  /// In en, this message translates to:
  /// **'Each person adds one photo and tries outfits, lip colors and hair colors.'**
  String get step2Body;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'See the group in harmony'**
  String get step3Title;

  /// No description provided for @step3Body.
  ///
  /// In en, this message translates to:
  /// **'Spot almost-matching colors and stay within the shared budget, before anyone buys.'**
  String get step3Body;

  /// No description provided for @clashFixed.
  ///
  /// In en, this message translates to:
  /// **'Clash fixed: the group’s colors work together now.'**
  String get clashFixed;

  /// No description provided for @harmonyMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Harmony map'**
  String get harmonyMapTitle;

  /// No description provided for @harmonyMapHint.
  ///
  /// In en, this message translates to:
  /// **'Each line compares two outfits. Point at or tap a person to see only their pairs. Small dots are hair and lip colors.'**
  String get harmonyMapHint;

  /// No description provided for @fixTitle.
  ///
  /// In en, this message translates to:
  /// **'How to fix it'**
  String get fixTitle;

  /// No description provided for @fixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swaps from this event\'s catalogue that remove the near-miss, checked with the same color math. No model opinions.'**
  String get fixSubtitle;

  /// No description provided for @fixNone.
  ///
  /// In en, this message translates to:
  /// **'No item in the catalogue fixes this yet. Add one in the same shade or in a clearly different color.'**
  String get fixNone;

  /// No description provided for @fixWith.
  ///
  /// In en, this message translates to:
  /// **'{relation} with {name}'**
  String fixWith(Object name, Object relation);

  /// No description provided for @fixWithOutfit.
  ///
  /// In en, this message translates to:
  /// **'{relation} with the outfit'**
  String fixWithOutfit(Object relation);

  /// No description provided for @fixScore.
  ///
  /// In en, this message translates to:
  /// **'Group harmony'**
  String get fixScore;

  /// No description provided for @fixSamePrice.
  ///
  /// In en, this message translates to:
  /// **'Same price'**
  String get fixSamePrice;

  /// No description provided for @fixOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over the per-person budget'**
  String get fixOverBudget;

  /// No description provided for @fixApply.
  ///
  /// In en, this message translates to:
  /// **'Switch to this'**
  String get fixApply;

  /// No description provided for @fixApplied.
  ///
  /// In en, this message translates to:
  /// **'Look updated. The harmony check already uses it.'**
  String get fixApplied;

  /// No description provided for @fixPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get fixPreview;

  /// No description provided for @fixCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy suggestion'**
  String get fixCopy;

  /// No description provided for @fixCopied.
  ///
  /// In en, this message translates to:
  /// **'Suggestion copied'**
  String get fixCopied;

  /// No description provided for @fixShareText.
  ///
  /// In en, this message translates to:
  /// **'{name}, try {item} instead: next to {other} it reads as “{relation}”, not a near-miss.'**
  String fixShareText(Object item, Object name, Object other, Object relation);

  /// No description provided for @fixShareTextSelf.
  ///
  /// In en, this message translates to:
  /// **'{name}, try {item} instead: with the outfit it reads as “{relation}”, not a near-miss.'**
  String fixShareTextSelf(Object item, Object name, Object relation);

  /// No description provided for @frameOpen.
  ///
  /// In en, this message translates to:
  /// **'Group photo'**
  String get frameOpen;

  /// No description provided for @frameOpenHint.
  ///
  /// In en, this message translates to:
  /// **'See everyone\'s current look in one frame and save it as an image.'**
  String get frameOpenHint;

  /// No description provided for @frameTitle.
  ///
  /// In en, this message translates to:
  /// **'Group photo'**
  String get frameTitle;

  /// No description provided for @frameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s current look in one frame. Partners stand together.'**
  String get frameSubtitle;

  /// No description provided for @frameBackdrop.
  ///
  /// In en, this message translates to:
  /// **'Backdrop'**
  String get frameBackdrop;

  /// No description provided for @backdropBallroom.
  ///
  /// In en, this message translates to:
  /// **'Ballroom'**
  String get backdropBallroom;

  /// No description provided for @backdropStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get backdropStage;

  /// No description provided for @backdropGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get backdropGarden;

  /// No description provided for @backdropStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get backdropStudio;

  /// No description provided for @frameSave.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get frameSave;

  /// No description provided for @frameShare.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get frameShare;

  /// No description provided for @frameSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved to your downloads.'**
  String get frameSaved;

  /// No description provided for @frameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The image could not be created. Try again.'**
  String get frameSaveFailed;

  /// No description provided for @frameHint.
  ///
  /// In en, this message translates to:
  /// **'The image keeps the labels that say what is simulated.'**
  String get frameHint;

  /// No description provided for @frameEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one has joined yet.'**
  String get frameEmpty;

  /// No description provided for @frameHarmony.
  ///
  /// In en, this message translates to:
  /// **'Harmony {score}/100'**
  String frameHarmony(int score);

  /// No description provided for @framePeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String framePeople(int count);

  /// No description provided for @frameHonestDemo.
  ///
  /// In en, this message translates to:
  /// **'Illustrations, not real photos'**
  String get frameHonestDemo;

  /// No description provided for @frameHonestMock.
  ///
  /// In en, this message translates to:
  /// **'Simulated try-on (mock mode)'**
  String get frameHonestMock;

  /// No description provided for @frameHonestReal.
  ///
  /// In en, this message translates to:
  /// **'Virtual try-on preview, not a fit guarantee'**
  String get frameHonestReal;

  /// No description provided for @frameShareText.
  ///
  /// In en, this message translates to:
  /// **'Our looks for {event}, made with Wearmony.'**
  String frameShareText(Object event);

  /// No description provided for @readinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting ready'**
  String get readinessTitle;

  /// No description provided for @readinessPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get readinessPhoto;

  /// No description provided for @readinessLook.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get readinessLook;

  /// No description provided for @readinessPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get readinessPreview;

  /// No description provided for @readinessLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get readinessLocked;

  /// No description provided for @nextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Needs a photo'**
  String get nextPhoto;

  /// No description provided for @nextLook.
  ///
  /// In en, this message translates to:
  /// **'Choosing a look'**
  String get nextLook;

  /// No description provided for @nextPreview.
  ///
  /// In en, this message translates to:
  /// **'No preview yet'**
  String get nextPreview;

  /// No description provided for @nextLock.
  ///
  /// In en, this message translates to:
  /// **'Can lock the look'**
  String get nextLock;

  /// No description provided for @nextDone.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get nextDone;

  /// No description provided for @reminderCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy a reminder'**
  String get reminderCopy;

  /// No description provided for @reminderText.
  ///
  /// In en, this message translates to:
  /// **'Please finish your look for {event} on Wearmony: {link}'**
  String reminderText(Object event, Object link);

  /// No description provided for @reminderCopied.
  ///
  /// In en, this message translates to:
  /// **'Reminder copied. Paste it in your group chat.'**
  String get reminderCopied;

  /// No description provided for @eventDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Event date (optional)'**
  String get eventDateLabel;

  /// No description provided for @eventDateNone.
  ///
  /// In en, this message translates to:
  /// **'No date yet'**
  String get eventDateNone;

  /// No description provided for @eventDateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the date'**
  String get eventDateClear;

  /// No description provided for @countdownToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get countdownToday;

  /// No description provided for @countdownDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String countdownDays(int count);

  /// No description provided for @countdownPast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String countdownPast(int count);

  /// No description provided for @featureFixTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix it in one tap'**
  String get featureFixTitle;

  /// No description provided for @featureFixBody.
  ///
  /// In en, this message translates to:
  /// **'When two colors almost match, Wearmony finds catalogue swaps that fix it and shows what changes.'**
  String get featureFixBody;

  /// No description provided for @featureFrameTitle.
  ///
  /// In en, this message translates to:
  /// **'One group photo'**
  String get featureFrameTitle;

  /// No description provided for @featureFrameBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s current look in one frame, partners side by side, ready to share.'**
  String get featureFrameBody;

  /// No description provided for @fixOthersLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Another near-miss in the group stays} other{{count} other near-misses in the group stay}}'**
  String fixOthersLeft(int count);

  /// No description provided for @fixWithYou.
  ///
  /// In en, this message translates to:
  /// **'{relation} with you'**
  String fixWithYou(Object relation);

  /// No description provided for @fixShareTextMe.
  ///
  /// In en, this message translates to:
  /// **'{name}, try {item} instead: next to me it reads as “{relation}”, not a near-miss.'**
  String fixShareTextMe(Object item, Object name, Object relation);

  /// No description provided for @harmonyMapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Harmony map of {people} people with {nearMisses, plural, =0{no near-misses} =1{one near-miss} other{{nearMisses} near-misses}}.'**
  String harmonyMapSemantics(int people, int nearMisses);

  /// No description provided for @frameSemantics.
  ///
  /// In en, this message translates to:
  /// **'Group photo of {event}: {names}.'**
  String frameSemantics(Object event, Object names);

  /// No description provided for @openTheatreDemo.
  ///
  /// In en, this message translates to:
  /// **'Theatre cast demo'**
  String get openTheatreDemo;

  /// No description provided for @notPreviewed.
  ///
  /// In en, this message translates to:
  /// **'New look, not previewed yet'**
  String get notPreviewed;

  /// No description provided for @poweredByEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Powered by YouCam APIs'**
  String get poweredByEyebrow;

  /// No description provided for @poweredByTitle.
  ///
  /// In en, this message translates to:
  /// **'One photo, three try-on steps'**
  String get poweredByTitle;

  /// No description provided for @poweredByBody.
  ///
  /// In en, this message translates to:
  /// **'Each look is built as a chain on the participant\'s own photo: the outfit first, then the lip color on that result, then the hair color. Every step can be checked on its own.'**
  String get poweredByBody;

  /// No description provided for @chainPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get chainPhotoTitle;

  /// No description provided for @chainPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Checked for size and light before any try-on, standing or seated.'**
  String get chainPhotoBody;

  /// No description provided for @chainClothesBody.
  ///
  /// In en, this message translates to:
  /// **'Puts the outfit from the event catalogue on the photo.'**
  String get chainClothesBody;

  /// No description provided for @chainMakeupBody.
  ///
  /// In en, this message translates to:
  /// **'Adds the exact lip color from the catalogue.'**
  String get chainMakeupBody;

  /// No description provided for @chainHairBody.
  ///
  /// In en, this message translates to:
  /// **'Applies the chosen hair color.'**
  String get chainHairBody;

  /// No description provided for @factCache.
  ///
  /// In en, this message translates to:
  /// **'Each step is cached: the same photo and item never cost twice.'**
  String get factCache;

  /// No description provided for @factLedger.
  ///
  /// In en, this message translates to:
  /// **'A unit ledger caps spending per event and per person.'**
  String get factLedger;

  /// No description provided for @factLabels.
  ///
  /// In en, this message translates to:
  /// **'Simulated and demo results are always labeled.'**
  String get factLabels;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get privacyTitle;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos are personal. Wearmony treats them that way.'**
  String get privacySubtitle;

  /// No description provided for @privacyPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private to the event'**
  String get privacyPrivateTitle;

  /// No description provided for @privacyPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Only people in your event see your photo and previews.'**
  String get privacyPrivateBody;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete at any time'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove your photo and data yourself; organizers can delete the whole event.'**
  String get privacyDeleteBody;

  /// No description provided for @privacyLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Links that expire'**
  String get privacyLinksTitle;

  /// No description provided for @privacyLinksBody.
  ///
  /// In en, this message translates to:
  /// **'Vendor links are read-only and stop working after their date.'**
  String get privacyLinksBody;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Adults, with consent'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentBody.
  ///
  /// In en, this message translates to:
  /// **'A clear consent screen comes before any photo upload.'**
  String get privacyConsentBody;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get faqTitle;

  /// No description provided for @faqSeatedQ.
  ///
  /// In en, this message translates to:
  /// **'Does it work if I use a wheelchair?'**
  String get faqSeatedQ;

  /// No description provided for @faqSeatedA.
  ///
  /// In en, this message translates to:
  /// **'Yes. Choose \"seated\" when you add your photo. Try-on engines are usually tested on standing people, so Wearmony measures how well seated photos work and publishes the results.'**
  String get faqSeatedA;

  /// No description provided for @faqNearMissQ.
  ///
  /// In en, this message translates to:
  /// **'What is a near-miss?'**
  String get faqNearMissQ;

  /// No description provided for @faqNearMissA.
  ///
  /// In en, this message translates to:
  /// **'Two colors that are close but not the same, like two slightly different pinks. Side by side they read as a mistake, so Wearmony warns you and suggests swaps that fix it.'**
  String get faqNearMissA;

  /// No description provided for @faqExactQ.
  ///
  /// In en, this message translates to:
  /// **'Is the preview exact?'**
  String get faqExactQ;

  /// No description provided for @faqExactA.
  ///
  /// In en, this message translates to:
  /// **'It is a visual preview, not a fit guarantee. Fabric, light and cameras change how colors look on the night.'**
  String get faqExactA;

  /// No description provided for @faqPhotoQ.
  ///
  /// In en, this message translates to:
  /// **'Who can see my photo?'**
  String get faqPhotoQ;

  /// No description provided for @faqPhotoA.
  ///
  /// In en, this message translates to:
  /// **'Only the people in your event. A hairdresser you invite sees only the hair color and your before photo, through a link that expires. You can delete your photo at any time.'**
  String get faqPhotoA;

  /// No description provided for @faqAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Do I need an account?'**
  String get faqAccountQ;

  /// No description provided for @faqAccountA.
  ///
  /// In en, this message translates to:
  /// **'No. You join with a code. Signing in with email is optional, to use your events on another device.'**
  String get faqAccountA;

  /// No description provided for @faqUnitsQ.
  ///
  /// In en, this message translates to:
  /// **'Does a preview cost anything?'**
  String get faqUnitsQ;

  /// No description provided for @faqUnitsA.
  ///
  /// In en, this message translates to:
  /// **'Planning, colors and budgets use no API units. Each try-on step uses YouCam API units from the event budget, with caps per event and per person, and the same photo and item are never paid for twice.'**
  String get faqUnitsA;

  /// No description provided for @footerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get footerStart;

  /// No description provided for @footerDemos.
  ///
  /// In en, this message translates to:
  /// **'Demos'**
  String get footerDemos;

  /// No description provided for @footerLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get footerLearn;

  /// No description provided for @footerTagline.
  ///
  /// In en, this message translates to:
  /// **'Group virtual try-on for proms, plays, weddings and group photos.'**
  String get footerTagline;

  /// No description provided for @footerHackathon.
  ///
  /// In en, this message translates to:
  /// **'Built for the YouCam API Skin AI & eCommerce VTO Hackathon. People in the demos are illustrations.'**
  String get footerHackathon;

  /// No description provided for @tourButton.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get tourButton;

  /// No description provided for @tourTitle.
  ///
  /// In en, this message translates to:
  /// **'Take the tour'**
  String get tourTitle;

  /// No description provided for @tourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few things to try in this demo.'**
  String get tourSubtitle;

  /// No description provided for @tourFixTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix your clash'**
  String get tourFixTitle;

  /// No description provided for @tourFixBody.
  ///
  /// In en, this message translates to:
  /// **'You and Sofia nearly match. Fix it with one tap.'**
  String get tourFixBody;

  /// No description provided for @tourPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'See everyone in one frame'**
  String get tourPhotoTitle;

  /// No description provided for @tourPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'The group photo, ready to save.'**
  String get tourPhotoBody;

  /// No description provided for @tourMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the harmony map'**
  String get tourMapTitle;

  /// No description provided for @tourMapBody.
  ///
  /// In en, this message translates to:
  /// **'Every pair of outfits as one line, colored by how they work together.'**
  String get tourMapBody;

  /// No description provided for @tourBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the budget'**
  String get tourBudgetTitle;

  /// No description provided for @tourBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Who is over the cap, and who still needs a photo or a lock.'**
  String get tourBudgetBody;

  /// No description provided for @tourTheatreTitle.
  ///
  /// In en, this message translates to:
  /// **'Same engine, another event'**
  String get tourTheatreTitle;

  /// No description provided for @tourTheatreBody.
  ///
  /// In en, this message translates to:
  /// **'Open the school theatre cast.'**
  String get tourTheatreBody;

  /// No description provided for @tourCostumesTitle.
  ///
  /// In en, this message translates to:
  /// **'Spot the costume clash'**
  String get tourCostumesTitle;

  /// No description provided for @tourCostumesBody.
  ///
  /// In en, this message translates to:
  /// **'Romeo\'s and Mercutio\'s teals nearly match.'**
  String get tourCostumesBody;

  /// No description provided for @tourStageTitle.
  ///
  /// In en, this message translates to:
  /// **'The cast on stage'**
  String get tourStageTitle;

  /// No description provided for @tourStageBody.
  ///
  /// In en, this message translates to:
  /// **'The group photo on a stage backdrop.'**
  String get tourStageBody;

  /// No description provided for @tourPromTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to the prom'**
  String get tourPromTitle;

  /// No description provided for @tourPromBody.
  ///
  /// In en, this message translates to:
  /// **'Open the prom demo.'**
  String get tourPromBody;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get activityTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Activity appears here as people join and try on looks.'**
  String get activityEmpty;

  /// No description provided for @activityJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String activityJoined(Object name);

  /// No description provided for @activityLook.
  ///
  /// In en, this message translates to:
  /// **'{name} chose {item}'**
  String activityLook(Object item, Object name);

  /// No description provided for @activityLocked.
  ///
  /// In en, this message translates to:
  /// **'{name} locked their look'**
  String activityLocked(Object name);

  /// No description provided for @activityPreviewed.
  ///
  /// In en, this message translates to:
  /// **'{name} tried on their look'**
  String activityPreviewed(Object name);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String timeMinutes(int count);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 h ago} other{{count} h ago}}'**
  String timeHours(int count);

  /// No description provided for @timeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String timeDays(int count);

  /// No description provided for @previewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your previews'**
  String get previewsTitle;

  /// No description provided for @previewsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap one to compare it with your current look.'**
  String get previewsHint;

  /// No description provided for @previewsNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get previewsNow;

  /// No description provided for @lookUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get lookUnnamed;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare looks'**
  String get compareTitle;

  /// No description provided for @compareWear.
  ///
  /// In en, this message translates to:
  /// **'Wear {name} again'**
  String compareWear(Object name);

  /// No description provided for @compareNote.
  ///
  /// In en, this message translates to:
  /// **'Both previews are already made, so going back costs nothing.'**
  String get compareNote;

  /// No description provided for @activityLockedYou.
  ///
  /// In en, this message translates to:
  /// **'You locked your look'**
  String get activityLockedYou;

  /// No description provided for @activityPreviewedYou.
  ///
  /// In en, this message translates to:
  /// **'You tried on your look'**
  String get activityPreviewedYou;

  /// No description provided for @inclusionMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'How we measure'**
  String get inclusionMethodTitle;

  /// No description provided for @method1Title.
  ///
  /// In en, this message translates to:
  /// **'Same garments'**
  String get method1Title;

  /// No description provided for @method1Body.
  ///
  /// In en, this message translates to:
  /// **'Every photo gets the same outfits from one catalogue, so only the pose differs.'**
  String get method1Body;

  /// No description provided for @method2Title.
  ///
  /// In en, this message translates to:
  /// **'Standing and seated'**
  String get method2Title;

  /// No description provided for @method2Body.
  ///
  /// In en, this message translates to:
  /// **'Photos of consenting adults, standing and seated, with the same framing rules.'**
  String get method2Body;

  /// No description provided for @method3Title.
  ///
  /// In en, this message translates to:
  /// **'Four things recorded'**
  String get method3Title;

  /// No description provided for @method3Body.
  ///
  /// In en, this message translates to:
  /// **'Whether the outfit was applied, silent failures, whether the face changed (human review) and the time taken.'**
  String get method3Body;

  /// No description provided for @method4Title.
  ///
  /// In en, this message translates to:
  /// **'Published as measured'**
  String get method4Title;

  /// No description provided for @method4Body.
  ///
  /// In en, this message translates to:
  /// **'No estimates. Mitigations are reported as before and after numbers.'**
  String get method4Body;

  /// No description provided for @inclusionTableTitle.
  ///
  /// In en, this message translates to:
  /// **'What will be published'**
  String get inclusionTableTitle;

  /// No description provided for @inclusionTableNote.
  ///
  /// In en, this message translates to:
  /// **'Every cell stays empty until it is measured.'**
  String get inclusionTableNote;

  /// No description provided for @inclusionBuiltTitle.
  ///
  /// In en, this message translates to:
  /// **'Already built for seated people'**
  String get inclusionBuiltTitle;

  /// No description provided for @built1.
  ///
  /// In en, this message translates to:
  /// **'Every participant chooses \"standing\" or \"seated\" for their photo.'**
  String get built1;

  /// No description provided for @built2.
  ///
  /// In en, this message translates to:
  /// **'If a full-length outfit fails on a seated photo, Wearmony retries once with upper-body framing.'**
  String get built2;

  /// No description provided for @built3.
  ///
  /// In en, this message translates to:
  /// **'Every render is checked for an outfit that was not applied, so a silent failure is labeled, not shown as a result.'**
  String get built3;

  /// No description provided for @built4.
  ///
  /// In en, this message translates to:
  /// **'The demo prom includes a seated participant, so the flow can be tried without photos.'**
  String get built4;

  /// No description provided for @inclusionDemoCta.
  ///
  /// In en, this message translates to:
  /// **'See the demo group'**
  String get inclusionDemoCta;

  /// No description provided for @inclusionNoteSample.
  ///
  /// In en, this message translates to:
  /// **'{renders} apparel renders of {people} people ({seated} seated). A small sample: read the numbers as indicative, not as a benchmark.'**
  String inclusionNoteSample(int renders, int people, int seated);

  /// No description provided for @inclusionNoteDocs.
  ///
  /// In en, this message translates to:
  /// **'The YouCam AI Clothes documentation asks for a person standing (no sitting or crouching); this evaluation measures what that means for seated participants.'**
  String get inclusionNoteDocs;

  /// No description provided for @inclusionNoteApplied.
  ///
  /// In en, this message translates to:
  /// **'\"Applied\" counts renders a human reviewer did not reject; \"silent failures\" are renders returned without the garment.'**
  String get inclusionNoteApplied;

  /// No description provided for @personLookTitle.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get personLookTitle;

  /// No description provided for @personHarmonyTitle.
  ///
  /// In en, this message translates to:
  /// **'Next to the others'**
  String get personHarmonyTitle;

  /// No description provided for @personSelf.
  ///
  /// In en, this message translates to:
  /// **'Own {subject} and outfit'**
  String personSelf(Object subject);

  /// No description provided for @personOpenMyLook.
  ///
  /// In en, this message translates to:
  /// **'Open my look'**
  String get personOpenMyLook;

  /// No description provided for @dressCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dress code'**
  String get dressCodeTitle;

  /// No description provided for @dressCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick up to four colors for the group. Each outfit is checked against the nearest one.'**
  String get dressCodeHint;

  /// No description provided for @dressCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dress code yet.'**
  String get dressCodeEmpty;

  /// No description provided for @dressCodeOnCount.
  ///
  /// In en, this message translates to:
  /// **'{on} of {total} in the dress code'**
  String dressCodeOnCount(int on, int total);

  /// No description provided for @dressFitOn.
  ///
  /// In en, this message translates to:
  /// **'In the dress code'**
  String get dressFitOn;

  /// No description provided for @dressFitClose.
  ///
  /// In en, this message translates to:
  /// **'Close to the dress code'**
  String get dressFitClose;

  /// No description provided for @dressFitOff.
  ///
  /// In en, this message translates to:
  /// **'Outside the dress code'**
  String get dressFitOff;

  /// No description provided for @swatchBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get swatchBlack;

  /// No description provided for @swatchWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get swatchWhite;

  /// No description provided for @swatchIvory.
  ///
  /// In en, this message translates to:
  /// **'Ivory'**
  String get swatchIvory;

  /// No description provided for @swatchChampagne.
  ///
  /// In en, this message translates to:
  /// **'Champagne'**
  String get swatchChampagne;

  /// No description provided for @swatchGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get swatchGold;

  /// No description provided for @swatchSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get swatchSilver;

  /// No description provided for @swatchBlush.
  ///
  /// In en, this message translates to:
  /// **'Blush'**
  String get swatchBlush;

  /// No description provided for @swatchRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get swatchRose;

  /// No description provided for @swatchRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get swatchRed;

  /// No description provided for @swatchCrimson.
  ///
  /// In en, this message translates to:
  /// **'Crimson'**
  String get swatchCrimson;

  /// No description provided for @swatchBurgundy.
  ///
  /// In en, this message translates to:
  /// **'Burgundy'**
  String get swatchBurgundy;

  /// No description provided for @swatchLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get swatchLavender;

  /// No description provided for @swatchSky.
  ///
  /// In en, this message translates to:
  /// **'Sky blue'**
  String get swatchSky;

  /// No description provided for @swatchRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal blue'**
  String get swatchRoyal;

  /// No description provided for @swatchNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get swatchNavy;

  /// No description provided for @swatchTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get swatchTeal;

  /// No description provided for @swatchEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get swatchEmerald;

  /// No description provided for @swatchSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get swatchSage;

  /// No description provided for @swatchMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get swatchMustard;

  /// No description provided for @dressCodeFull.
  ///
  /// In en, this message translates to:
  /// **'Four colors chosen. Remove one to pick another.'**
  String get dressCodeFull;

  /// No description provided for @runwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Virtual Runway'**
  String get runwayTitle;

  /// No description provided for @runwaySolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get runwaySolo;

  /// No description provided for @runwayDuo.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get runwayDuo;

  /// No description provided for @runwayFinale.
  ///
  /// In en, this message translates to:
  /// **'Finale'**
  String get runwayFinale;

  /// No description provided for @runwayPlay.
  ///
  /// In en, this message translates to:
  /// **'Auto-walk'**
  String get runwayPlay;

  /// No description provided for @runwayPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get runwayPause;

  /// No description provided for @runwayFixNow.
  ///
  /// In en, this message translates to:
  /// **'Fix on stage'**
  String get runwayFixNow;

  /// No description provided for @moodboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Moodboard'**
  String get moodboardTitle;

  /// No description provided for @moodboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the group\'s color chords, swatches and color temperature.'**
  String get moodboardSubtitle;

  /// No description provided for @moodboardExport.
  ///
  /// In en, this message translates to:
  /// **'Export palette'**
  String get moodboardExport;

  /// No description provided for @moodboardWheelTitle.
  ///
  /// In en, this message translates to:
  /// **'Chromatic Harmony Wheel'**
  String get moodboardWheelTitle;

  /// No description provided for @moodboardWheelHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a node to inspect that person\'s exact CIELAB colors and harmony pairings.'**
  String get moodboardWheelHint;

  /// No description provided for @moodboardInspectTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Inspector'**
  String get moodboardInspectTitle;

  /// No description provided for @moodboardInspectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a person on the wheel above to examine their extracted shade and pairwise relations.'**
  String get moodboardInspectHint;

  /// No description provided for @moodboardPairRelations.
  ///
  /// In en, this message translates to:
  /// **'Harmony pairings'**
  String get moodboardPairRelations;

  /// No description provided for @moodboardPaletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Color Palette'**
  String get moodboardPaletteTitle;

  /// No description provided for @moodboardNoSwatches.
  ///
  /// In en, this message translates to:
  /// **'No garments selected yet.'**
  String get moodboardNoSwatches;

  /// No description provided for @moodboardVibeTitle.
  ///
  /// In en, this message translates to:
  /// **'Aesthetic & Cohesion Vibe'**
  String get moodboardVibeTitle;

  /// No description provided for @moodboardCohesionScore.
  ///
  /// In en, this message translates to:
  /// **'Group harmony (weakest pair)'**
  String get moodboardCohesionScore;

  /// No description provided for @moodboardCohesionHigh.
  ///
  /// In en, this message translates to:
  /// **'Excellent color cohesion across the whole group.'**
  String get moodboardCohesionHigh;

  /// No description provided for @moodboardCohesionMed.
  ///
  /// In en, this message translates to:
  /// **'Good color coordination with minor contrast variations.'**
  String get moodboardCohesionMed;

  /// No description provided for @moodboardCohesionLow.
  ///
  /// In en, this message translates to:
  /// **'Notable near-miss color clashes to adjust.'**
  String get moodboardCohesionLow;

  /// No description provided for @moodboardTempBalance.
  ///
  /// In en, this message translates to:
  /// **'Color Temperature Balance'**
  String get moodboardTempBalance;

  /// No description provided for @moodboardWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm (Reds / Roses / Golds)'**
  String get moodboardWarm;

  /// No description provided for @moodboardCool.
  ///
  /// In en, this message translates to:
  /// **'Cool (Blues / Teals / Greens)'**
  String get moodboardCool;

  /// No description provided for @lookbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Lookbook'**
  String get lookbookTitle;

  /// No description provided for @lookbookExportSpread.
  ///
  /// In en, this message translates to:
  /// **'Export spread as image'**
  String get lookbookExportSpread;

  /// No description provided for @lookbookSpreadCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get lookbookSpreadCover;

  /// No description provided for @lookbookSpreadPairs.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get lookbookSpreadPairs;

  /// No description provided for @lookbookSpreadCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get lookbookSpreadCollection;

  /// No description provided for @lookbookSpreadStory.
  ///
  /// In en, this message translates to:
  /// **'Color Story'**
  String get lookbookSpreadStory;

  /// No description provided for @showcaseDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive Showcase'**
  String get showcaseDeckTitle;

  /// No description provided for @showcaseDeckRunway.
  ///
  /// In en, this message translates to:
  /// **'3D Runway'**
  String get showcaseDeckRunway;

  /// No description provided for @showcaseDeckRunwayHint.
  ///
  /// In en, this message translates to:
  /// **'Catwalk fashion show with stage lights & live fixes'**
  String get showcaseDeckRunwayHint;

  /// No description provided for @showcaseDeckFrame.
  ///
  /// In en, this message translates to:
  /// **'Group Photo'**
  String get showcaseDeckFrame;

  /// No description provided for @showcaseDeckFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone together on a painted backdrop'**
  String get showcaseDeckFrameHint;

  /// No description provided for @showcaseDeckMoodboard.
  ///
  /// In en, this message translates to:
  /// **'Moodboard'**
  String get showcaseDeckMoodboard;

  /// No description provided for @showcaseDeckMoodboardHint.
  ///
  /// In en, this message translates to:
  /// **'Color wheel and swatch palette'**
  String get showcaseDeckMoodboardHint;

  /// No description provided for @showcaseDeckLookbook.
  ///
  /// In en, this message translates to:
  /// **'Lookbook'**
  String get showcaseDeckLookbook;

  /// No description provided for @showcaseDeckLookbookHint.
  ///
  /// In en, this message translates to:
  /// **'Glossy editorial fashion magazine spread'**
  String get showcaseDeckLookbookHint;

  /// No description provided for @lookbookSeal.
  ///
  /// In en, this message translates to:
  /// **'Harmony'**
  String get lookbookSeal;

  /// No description provided for @lookbookPairsHint.
  ///
  /// In en, this message translates to:
  /// **'Colors chosen so no two looks clash side by side.'**
  String get lookbookPairsHint;

  /// No description provided for @lookbookPairNote.
  ///
  /// In en, this message translates to:
  /// **'Compared with CIEDE2000, the same color math as the harmony check.'**
  String get lookbookPairNote;

  /// No description provided for @lookbookCollectionHint.
  ///
  /// In en, this message translates to:
  /// **'Every outfit, lip color and hair color, with prices.'**
  String get lookbookCollectionHint;

  /// No description provided for @lookbookStoryHint.
  ///
  /// In en, this message translates to:
  /// **'The group\'s palette, and who Wearmony is built for.'**
  String get lookbookStoryHint;

  /// No description provided for @lookbookChords.
  ///
  /// In en, this message translates to:
  /// **'Event colors'**
  String get lookbookChords;

  /// No description provided for @lookbookInclusionTitle.
  ///
  /// In en, this message translates to:
  /// **'Made for everyone'**
  String get lookbookInclusionTitle;

  /// No description provided for @lookbookInclusionBody.
  ///
  /// In en, this message translates to:
  /// **'Virtual try-on is usually tested on standing models. Wearmony retries seated photos with upper-body framing and measures how well they work before publishing any number.'**
  String get lookbookInclusionBody;

  /// No description provided for @lookbookMasthead.
  ///
  /// In en, this message translates to:
  /// **'The harmony issue · Vol. I'**
  String get lookbookMasthead;

  /// No description provided for @lookbookIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue {year}'**
  String lookbookIssue(String year);
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
