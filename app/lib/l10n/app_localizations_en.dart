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
  String get openDemo => 'Prom demo';

  @override
  String get demoHint =>
      'Ready-made events with illustrated people: a prom and a school play. No photos needed.';

  @override
  String get yourEvents => 'Your events';

  @override
  String get organizerRole => 'Organizer';

  @override
  String get participantRole => 'Participant';

  @override
  String get inclusionLink => 'Inclusion results: standing vs seated';

  @override
  String get language => 'Language';

  @override
  String get apiStatusMock => 'Try-on: simulated (mock mode)';

  @override
  String get apiStatusLive => 'Try-on: live YouCam API';

  @override
  String get apiStatusOffline => 'Can\'t reach Wearmony';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get continueLabel => 'Continue';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorOffline =>
      'Can\'t reach Wearmony. Check your connection and try again.';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get none => 'None';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInExplain =>
      'Sign in with your email to create or join events.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signUpButton => 'Create account';

  @override
  String get checkEmail =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get createEventTitle => 'New event';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get templateLabel => 'Template';

  @override
  String get templateProm => 'Prom';

  @override
  String get templateTheatre => 'Theatre cast';

  @override
  String get templateGroup => 'Group photo';

  @override
  String get templatePromHint =>
      'Couples and friends coordinating for the prom.';

  @override
  String get templateTheatreHint => 'A cast trying costumes together.';

  @override
  String get templateGroupHint => 'Weddings, family photos, any group.';

  @override
  String get budgetPerPersonLabel => 'Budget per person (optional)';

  @override
  String get budgetTotalLabel => 'Total budget (optional)';

  @override
  String get amountsInEuro => 'Amounts in euro.';

  @override
  String get createEventButton => 'Create event';

  @override
  String get joinTitle => 'Join an event';

  @override
  String get joinCodeLabel => 'Event code';

  @override
  String get yourNameLabel => 'Your name, as the group will see it';

  @override
  String get joinButton => 'Join';

  @override
  String joiningEvent(Object name) {
    return 'You are joining $name.';
  }

  @override
  String get codeNotFound => 'No event uses this code.';

  @override
  String get tabBoard => 'Group';

  @override
  String get tabMyLook => 'My look';

  @override
  String get tabTogether => 'Together';

  @override
  String get tabCatalogue => 'Catalogue';

  @override
  String get tabHarmony => 'Harmony';

  @override
  String get tabInvite => 'Invite';

  @override
  String get tabSettings => 'Settings';

  @override
  String get demoBanner =>
      'Demo event: the people and renders are illustrations, not real photos.';

  @override
  String get mockBanner =>
      'Mock mode: try-on results are simulated, no YouCam calls are made.';

  @override
  String get consentTitle => 'Before you add a photo';

  @override
  String get consentAdult => 'I am 18 or older.';

  @override
  String get consentPrivate =>
      'My photo is visible only to people in this event and to vendors I choose to share it with.';

  @override
  String get consentDelete =>
      'I can delete my photo and every render at any time.';

  @override
  String get consentPreview =>
      'Try-on is a visual preview, not a fit guarantee.';

  @override
  String get consentButton => 'I agree';

  @override
  String get photoTitle => 'Your photo';

  @override
  String get photoTipsTitle => 'For the best result';

  @override
  String get photoTipLight => 'Even, bright light.';

  @override
  String get photoTipFrame =>
      'Face and shoulders fully visible; include as much of your outfit area as you can.';

  @override
  String get photoTipAlone => 'Only you in the photo.';

  @override
  String get photoTipClothes =>
      'Lighter, fitted clothing works better than dark or bulky clothes.';

  @override
  String get poseQuestion => 'In this photo I am';

  @override
  String get poseStanding => 'Standing';

  @override
  String get poseSeated => 'Seated';

  @override
  String get poseSeatedNote =>
      'Seated photos are welcome. If a full-length outfit does not apply, Wearmony retries with upper-body framing automatically.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get checkingPhoto => 'Checking your photo…';

  @override
  String get photoReady => 'Your photo is ready.';

  @override
  String get replacePhoto => 'Replace photo';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get photoNextStep => 'Next: pick your look';

  @override
  String get issue_too_small =>
      'The photo is too small. Use a larger, sharper photo.';

  @override
  String get issue_unusual_ratio =>
      'The photo is very tall or very wide. Use a normal portrait photo.';

  @override
  String get issue_too_dark => 'The photo is quite dark; try brighter light.';

  @override
  String get issue_too_bright => 'The photo is very bright; try softer light.';

  @override
  String get issue_low_contrast => 'The photo looks flat or washed out.';

  @override
  String get warning_dark_clothing =>
      'Dark clothing on the photo can stop the outfit from applying. A photo in lighter clothing works better.';

  @override
  String get sectionOutfit => 'Outfit';

  @override
  String get sectionMakeup => 'Lip color';

  @override
  String get sectionHair => 'Hair color';

  @override
  String get catalogueEmpty => 'The organizer has not added items yet.';

  @override
  String lookTotal(Object amount) {
    return 'Total $amount';
  }

  @override
  String get tryOnButton => 'Try it on';

  @override
  String get kindApparel => 'outfit';

  @override
  String get kindMakeup => 'lip color';

  @override
  String get kindHair => 'hair color';

  @override
  String renderRunning(Object kind) {
    return 'Trying on the $kind…';
  }

  @override
  String get renderIdle =>
      'Press \"Try it on\" to see this look on your photo.';

  @override
  String get renderNoPhoto => 'Add your photo to try looks on.';

  @override
  String get addPhoto => 'Add my photo';

  @override
  String get renderEmpty => 'Pick an outfit, a lip color or a hair color.';

  @override
  String get renderFailed => 'Try-on did not work';

  @override
  String get mockBadge => 'Simulated result (mock mode, no YouCam call)';

  @override
  String get demoRenderBadge => 'Illustration (demo data), not a real render';

  @override
  String get previewDisclaimer => 'Visual preview, not a fit guarantee.';

  @override
  String get checkNotApplied =>
      'The outfit may not have been applied to this photo. A photo in lighter, fitted clothing usually helps.';

  @override
  String get checkDrift =>
      'Check this render: its colors differ from the catalogue photo.';

  @override
  String get failure_garment_not_applied =>
      'The outfit was not applied to the photo. This often happens when the clothing on the photo is dark or bulky; try a photo in lighter, fitted clothing.';

  @override
  String get failure_pose_not_supported =>
      'The try-on engine could not read the pose in this photo. Use a photo where your shoulders and upper body are clearly visible.';

  @override
  String get failure_face_not_found =>
      'No face was found. Use a photo with your face fully visible, facing the camera.';

  @override
  String get failure_multiple_people =>
      'More than one person is in the photo. Use a photo of just you.';

  @override
  String get failure_image_invalid =>
      'This photo or item image cannot be used. Try a different one.';

  @override
  String get failure_content_rejected =>
      'The try-on engine rejected this image.';

  @override
  String get failure_budget_exhausted =>
      'The render budget is used up. Your look is saved, and the organizer can raise the budget.';

  @override
  String get failure_provider_error => 'The try-on service had a problem.';

  @override
  String get failure_timeout => 'The try-on took too long.';

  @override
  String get lockLook => 'Lock my look';

  @override
  String get unlockLook => 'Unlock';

  @override
  String get lockedNote => 'Locked: this is your final look.';

  @override
  String get shareHair => 'Share hair color with my hairdresser';

  @override
  String get shareLook => 'Share my look with a shop';

  @override
  String shareLinkReady(Object date) {
    return 'Read-only link, valid until $date:';
  }

  @override
  String get copyLink => 'Copy link';

  @override
  String get myData => 'My data';

  @override
  String get togetherNoPartner =>
      'Choose your partner to see yourselves side by side.';

  @override
  String get partnerLabel => 'Partner';

  @override
  String get noPartner => 'No partner';

  @override
  String youAndPartner(Object name) {
    return 'You and $name';
  }

  @override
  String get you => 'You';

  @override
  String boardRendered(Object rendered, Object total) {
    return '$rendered of $total rendered';
  }

  @override
  String boardLocked(Object locked) {
    return '$locked locked';
  }

  @override
  String get budgetTitle => 'Budget';

  @override
  String budgetOfCap(Object cap) {
    return 'of $cap';
  }

  @override
  String budgetPerPersonCap(Object amount) {
    return 'Up to $amount per person';
  }

  @override
  String get overBudget => 'Over budget';

  @override
  String overBudgetCount(Object count) {
    return '$count over the per-person budget';
  }

  @override
  String unitsUsed(Object cap, Object used) {
    return 'Try-on units used: $used of $cap';
  }

  @override
  String get unitsSimulated => 'Renders here are simulated and use no units.';

  @override
  String get noLookYet => 'No look yet';

  @override
  String get noPhotoYet => 'No photo yet';

  @override
  String withPartner(Object name) {
    return 'with $name';
  }

  @override
  String get seatedLabel => 'Seated';

  @override
  String get lockedLabel => 'Locked';

  @override
  String groupHarmony(Object score) {
    return 'Group harmony $score/100';
  }

  @override
  String addPeopleHint(Object code) {
    return 'Invite people with the code $code.';
  }

  @override
  String get harmonyTitle => 'Color harmony';

  @override
  String get harmonyWeakest => 'Weakest pair';

  @override
  String get harmonyNoData =>
      'Add outfits to see how the group\'s colors work together.';

  @override
  String get harmonyNoWarnings =>
      'No near-miss colors. The group reads as intentional.';

  @override
  String get harmonyWarnings => 'Warnings';

  @override
  String get harmonyAll => 'All comparisons';

  @override
  String harmonyWithoutOutfit(Object names) {
    return 'No outfit yet: $names';
  }

  @override
  String get relationMatched => 'Matched';

  @override
  String get relationNearMiss => 'Near-miss';

  @override
  String get relationComplementary => 'Complementary';

  @override
  String get relationContrast => 'Contrast';

  @override
  String pairMatched(Object a, Object b, Object color) {
    return '$a and $b match: both wear $color.';
  }

  @override
  String pairNearMiss(
    Object a,
    Object b,
    Object colorA,
    Object colorB,
    Object de,
  ) {
    return '$a\'s $colorA and $b\'s $colorB are close but not the same shade (ΔE $de). Side by side this can look like a mistake: match them exactly or pick clearly different colors.';
  }

  @override
  String pairComplementary(Object a, Object b, Object colorA, Object colorB) {
    return '$a\'s $colorA and $b\'s $colorB are complementary colors that set each other off.';
  }

  @override
  String pairContrast(Object a, Object b, Object colorA, Object colorB) {
    return '$a\'s $colorA and $b\'s $colorB are clearly different, which reads as intentional.';
  }

  @override
  String selfMatched(Object a, Object color, Object subject) {
    return '$a\'s $subject matches the $color outfit.';
  }

  @override
  String selfNearMiss(
    Object a,
    Object colorA,
    Object colorB,
    Object de,
    Object subject,
  ) {
    return '$a\'s $colorA $subject is close to, but not the same as, the $colorB outfit (ΔE $de). Match it or choose a clearly different shade.';
  }

  @override
  String selfComplementary(
    Object a,
    Object colorA,
    Object colorB,
    Object subject,
  ) {
    return '$a\'s $colorA $subject is complementary to the $colorB outfit.';
  }

  @override
  String selfContrast(Object a, Object colorA, Object colorB, Object subject) {
    return '$a\'s $colorA $subject stands apart from the $colorB outfit, which reads as intentional.';
  }

  @override
  String get subjectLips => 'lip color';

  @override
  String get subjectHair => 'hair color';

  @override
  String get explainButton => 'Explain in plain words';

  @override
  String get explainNote =>
      'Written by Gemini from the results above. Scores come only from the color rules.';

  @override
  String get harmonyMethodTitle => 'How it works';

  @override
  String get harmonyMethod =>
      'Garment colors come from the catalogue photos (background removed, k-means clustering in CIELAB). Every pair is compared with CIEDE2000: under 2 is a match, 2 to 8 is a near-miss that can look like a mistake, and opposite hues are complementary. Lip and hair colors are compared with the same person\'s outfit. The group score is the weakest pair, not an average. Harmony is about colors only, never about bodies or skin.';

  @override
  String get colorBlack => 'black';

  @override
  String get colorWhite => 'white';

  @override
  String get colorGray => 'gray';

  @override
  String get colorBeige => 'beige';

  @override
  String get colorBrown => 'brown';

  @override
  String get colorRed => 'red';

  @override
  String get colorBurgundy => 'burgundy';

  @override
  String get colorPink => 'pink';

  @override
  String get colorOrange => 'orange';

  @override
  String get colorYellow => 'yellow';

  @override
  String get colorOlive => 'olive';

  @override
  String get colorGreen => 'green';

  @override
  String get colorTeal => 'teal';

  @override
  String get colorBlue => 'blue';

  @override
  String get colorNavy => 'navy';

  @override
  String get colorPurple => 'purple';

  @override
  String get colorLavender => 'lavender';

  @override
  String get colorMagenta => 'magenta';

  @override
  String colorLight(Object color) {
    return 'light $color';
  }

  @override
  String colorDark(Object color) {
    return 'dark $color';
  }

  @override
  String colorMuted(Object color) {
    return 'muted $color';
  }

  @override
  String get catalogueTitle => 'Catalogue';

  @override
  String get addGarment => 'Add outfit';

  @override
  String get addMakeup => 'Add lip color';

  @override
  String get addHair => 'Add hair color';

  @override
  String get itemName => 'Name';

  @override
  String get itemPrice => 'Price';

  @override
  String get itemCategory => 'Type';

  @override
  String get categoryFullBody => 'Full outfit';

  @override
  String get categoryUpperBody => 'Top';

  @override
  String get categoryLowerBody => 'Bottom';

  @override
  String get categoryOuter => 'Jacket or outerwear';

  @override
  String get itemColor => 'Color';

  @override
  String get chooseItemPhoto => 'Choose product photo';

  @override
  String get itemPhotoHint =>
      'A front-facing product photo of one garment on a plain background works best.';

  @override
  String get itemNeedsPhoto =>
      'Add a product photo so the outfit can be tried on.';

  @override
  String addedBy(Object vendor) {
    return 'Added by $vendor';
  }

  @override
  String get colorsFound => 'Colors found';

  @override
  String deleteItemConfirm(Object name) {
    return 'Delete $name? Looks that use it lose this item.';
  }

  @override
  String get inviteTitle => 'Invite people';

  @override
  String get inviteCode => 'Event code';

  @override
  String get inviteLinkLabel => 'Invite link';

  @override
  String get inviteQrHint => 'Scan to join';

  @override
  String get vendorLinksTitle => 'Vendors';

  @override
  String get vendorCatalogueExplain =>
      'Let a shop or costume keeper add items to this catalogue, without an account.';

  @override
  String get vendorNameLabel => 'Vendor name (optional)';

  @override
  String get createLink => 'Create link';

  @override
  String get settingsTitle => 'Event settings';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saved => 'Saved';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String deleteEventConfirm(Object name) {
    return 'Delete $name with all photos, renders and links? This cannot be undone.';
  }

  @override
  String get participantsTitle => 'Participants';

  @override
  String removeParticipantConfirm(Object name) {
    return 'Remove $name and delete their photo and renders?';
  }

  @override
  String get myDataTitle => 'My data';

  @override
  String get myDataExplain =>
      'Your photo and renders are stored only for this event. Photos are resized and stripped of location data before anything is sent to the try-on engine.';

  @override
  String get deletePhotoConfirm =>
      'Delete your photo and every render made from it?';

  @override
  String get leaveEvent => 'Leave this event and delete my data';

  @override
  String leaveEventConfirm(Object name) {
    return 'Leave $name? Your photo, look and renders are deleted.';
  }

  @override
  String get deleteEverywhere => 'Delete my data in all events';

  @override
  String get deleteEverywhereConfirm =>
      'Leave every event you joined and delete all your photos, looks and renders?';

  @override
  String get deletedDone => 'Deleted.';

  @override
  String get vendorTitle => 'Shared look';

  @override
  String get vendorReadOnly => 'This page is read-only and the link expires.';

  @override
  String vendorFor(Object event, Object name) {
    return 'From $name for $event';
  }

  @override
  String get vendorBefore => 'Before';

  @override
  String get vendorAfter => 'Preview';

  @override
  String vendorExpires(Object date) {
    return 'Link valid until $date';
  }

  @override
  String get vendorExpired => 'This link has expired.';

  @override
  String get vendorNotFound => 'This link does not exist or was revoked.';

  @override
  String vendorCatalogueTitle(Object event) {
    return 'Add items to $event';
  }

  @override
  String get vendorAddItem => 'Add item';

  @override
  String get vendorItemsInEvent => 'Items in this catalogue';

  @override
  String get inclusionTitle => 'Inclusion: standing vs seated';

  @override
  String get inclusionIntro =>
      'Virtual try-on is usually tested on standing models. We measure how Wearmony works for seated people, such as wheelchair users, and publish the numbers as they are.';

  @override
  String get inclusionNotMeasured => 'No measurements yet.';

  @override
  String inclusionEngine(Object engine) {
    return 'Engine: $engine';
  }

  @override
  String inclusionMeasuredAt(Object date) {
    return 'Measured $date';
  }

  @override
  String get colPose => 'Pose';

  @override
  String get colFraming => 'Framing';

  @override
  String get colRuns => 'Runs';

  @override
  String get colApplied => 'Applied';

  @override
  String get colSilent => 'Silent failures';

  @override
  String get colErrors => 'Errors';

  @override
  String get colFaceChanged => 'Face changed';

  @override
  String get colMedianTime => 'Median time';

  @override
  String get framingAsCatalogued => 'As catalogued';

  @override
  String get framingUpperBody => 'Upper-body fallback';

  @override
  String get notReviewed => 'not reviewed';

  @override
  String get heroEyebrow => 'Group virtual try-on for events';

  @override
  String get featureTryOnTitle => 'Try it on, together';

  @override
  String get featureTryOnBody =>
      'Outfit, lip color and hair color on your own photo, then everyone side by side.';

  @override
  String get featureHarmonyTitle => 'Color harmony';

  @override
  String get featureHarmonyBody =>
      'Spots almost-matching colors before the night, explained in one sentence.';

  @override
  String get featureBudgetTitle => 'Shared budget';

  @override
  String get featureBudgetBody =>
      'Per-person and group totals, so nobody is surprised.';

  @override
  String get featureInclusiveTitle => 'Made for everyone';

  @override
  String get featureInclusiveBody =>
      'Seated photos are supported, and how well they work is measured.';

  @override
  String get statRendered => 'Rendered';

  @override
  String get statLocked => 'Locked looks';

  @override
  String get statHarmony => 'Harmony';

  @override
  String get statBudget => 'Group total';

  @override
  String get yourLook => 'Your look';

  @override
  String get selected => 'Selected';

  @override
  String get stepsTitle => 'Try-on steps';

  @override
  String get badgeIllustration => 'Illustration';

  @override
  String get badgeSimulated => 'Simulated';

  @override
  String get notFoundTitle => 'This page does not exist';

  @override
  String get notFoundBody => 'The link may be old or mistyped.';

  @override
  String get goHome => 'Back to Wearmony';

  @override
  String get howItWorks => 'How it works';

  @override
  String get step1Title => 'Invite the group';

  @override
  String get step1Body =>
      'Create the event and share a code, a link or a QR code.';

  @override
  String get step2Title => 'Everyone tries on';

  @override
  String get step2Body =>
      'Each person adds one photo and tries outfits, lip colors and hair colors.';

  @override
  String get step3Title => 'See the group in harmony';

  @override
  String get step3Body =>
      'Spot almost-matching colors and stay within the shared budget, before anyone buys.';

  @override
  String get clashFixed => 'Clash fixed: the group’s colors work together now.';

  @override
  String get harmonyMapTitle => 'Harmony map';

  @override
  String get harmonyMapHint =>
      'Each line compares two outfits. Point at or tap a person to see only their pairs. Small dots are hair and lip colors.';

  @override
  String get fixTitle => 'How to fix it';

  @override
  String get fixSubtitle =>
      'Swaps from this event\'s catalogue that remove the near-miss, checked with the same color math. No model opinions.';

  @override
  String get fixNone =>
      'No item in the catalogue fixes this yet. Add one in the same shade or in a clearly different color.';

  @override
  String fixWith(Object name, Object relation) {
    return '$relation with $name';
  }

  @override
  String fixWithOutfit(Object relation) {
    return '$relation with the outfit';
  }

  @override
  String get fixScore => 'Group harmony';

  @override
  String get fixSamePrice => 'Same price';

  @override
  String get fixOverBudget => 'Over the per-person budget';

  @override
  String get fixApply => 'Switch to this';

  @override
  String get fixApplied => 'Look updated. The harmony check already uses it.';

  @override
  String get fixPreview => 'Preview';

  @override
  String get fixCopy => 'Copy suggestion';

  @override
  String get fixCopied => 'Suggestion copied';

  @override
  String fixShareText(Object item, Object name, Object other, Object relation) {
    return '$name, try $item instead: next to $other it reads as “$relation”, not a near-miss.';
  }

  @override
  String fixShareTextSelf(Object item, Object name, Object relation) {
    return '$name, try $item instead: with the outfit it reads as “$relation”, not a near-miss.';
  }

  @override
  String get frameOpen => 'Group photo';

  @override
  String get frameOpenHint =>
      'See everyone\'s current look in one frame and save it as an image.';

  @override
  String get frameTitle => 'Group photo';

  @override
  String get frameSubtitle =>
      'Everyone\'s current look in one frame. Partners stand together.';

  @override
  String get frameBackdrop => 'Backdrop';

  @override
  String get backdropBallroom => 'Ballroom';

  @override
  String get backdropStage => 'Stage';

  @override
  String get backdropGarden => 'Garden';

  @override
  String get backdropStudio => 'Studio';

  @override
  String get frameSave => 'Save image';

  @override
  String get frameShare => 'Share image';

  @override
  String get frameSaved => 'Image saved to your downloads.';

  @override
  String get frameSaveFailed => 'The image could not be created. Try again.';

  @override
  String get frameHint =>
      'The image keeps the labels that say what is simulated.';

  @override
  String get frameEmpty => 'No one has joined yet.';

  @override
  String frameHarmony(int score) {
    return 'Harmony $score/100';
  }

  @override
  String framePeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get frameHonestDemo => 'Illustrations, not real photos';

  @override
  String get frameHonestMock => 'Simulated try-on (mock mode)';

  @override
  String get frameHonestReal => 'Virtual try-on preview, not a fit guarantee';

  @override
  String frameShareText(Object event) {
    return 'Our looks for $event, made with Wearmony.';
  }

  @override
  String get readinessTitle => 'Getting ready';

  @override
  String get readinessPhoto => 'Photo';

  @override
  String get readinessLook => 'Look';

  @override
  String get readinessPreview => 'Preview';

  @override
  String get readinessLocked => 'Locked';

  @override
  String get nextPhoto => 'Needs a photo';

  @override
  String get nextLook => 'Choosing a look';

  @override
  String get nextPreview => 'No preview yet';

  @override
  String get nextLock => 'Can lock the look';

  @override
  String get nextDone => 'All set';

  @override
  String get reminderCopy => 'Copy a reminder';

  @override
  String reminderText(Object event, Object link) {
    return 'Please finish your look for $event on Wearmony: $link';
  }

  @override
  String get reminderCopied => 'Reminder copied. Paste it in your group chat.';

  @override
  String get eventDateLabel => 'Event date (optional)';

  @override
  String get eventDateNone => 'No date yet';

  @override
  String get eventDateClear => 'Clear the date';

  @override
  String get countdownToday => 'Today';

  @override
  String countdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String countdownPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get featureFixTitle => 'Fix it in one tap';

  @override
  String get featureFixBody =>
      'When two colors almost match, Wearmony finds catalogue swaps that fix it and shows what changes.';

  @override
  String get featureFrameTitle => 'One group photo';

  @override
  String get featureFrameBody =>
      'Everyone\'s current look in one frame, partners side by side, ready to share.';

  @override
  String fixOthersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other near-misses in the group stay',
      one: 'Another near-miss in the group stays',
    );
    return '$_temp0';
  }

  @override
  String fixWithYou(Object relation) {
    return '$relation with you';
  }

  @override
  String fixShareTextMe(Object item, Object name, Object relation) {
    return '$name, try $item instead: next to me it reads as “$relation”, not a near-miss.';
  }

  @override
  String harmonyMapSemantics(int people, int nearMisses) {
    String _temp0 = intl.Intl.pluralLogic(
      nearMisses,
      locale: localeName,
      other: '$nearMisses near-misses',
      one: 'one near-miss',
      zero: 'no near-misses',
    );
    return 'Harmony map of $people people with $_temp0.';
  }

  @override
  String frameSemantics(Object event, Object names) {
    return 'Group photo of $event: $names.';
  }

  @override
  String get openTheatreDemo => 'Theatre cast demo';
}
