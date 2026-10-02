// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'Wearmony';

  @override
  String get slogan => 'Пробвайте го заедно.';

  @override
  String get landingPitch =>
      'Вижте как изглеждате заедно, преди някой да купи тоалет: пробване, хармония на цветовете и общ бюджет на едно място.';

  @override
  String get organizeEvent => 'Организирай събитие';

  @override
  String get joinWithCode => 'Влез с код';

  @override
  String get openDemo => 'Отвори демо събитието';

  @override
  String get demoHint => 'Примерен бал с илюстрирани хора. Не са нужни снимки.';

  @override
  String get yourEvents => 'Твоите събития';

  @override
  String get organizerRole => 'Организатор';

  @override
  String get participantRole => 'Участник';

  @override
  String get inclusionLink => 'Достъпност: прави и седнали, измерено';

  @override
  String get language => 'Език';

  @override
  String get apiStatusMock => 'Пробване: симулирано (mock режим)';

  @override
  String get apiStatusLive => 'Пробване: YouCam API на живо';

  @override
  String get apiStatusOffline => 'Няма връзка с Wearmony';

  @override
  String get retry => 'Опитай отново';

  @override
  String get cancel => 'Отказ';

  @override
  String get save => 'Запази';

  @override
  String get delete => 'Изтрий';

  @override
  String get close => 'Затвори';

  @override
  String get continueLabel => 'Продължи';

  @override
  String get errorGeneric => 'Нещо се обърка. Опитай отново.';

  @override
  String get errorOffline =>
      'Няма връзка с Wearmony. Провери интернета и опитай отново.';

  @override
  String get linkCopied => 'Връзката е копирана';

  @override
  String get none => 'Без';

  @override
  String get signInTitle => 'Вход';

  @override
  String get signInExplain =>
      'Влез с имейл, за да създаваш събития или да се присъединяваш.';

  @override
  String get emailLabel => 'Имейл';

  @override
  String get passwordLabel => 'Парола';

  @override
  String get signInButton => 'Вход';

  @override
  String get signUpButton => 'Създай профил';

  @override
  String get checkEmail =>
      'Провери имейла си, за да потвърдиш профила, и после влез.';

  @override
  String get createEventTitle => 'Ново събитие';

  @override
  String get eventNameLabel => 'Име на събитието';

  @override
  String get templateLabel => 'Шаблон';

  @override
  String get templateProm => 'Бал';

  @override
  String get templateTheatre => 'Театрална трупа';

  @override
  String get templateGroup => 'Групова снимка';

  @override
  String get templatePromHint =>
      'Двойки и приятели, които съгласуват визии за бала.';

  @override
  String get templateTheatreHint =>
      'Актьорски състав, който пробва костюми заедно.';

  @override
  String get templateGroupHint => 'Сватби, семейни снимки, всяка група.';

  @override
  String get budgetPerPersonLabel => 'Бюджет на човек (по желание)';

  @override
  String get budgetTotalLabel => 'Общ бюджет (по желание)';

  @override
  String get amountsInEuro => 'Сумите са в евро.';

  @override
  String get createEventButton => 'Създай събитие';

  @override
  String get joinTitle => 'Влез в събитие';

  @override
  String get joinCodeLabel => 'Код на събитието';

  @override
  String get yourNameLabel => 'Твоето име, както ще го вижда групата';

  @override
  String get joinButton => 'Влез';

  @override
  String joiningEvent(Object name) {
    return 'Влизаш в „$name“.';
  }

  @override
  String get codeNotFound => 'Няма събитие с този код.';

  @override
  String get tabBoard => 'Групата';

  @override
  String get tabMyLook => 'Моята визия';

  @override
  String get tabTogether => 'Заедно';

  @override
  String get tabCatalogue => 'Каталог';

  @override
  String get tabHarmony => 'Хармония';

  @override
  String get tabInvite => 'Покани';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get demoBanner =>
      'Демо събитие: хората и резултатите са илюстрации, не истински снимки.';

  @override
  String get mockBanner =>
      'Mock режим: резултатите от пробването са симулирани, без извиквания към YouCam.';

  @override
  String get consentTitle => 'Преди да добавиш снимка';

  @override
  String get consentAdult => 'На 18 или повече години съм.';

  @override
  String get consentPrivate =>
      'Снимката ми се вижда само от хората в това събитие и от доставчиците, с които реша да я споделя.';

  @override
  String get consentDelete =>
      'Мога да изтрия снимката си и всички резултати по всяко време.';

  @override
  String get consentPreview =>
      'Пробването е визуален преглед, не гаранция за размера.';

  @override
  String get consentButton => 'Съгласен/на съм';

  @override
  String get photoTitle => 'Твоята снимка';

  @override
  String get photoTipsTitle => 'За най-добър резултат';

  @override
  String get photoTipLight => 'Равномерна, ярка светлина.';

  @override
  String get photoTipFrame =>
      'Лицето и раменете да се виждат изцяло; хвани колкото може повече от мястото за тоалета.';

  @override
  String get photoTipAlone => 'Само ти на снимката.';

  @override
  String get photoTipClothes =>
      'По-светли, прилепнали дрехи работят по-добре от тъмни или обемни.';

  @override
  String get poseQuestion => 'На тази снимка съм';

  @override
  String get poseStanding => 'Прав/а';

  @override
  String get poseSeated => 'Седнал/а';

  @override
  String get poseSeatedNote =>
      'Снимки в седнало положение са добре дошли. Ако тоалет в цял ръст не се приложи, Wearmony опитва автоматично с рамка за горната част на тялото.';

  @override
  String get takePhoto => 'Снимай';

  @override
  String get choosePhoto => 'Избери снимка';

  @override
  String get checkingPhoto => 'Проверяваме снимката…';

  @override
  String get photoReady => 'Снимката е готова.';

  @override
  String get replacePhoto => 'Смени снимката';

  @override
  String get deletePhoto => 'Изтрий снимката';

  @override
  String get photoNextStep => 'Напред: избери визия';

  @override
  String get issue_too_small =>
      'Снимката е твърде малка. Използвай по-голяма и по-ясна снимка.';

  @override
  String get issue_unusual_ratio =>
      'Снимката е много висока или много широка. Използвай нормална портретна снимка.';

  @override
  String get issue_too_dark =>
      'Снимката е доста тъмна; опитай с повече светлина.';

  @override
  String get issue_too_bright =>
      'Снимката е много светла; опитай с по-мека светлина.';

  @override
  String get issue_low_contrast => 'Снимката изглежда плоска или избледняла.';

  @override
  String get warning_dark_clothing =>
      'Тъмните дрехи на снимката могат да попречат тоалетът да се приложи. Снимка с по-светли дрехи работи по-добре.';

  @override
  String get sectionOutfit => 'Тоалет';

  @override
  String get sectionMakeup => 'Червило';

  @override
  String get sectionHair => 'Цвят на косата';

  @override
  String get catalogueEmpty => 'Организаторът още не е добавил артикули.';

  @override
  String lookTotal(Object amount) {
    return 'Общо $amount';
  }

  @override
  String get tryOnButton => 'Пробвай';

  @override
  String get kindApparel => 'тоалета';

  @override
  String get kindMakeup => 'червилото';

  @override
  String get kindHair => 'цвета на косата';

  @override
  String renderRunning(Object kind) {
    return 'Пробваме $kind…';
  }

  @override
  String get renderIdle =>
      'Натисни „Пробвай“, за да видиш визията на своята снимка.';

  @override
  String get renderNoPhoto => 'Добави снимка, за да пробваш визии.';

  @override
  String get addPhoto => 'Добави снимка';

  @override
  String get renderEmpty => 'Избери тоалет, червило или цвят на косата.';

  @override
  String get renderFailed => 'Пробването не успя';

  @override
  String get mockBadge =>
      'Симулиран резултат (mock режим, без извикване към YouCam)';

  @override
  String get demoRenderBadge => 'Илюстрация (демо данни), не истински резултат';

  @override
  String get previewDisclaimer => 'Визуален преглед, не гаранция за размера.';

  @override
  String get checkNotApplied =>
      'Тоалетът може да не се е приложил върху снимката. Обикновено помага снимка с по-светли, прилепнали дрехи.';

  @override
  String get checkDrift =>
      'Провери този резултат: цветовете му се различават от снимката в каталога.';

  @override
  String get failure_garment_not_applied =>
      'Тоалетът не беше приложен върху снимката. Това често се случва, когато дрехите на снимката са тъмни или обемни; опитай снимка с по-светли, прилепнали дрехи.';

  @override
  String get failure_pose_not_supported =>
      'Системата не разпозна позата на тази снимка. Използвай снимка, на която раменете и горната част на тялото се виждат ясно.';

  @override
  String get failure_face_not_found =>
      'Не е открито лице. Използвай снимка, на която лицето се вижда изцяло, обърнато към камерата.';

  @override
  String get failure_multiple_people =>
      'На снимката има повече от един човек. Използвай снимка само с теб.';

  @override
  String get failure_image_invalid =>
      'Тази снимка или снимка на артикул не може да се използва. Опитай с друга.';

  @override
  String get failure_content_rejected =>
      'Системата за пробване отказа това изображение.';

  @override
  String get failure_budget_exhausted =>
      'Бюджетът за пробвания е изчерпан. Визията ти е запазена, а организаторът може да увеличи бюджета.';

  @override
  String get failure_provider_error => 'Услугата за пробване имаше проблем.';

  @override
  String get failure_timeout => 'Пробването отне твърде дълго.';

  @override
  String get lockLook => 'Заключи визията';

  @override
  String get unlockLook => 'Отключи';

  @override
  String get lockedNote => 'Заключена: това е окончателната ти визия.';

  @override
  String get shareHair => 'Сподели цвета на косата с фризьора';

  @override
  String get shareLook => 'Сподели визията с магазин';

  @override
  String shareLinkReady(Object date) {
    return 'Връзка само за преглед, валидна до $date:';
  }

  @override
  String get copyLink => 'Копирай връзката';

  @override
  String get myData => 'Моите данни';

  @override
  String get togetherNoPartner =>
      'Избери партньора си, за да се видите един до друг.';

  @override
  String get partnerLabel => 'Партньор';

  @override
  String get noPartner => 'Без партньор';

  @override
  String youAndPartner(Object name) {
    return 'Ти и $name';
  }

  @override
  String get you => 'Ти';

  @override
  String boardRendered(Object rendered, Object total) {
    return '$rendered от $total са пробвали';
  }

  @override
  String boardLocked(Object locked) {
    return '$locked заключени';
  }

  @override
  String get budgetTitle => 'Бюджет';

  @override
  String budgetTotalOf(Object cap, Object total) {
    return '$total от $cap';
  }

  @override
  String budgetPerPersonCap(Object amount) {
    return 'До $amount на човек';
  }

  @override
  String get overBudget => 'Над бюджета';

  @override
  String overBudgetCount(Object count) {
    return '$count над бюджета на човек';
  }

  @override
  String unitsUsed(Object cap, Object used) {
    return 'Използвани единици за пробване: $used от $cap';
  }

  @override
  String get unitsSimulated =>
      'Резултатите тук са симулирани и не харчат единици.';

  @override
  String get noLookYet => 'Още няма визия';

  @override
  String get noPhotoYet => 'Още няма снимка';

  @override
  String withPartner(Object name) {
    return 'с $name';
  }

  @override
  String get seatedLabel => 'Седнал/а';

  @override
  String get lockedLabel => 'Заключена';

  @override
  String groupHarmony(Object score) {
    return 'Хармония на групата $score/100';
  }

  @override
  String addPeopleHint(Object code) {
    return 'Покани хора с кода $code.';
  }

  @override
  String get harmonyTitle => 'Хармония на цветовете';

  @override
  String get harmonyWeakest => 'Най-слабата двойка';

  @override
  String get harmonyNoData =>
      'Добавете тоалети, за да видите как си пасват цветовете на групата.';

  @override
  String get harmonyNoWarnings =>
      'Няма почти еднакви цветове. Групата изглежда съгласувана.';

  @override
  String get harmonyWarnings => 'Предупреждения';

  @override
  String get harmonyAll => 'Всички сравнения';

  @override
  String harmonyWithoutOutfit(Object names) {
    return 'Още без тоалет: $names';
  }

  @override
  String get relationMatched => 'Съвпадат';

  @override
  String get relationNearMiss => 'Почти еднакви';

  @override
  String get relationComplementary => 'Допълващи се';

  @override
  String get relationContrast => 'Контраст';

  @override
  String pairMatched(Object a, Object b, Object color) {
    return '$a и $b си пасват: и двамата са в $color.';
  }

  @override
  String pairNearMiss(
    Object a,
    Object b,
    Object colorA,
    Object colorB,
    Object de,
  ) {
    return '$a ($colorA) и $b ($colorB) са с близки, но не еднакви нюанси (ΔE $de). Едно до друго това може да изглежда като грешка: изберете точно същия цвят или ясно различен.';
  }

  @override
  String pairComplementary(Object a, Object b, Object colorA, Object colorB) {
    return '$a ($colorA) и $b ($colorB) са с допълващи се цветове, които се подчертават взаимно.';
  }

  @override
  String pairContrast(Object a, Object b, Object colorA, Object colorB) {
    return '$a ($colorA) и $b ($colorB) са с ясно различни цветове, което изглежда нарочно.';
  }

  @override
  String selfMatched(Object a, Object color, Object subject) {
    return 'При $a $subject съвпада с тоалета ($color).';
  }

  @override
  String selfNearMiss(
    Object a,
    Object colorA,
    Object colorB,
    Object de,
    Object subject,
  ) {
    return 'При $a $subject ($colorA) е близък, но не същият като тоалета ($colorB, ΔE $de). Изберете точно същия нюанс или ясно различен.';
  }

  @override
  String selfComplementary(
    Object a,
    Object colorA,
    Object colorB,
    Object subject,
  ) {
    return 'При $a $subject ($colorA) допълва тоалета ($colorB).';
  }

  @override
  String selfContrast(Object a, Object colorA, Object colorB, Object subject) {
    return 'При $a $subject ($colorA) се отличава ясно от тоалета ($colorB), което изглежда нарочно.';
  }

  @override
  String get subjectLips => 'цветът на червилото';

  @override
  String get subjectHair => 'цветът на косата';

  @override
  String get explainButton => 'Обясни с прости думи';

  @override
  String get explainNote =>
      'Написано от Gemini въз основа на резултатите по-горе. Оценките идват само от правилата за цветове.';

  @override
  String get harmonyMethodTitle => 'Как работи';

  @override
  String get harmonyMethod =>
      'Цветовете на дрехите се извличат от снимките в каталога (фонът се премахва, k-means групиране в CIELAB). Всяка двойка се сравнява с CIEDE2000: под 2 е съвпадение, от 2 до 8 е почти еднакво и може да изглежда като грешка, а противоположните нюанси са допълващи се. Червилото и цветът на косата се сравняват с тоалета на същия човек. Оценката на групата е тази на най-слабата двойка, не средна стойност. Хармонията е само за цветове, никога за тела или кожа.';

  @override
  String get colorBlack => 'черно';

  @override
  String get colorWhite => 'бяло';

  @override
  String get colorGray => 'сиво';

  @override
  String get colorBeige => 'бежово';

  @override
  String get colorBrown => 'кафяво';

  @override
  String get colorRed => 'червено';

  @override
  String get colorBurgundy => 'бордо';

  @override
  String get colorPink => 'розово';

  @override
  String get colorOrange => 'оранжево';

  @override
  String get colorYellow => 'жълто';

  @override
  String get colorOlive => 'маслинено';

  @override
  String get colorGreen => 'зелено';

  @override
  String get colorTeal => 'синьо-зелено';

  @override
  String get colorBlue => 'синьо';

  @override
  String get colorNavy => 'тъмносиньо';

  @override
  String get colorPurple => 'лилаво';

  @override
  String get colorLavender => 'лавандулово';

  @override
  String get colorMagenta => 'фуксия';

  @override
  String colorLight(Object color) {
    return 'светло$color';
  }

  @override
  String colorDark(Object color) {
    return 'тъмно$color';
  }

  @override
  String colorMuted(Object color) {
    return 'приглушено $color';
  }

  @override
  String get catalogueTitle => 'Каталог';

  @override
  String get addGarment => 'Добави тоалет';

  @override
  String get addMakeup => 'Добави червило';

  @override
  String get addHair => 'Добави цвят на косата';

  @override
  String get itemName => 'Име';

  @override
  String get itemPrice => 'Цена';

  @override
  String get itemCategory => 'Вид';

  @override
  String get categoryFullBody => 'Цял тоалет';

  @override
  String get categoryUpperBody => 'Горна част';

  @override
  String get categoryLowerBody => 'Долна част';

  @override
  String get categoryOuter => 'Сако или горна дреха';

  @override
  String get itemColor => 'Цвят';

  @override
  String get chooseItemPhoto => 'Избери снимка на продукта';

  @override
  String get itemPhotoHint =>
      'Най-добре работи снимка отпред на една дреха върху еднороден фон.';

  @override
  String get itemNeedsPhoto =>
      'Добави снимка на продукта, за да може тоалетът да се пробва.';

  @override
  String addedBy(Object vendor) {
    return 'Добавено от $vendor';
  }

  @override
  String get colorsFound => 'Открити цветове';

  @override
  String deleteItemConfirm(Object name) {
    return 'Да изтрием ли „$name“? Визиите, които го използват, ще го загубят.';
  }

  @override
  String get inviteTitle => 'Покани хора';

  @override
  String get inviteCode => 'Код на събитието';

  @override
  String get inviteLinkLabel => 'Връзка за покана';

  @override
  String get inviteQrHint => 'Сканирай, за да влезеш';

  @override
  String get vendorLinksTitle => 'Доставчици';

  @override
  String get vendorCatalogueExplain =>
      'Позволи на магазин или костюмер да добавя артикули в каталога, без профил.';

  @override
  String get vendorNameLabel => 'Име на доставчика (по желание)';

  @override
  String get createLink => 'Създай връзка';

  @override
  String get settingsTitle => 'Настройки на събитието';

  @override
  String get saveChanges => 'Запази промените';

  @override
  String get saved => 'Запазено';

  @override
  String get deleteEvent => 'Изтрий събитието';

  @override
  String deleteEventConfirm(Object name) {
    return 'Да изтрием ли „$name“ с всички снимки, резултати и връзки? Това не може да се отмени.';
  }

  @override
  String get participantsTitle => 'Участници';

  @override
  String removeParticipantConfirm(Object name) {
    return 'Да премахнем ли $name и да изтрием снимката и резултатите му/ѝ?';
  }

  @override
  String get myDataTitle => 'Моите данни';

  @override
  String get myDataExplain =>
      'Снимката и резултатите ти се пазят само за това събитие. Преди да се изпрати нещо към системата за пробване, снимките се смаляват и се премахват данните за местоположение.';

  @override
  String get deletePhotoConfirm =>
      'Да изтрием ли снимката ти и всички резултати от нея?';

  @override
  String get leaveEvent => 'Напусни събитието и изтрий данните ми';

  @override
  String leaveEventConfirm(Object name) {
    return 'Да напуснеш ли „$name“? Снимката, визията и резултатите ти се изтриват.';
  }

  @override
  String get deleteEverywhere => 'Изтрий данните ми във всички събития';

  @override
  String get deleteEverywhereConfirm =>
      'Да напуснеш ли всички събития и да изтрием всичките ти снимки, визии и резултати?';

  @override
  String get deletedDone => 'Изтрито.';

  @override
  String get vendorTitle => 'Споделена визия';

  @override
  String get vendorReadOnly =>
      'Страницата е само за преглед и връзката изтича.';

  @override
  String vendorFor(Object event, Object name) {
    return 'От $name за „$event“';
  }

  @override
  String get vendorBefore => 'Преди';

  @override
  String get vendorAfter => 'Преглед';

  @override
  String vendorExpires(Object date) {
    return 'Връзката е валидна до $date';
  }

  @override
  String get vendorExpired => 'Тази връзка е изтекла.';

  @override
  String get vendorNotFound => 'Тази връзка не съществува или е отменена.';

  @override
  String vendorCatalogueTitle(Object event) {
    return 'Добави артикули към „$event“';
  }

  @override
  String get vendorAddItem => 'Добави артикул';

  @override
  String get vendorItemsInEvent => 'Артикули в каталога';

  @override
  String get inclusionTitle => 'Достъпност: прави и седнали';

  @override
  String get inclusionIntro =>
      'Виртуалното пробване обикновено се тества с прави модели. Ние измерваме как Wearmony работи за седнали хора, например в инвалидна количка, и публикуваме числата такива, каквито са.';

  @override
  String get inclusionNotMeasured => 'Още няма измервания.';

  @override
  String inclusionEngine(Object engine) {
    return 'Система: $engine';
  }

  @override
  String inclusionMeasuredAt(Object date) {
    return 'Измерено на $date';
  }

  @override
  String get colPose => 'Поза';

  @override
  String get colFraming => 'Рамка';

  @override
  String get colRuns => 'Опити';

  @override
  String get colApplied => 'Приложено';

  @override
  String get colSilent => 'Тихи провали';

  @override
  String get colErrors => 'Грешки';

  @override
  String get colFaceChanged => 'Променено лице';

  @override
  String get colMedianTime => 'Медианно време';

  @override
  String get framingAsCatalogued => 'Както е в каталога';

  @override
  String get framingUpperBody => 'Горна част (резервен вариант)';

  @override
  String get notReviewed => 'непрегледано';

  @override
  String get heroEyebrow => 'Групово виртуално пробване за събития';

  @override
  String get featureTryOnTitle => 'Пробвайте заедно';

  @override
  String get featureTryOnBody =>
      'Тоалет, червило и цвят на косата върху собствената ти снимка, после всички един до друг.';

  @override
  String get featureHarmonyTitle => 'Хармония на цветовете';

  @override
  String get featureHarmonyBody =>
      'Открива почти еднаквите цветове преди вечерта и го обяснява с едно изречение.';

  @override
  String get featureBudgetTitle => 'Общ бюджет';

  @override
  String get featureBudgetBody => 'Суми на човек и за групата, без изненади.';

  @override
  String get featureInclusiveTitle => 'За всички';

  @override
  String get featureInclusiveBody =>
      'Снимки в седнало положение се поддържат, а колко добре работят се измерва.';

  @override
  String get statRendered => 'Пробвали';

  @override
  String get statLocked => 'Заключени визии';

  @override
  String get statHarmony => 'Хармония';

  @override
  String get statBudget => 'Общо за групата';

  @override
  String get yourLook => 'Твоята визия';

  @override
  String get selected => 'Избрано';

  @override
  String get stepsTitle => 'Стъпки на пробването';

  @override
  String get badgeIllustration => 'Илюстрация';

  @override
  String get badgeSimulated => 'Симулация';
}
