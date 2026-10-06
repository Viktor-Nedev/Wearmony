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
  String get openDemo => 'Демо бал';

  @override
  String get demoHint =>
      'Готови събития с илюстрирани хора: бал и училищна пиеса. Не са нужни снимки.';

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
  String budgetOfCap(Object cap) {
    return 'от $cap';
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

  @override
  String get notFoundTitle => 'Тази страница не съществува';

  @override
  String get notFoundBody => 'Връзката може да е стара или сгрешена.';

  @override
  String get goHome => 'Към Wearmony';

  @override
  String get howItWorks => 'Как работи';

  @override
  String get step1Title => 'Поканете групата';

  @override
  String get step1Body =>
      'Създайте събитието и споделете код, линк или QR код.';

  @override
  String get step2Title => 'Всеки пробва';

  @override
  String get step2Body =>
      'Всеки добавя една снимка и пробва тоалети, червила и цветове на косата.';

  @override
  String get step3Title => 'Вижте групата в хармония';

  @override
  String get step3Body =>
      'Открийте почти еднаквите цветове и останете в общия бюджет, преди някой да купи.';

  @override
  String get clashFixed =>
      'Сблъсъкът е оправен: цветовете на групата вече си пасват.';

  @override
  String get harmonyMapTitle => 'Карта на хармонията';

  @override
  String get harmonyMapHint =>
      'Всяка линия сравнява два тоалета. Посочете или докоснете човек, за да видите само неговите двойки. Малките точки са цветовете на косата и червилото.';

  @override
  String get fixTitle => 'Как да се поправи';

  @override
  String get fixSubtitle =>
      'Замени от каталога на събитието, които махат почти еднаквите цветове. Проверени със същата цветова математика, без мнения на модел.';

  @override
  String get fixNone =>
      'В каталога още няма вещ, която да поправи това. Добавете една в същия нюанс или в ясно различен цвят.';

  @override
  String fixWith(Object name, Object relation) {
    return '$relation с $name';
  }

  @override
  String fixWithOutfit(Object relation) {
    return '$relation с тоалета';
  }

  @override
  String get fixScore => 'Хармония на групата';

  @override
  String get fixSamePrice => 'Същата цена';

  @override
  String get fixOverBudget => 'Над бюджета на човек';

  @override
  String get fixApply => 'Смени с това';

  @override
  String get fixApplied =>
      'Визията е обновена. Проверката на хармонията вече я отчита.';

  @override
  String get fixPreview => 'Покажи';

  @override
  String get fixCopy => 'Копирай предложението';

  @override
  String get fixCopied => 'Предложението е копирано';

  @override
  String fixShareText(Object item, Object name, Object other, Object relation) {
    return '$name, пробвай $item: до $other резултатът е „$relation“, а не почти еднакви цветове.';
  }

  @override
  String fixShareTextSelf(Object item, Object name, Object relation) {
    return '$name, пробвай $item: с тоалета резултатът е „$relation“, а не почти еднакви цветове.';
  }

  @override
  String get frameOpen => 'Групова снимка';

  @override
  String get frameOpenHint =>
      'Вижте текущата визия на всички в един кадър и я запазете като изображение.';

  @override
  String get frameTitle => 'Групова снимка';

  @override
  String get frameSubtitle =>
      'Текущата визия на всички в един кадър. Партньорите стоят заедно.';

  @override
  String get frameBackdrop => 'Фон';

  @override
  String get backdropBallroom => 'Бална зала';

  @override
  String get backdropStage => 'Сцена';

  @override
  String get backdropGarden => 'Градина';

  @override
  String get backdropStudio => 'Студио';

  @override
  String get frameSave => 'Запази изображението';

  @override
  String get frameShare => 'Сподели изображението';

  @override
  String get frameSaved => 'Изображението е запазено в изтеглените файлове.';

  @override
  String get frameSaveFailed =>
      'Изображението не можа да бъде създадено. Опитайте отново.';

  @override
  String get frameHint =>
      'Изображението запазва етикетите, които казват кое е симулирано.';

  @override
  String get frameEmpty => 'Още никой не се е присъединил.';

  @override
  String frameHarmony(int score) {
    return 'Хармония $score/100';
  }

  @override
  String framePeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count души',
      one: '1 човек',
    );
    return '$_temp0';
  }

  @override
  String get frameHonestDemo => 'Илюстрации, не истински снимки';

  @override
  String get frameHonestMock => 'Симулирано пробване (mock режим)';

  @override
  String get frameHonestReal => 'Виртуален преглед, не гаранция за размера';

  @override
  String frameShareText(Object event) {
    return 'Нашите визии за $event, направени с Wearmony.';
  }

  @override
  String get readinessTitle => 'Подготовка';

  @override
  String get readinessPhoto => 'Снимка';

  @override
  String get readinessLook => 'Визия';

  @override
  String get readinessPreview => 'Преглед';

  @override
  String get readinessLocked => 'Заключена';

  @override
  String get nextPhoto => 'Трябва снимка';

  @override
  String get nextLook => 'Избира визия';

  @override
  String get nextPreview => 'Още няма преглед';

  @override
  String get nextLock => 'Може да заключи визията';

  @override
  String get nextDone => 'Всичко е готово';

  @override
  String get reminderCopy => 'Копирай напомняне';

  @override
  String reminderText(Object event, Object link) {
    return 'Моля, довършете визията си за $event в Wearmony: $link';
  }

  @override
  String get reminderCopied =>
      'Напомнянето е копирано. Поставете го в груповия чат.';

  @override
  String get eventDateLabel => 'Дата на събитието (по избор)';

  @override
  String get eventDateNone => 'Още без дата';

  @override
  String get eventDateClear => 'Изчисти датата';

  @override
  String get countdownToday => 'Днес';

  @override
  String countdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'след $count дни',
      one: 'след 1 ден',
    );
    return '$_temp0';
  }

  @override
  String countdownPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'преди $count дни',
      one: 'преди 1 ден',
    );
    return '$_temp0';
  }

  @override
  String get featureFixTitle => 'Поправка с едно докосване';

  @override
  String get featureFixBody =>
      'Когато два цвята почти съвпадат, Wearmony намира замени от каталога, които го поправят, и показва какво се променя.';

  @override
  String get featureFrameTitle => 'Една обща снимка';

  @override
  String get featureFrameBody =>
      'Текущата визия на всички в един кадър, партньорите един до друг, готова за споделяне.';

  @override
  String fixOthersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Остават още $count сблъсъка в групата',
      one: 'Остава още един сблъсък в групата',
    );
    return '$_temp0';
  }

  @override
  String fixWithYou(Object relation) {
    return '$relation с вас';
  }

  @override
  String fixShareTextMe(Object item, Object name, Object relation) {
    return '$name, пробвай $item: до мен резултатът е „$relation“, а не почти еднакви цветове.';
  }

  @override
  String harmonyMapSemantics(int people, int nearMisses) {
    String _temp0 = intl.Intl.pluralLogic(
      nearMisses,
      locale: localeName,
      other: '$nearMisses сблъсъка',
      one: 'един сблъсък',
      zero: 'нула сблъсъка',
    );
    return 'Карта на хармонията за $people души с $_temp0.';
  }

  @override
  String frameSemantics(Object event, Object names) {
    return 'Групова снимка на $event: $names.';
  }

  @override
  String get openTheatreDemo => 'Демо с театрална трупа';

  @override
  String get notPreviewed => 'Нова визия, още без преглед';

  @override
  String get poweredByEyebrow => 'С YouCam API';

  @override
  String get poweredByTitle => 'Една снимка, три стъпки на пробване';

  @override
  String get poweredByBody =>
      'Всяка визия се изгражда като верига върху собствената снимка на участника: първо тоалетът, после червилото върху този резултат, след това цветът на косата. Всяка стъпка може да се провери отделно.';

  @override
  String get chainPhotoTitle => 'Твоята снимка';

  @override
  String get chainPhotoBody =>
      'Проверява се за размер и светлина преди всяко пробване, права или седнала поза.';

  @override
  String get chainClothesBody =>
      'Облича тоалета от каталога на събитието върху снимката.';

  @override
  String get chainMakeupBody => 'Добавя точния цвят на червилото от каталога.';

  @override
  String get chainHairBody => 'Прилага избрания цвят на косата.';

  @override
  String get factCache =>
      'Всяка стъпка се пази: една и съща снимка и вещ никога не струват два пъти.';

  @override
  String get factLedger =>
      'Отчет на единиците ограничава разхода за събитие и за човек.';

  @override
  String get factLabels =>
      'Симулираните и демо резултатите винаги са отбелязани.';

  @override
  String get privacyTitle => 'Поверителност по подразбиране';

  @override
  String get privacySubtitle =>
      'Снимките са лични. Wearmony се отнася към тях така.';

  @override
  String get privacyPrivateTitle => 'Само за събитието';

  @override
  String get privacyPrivateBody =>
      'Само хората в събитието виждат снимката и прегледите ти.';

  @override
  String get privacyDeleteTitle => 'Изтриване по всяко време';

  @override
  String get privacyDeleteBody =>
      'Сам изтриваш снимката и данните си; организаторът може да изтрие цялото събитие.';

  @override
  String get privacyLinksTitle => 'Връзки с изтичащ срок';

  @override
  String get privacyLinksBody =>
      'Връзките за доставчици са само за четене и спират да работят след срока си.';

  @override
  String get privacyConsentTitle => 'Пълнолетни, със съгласие';

  @override
  String get privacyConsentBody =>
      'Ясен екран за съгласие се показва преди всяко качване на снимка.';

  @override
  String get faqTitle => 'Въпроси';

  @override
  String get faqSeatedQ => 'Работи ли, ако съм в инвалидна количка?';

  @override
  String get faqSeatedA =>
      'Да. Изберете „седнала поза“, когато добавяте снимката. Двигателите за пробване обикновено се тестват с изправени хора, затова Wearmony измерва колко добре работят седналите снимки и публикува резултатите.';

  @override
  String get faqNearMissQ => 'Какво е „почти еднакви“?';

  @override
  String get faqNearMissA =>
      'Два цвята, които са близки, но не еднакви, например два леко различни розови. Един до друг изглеждат като грешка, затова Wearmony предупреждава и предлага замени, които я поправят.';

  @override
  String get faqExactQ => 'Точен ли е прегледът?';

  @override
  String get faqExactA =>
      'Това е визуален преглед, не гаранция за размера. Платът, светлината и камерите променят как изглеждат цветовете на самата вечер.';

  @override
  String get faqPhotoQ => 'Кой вижда снимката ми?';

  @override
  String get faqPhotoA =>
      'Само хората в твоето събитие. Фризьор, когото поканиш, вижда само цвета на косата и снимката преди, чрез връзка с изтичащ срок. Можеш да изтриеш снимката си по всяко време.';

  @override
  String get faqAccountQ => 'Нужен ли е акаунт?';

  @override
  String get faqAccountA =>
      'Не. Влизаш с код. Влизането с имейл е по избор, за да ползваш събитията си на друго устройство.';

  @override
  String get faqUnitsQ => 'Струва ли нещо прегледът?';

  @override
  String get faqUnitsA =>
      'Планирането, цветовете и бюджетите не използват единици от API. Всяка стъпка на пробване използва единици от YouCam API от бюджета на събитието, с ограничения за събитие и за човек, а една и съща снимка и вещ никога не се плащат два пъти.';

  @override
  String get footerStart => 'Начало';

  @override
  String get footerDemos => 'Демо';

  @override
  String get footerLearn => 'Научи повече';

  @override
  String get footerTagline =>
      'Групово виртуално пробване за балове, пиеси, сватби и общи снимки.';

  @override
  String get footerHackathon =>
      'Създадено за YouCam API Skin AI & eCommerce VTO Hackathon. Хората в демо събитията са илюстрации.';

  @override
  String get tourButton => 'Обиколка';

  @override
  String get tourTitle => 'Разгледайте демото';

  @override
  String get tourSubtitle => 'Няколко неща, които да пробвате тук.';

  @override
  String get tourFixTitle => 'Поправете сблъсъка';

  @override
  String get tourFixBody =>
      'Вие и София почти съвпадате. Поправете го с едно докосване.';

  @override
  String get tourPhotoTitle => 'Всички в един кадър';

  @override
  String get tourPhotoBody => 'Груповата снимка, готова за запазване.';

  @override
  String get tourMapTitle => 'Картата на хармонията';

  @override
  String get tourMapBody =>
      'Всяка двойка тоалети като една линия, оцветена според това как си пасват.';

  @override
  String get tourBudgetTitle => 'Проверете бюджета';

  @override
  String get tourBudgetBody =>
      'Кой е над лимита и на кого още му трябва снимка или заключване.';

  @override
  String get tourTheatreTitle => 'Същият двигател, друго събитие';

  @override
  String get tourTheatreBody => 'Отворете училищната пиеса.';

  @override
  String get tourCostumesTitle => 'Открийте сблъсъка на костюмите';

  @override
  String get tourCostumesBody =>
      'Тюркоазите на Ромео и Меркуцио почти съвпадат.';

  @override
  String get tourStageTitle => 'Трупата на сцената';

  @override
  String get tourStageBody => 'Груповата снимка на фон сцена.';

  @override
  String get tourPromTitle => 'Обратно към бала';

  @override
  String get tourPromBody => 'Отворете демото на бала.';

  @override
  String get activityTitle => 'Последна активност';

  @override
  String get activityEmpty =>
      'Още нищо. Тук ще се появява активността, когато хората се присъединяват и пробват визии.';

  @override
  String activityJoined(Object name) {
    return '$name се присъедини';
  }

  @override
  String activityLook(Object item, Object name) {
    return '$name избра $item';
  }

  @override
  String activityLocked(Object name) {
    return '$name заключи визията си';
  }

  @override
  String activityPreviewed(Object name) {
    return '$name пробва визията си';
  }

  @override
  String get timeJustNow => 'току-що';

  @override
  String timeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'преди $count мин',
      one: 'преди 1 мин',
    );
    return '$_temp0';
  }

  @override
  String timeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'преди $count ч',
      one: 'преди 1 ч',
    );
    return '$_temp0';
  }

  @override
  String timeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'преди $count дни',
      one: 'вчера',
    );
    return '$_temp0';
  }

  @override
  String get previewsTitle => 'Твоите прегледи';

  @override
  String get previewsHint => 'Докосни един, за да го сравниш с текущата визия.';

  @override
  String get previewsNow => 'Сега';

  @override
  String get lookUnnamed => 'Визия';

  @override
  String get compareTitle => 'Сравни визиите';

  @override
  String compareWear(Object name) {
    return 'Облечи пак $name';
  }

  @override
  String get compareNote =>
      'И двата прегледа вече са готови, затова връщането не струва нищо.';

  @override
  String get activityLockedYou => 'Ти заключи визията си';

  @override
  String get activityPreviewedYou => 'Ти пробва визията си';

  @override
  String get inclusionMethodTitle => 'Как измерваме';

  @override
  String get method1Title => 'Едни и същи дрехи';

  @override
  String get method1Body =>
      'Всяка снимка получава едни и същи тоалети от един каталог, така че се различава само позата.';

  @override
  String get method2Title => 'Права и седнала поза';

  @override
  String get method2Body =>
      'Снимки на пълнолетни, дали съгласие, прави и седнали, с едни и същи правила за кадъра.';

  @override
  String get method3Title => 'Четири неща се записват';

  @override
  String get method3Body =>
      'Дали тоалетът е приложен, тихите неуспехи, дали лицето се е променило (проверка от човек) и колко време е отнело.';

  @override
  String get method4Title => 'Публикуваме измереното';

  @override
  String get method4Body =>
      'Без оценки на око. Подобренията се отчитат с числа преди и след.';

  @override
  String get inclusionTableTitle => 'Какво ще бъде публикувано';

  @override
  String get inclusionTableNote =>
      'Всяка клетка остава празна, докато не бъде измерена.';

  @override
  String get inclusionBuiltTitle => 'Вече направено за седнали хора';

  @override
  String get built1 =>
      'Всеки участник избира „права“ или „седнала“ поза за снимката си.';

  @override
  String get built2 =>
      'Ако тоалет в цял ръст не се приложи на седнала снимка, Wearmony опитва още веднъж с рамка за горната част на тялото.';

  @override
  String get built3 =>
      'Всеки резултат се проверява дали тоалетът изобщо е приложен, така че тихият неуспех се отбелязва, вместо да се показва като резултат.';

  @override
  String get built4 =>
      'Демо балът има седнал участник, така че потокът може да се пробва без снимки.';

  @override
  String get inclusionDemoCta => 'Виж демо групата';

  @override
  String inclusionNoteSample(int renders, int people, int seated) {
    return '$renders пробвания на дрехи върху $people души ($seated седнали). Малка извадка: числата са ориентировъчни, а не сравнителен тест.';
  }

  @override
  String get inclusionNoteDocs =>
      'Документацията на YouCam AI Clothes изисква човекът да стои прав (без сядане или клякане); тази оценка измерва какво означава това за седналите участници.';

  @override
  String get inclusionNoteApplied =>
      '„Приложено“ брои резултатите, които проверяващ човек не е отхвърлил; „тихи неуспехи“ са резултатите, върнати без дрехата.';

  @override
  String get personLookTitle => 'Визия';

  @override
  String get personHarmonyTitle => 'До останалите';

  @override
  String personSelf(Object subject) {
    return '$subject спрямо тоалета';
  }

  @override
  String get personOpenMyLook => 'Към моята визия';

  @override
  String get dressCodeTitle => 'Дрескод';

  @override
  String get dressCodeHint =>
      'Изберете до четири цвята за групата. Всеки тоалет се сравнява с най-близкия от тях.';

  @override
  String get dressCodeEmpty => 'Още няма дрескод.';

  @override
  String dressCodeOnCount(int on, int total) {
    return '$on от $total са в дрескода';
  }

  @override
  String get dressFitOn => 'В дрескода';

  @override
  String get dressFitClose => 'Близо до дрескода';

  @override
  String get dressFitOff => 'Извън дрескода';

  @override
  String get swatchBlack => 'Черно';

  @override
  String get swatchWhite => 'Бяло';

  @override
  String get swatchIvory => 'Слонова кост';

  @override
  String get swatchChampagne => 'Шампанско';

  @override
  String get swatchGold => 'Златисто';

  @override
  String get swatchSilver => 'Сребристо';

  @override
  String get swatchBlush => 'Пудрено розово';

  @override
  String get swatchRose => 'Розово';

  @override
  String get swatchRed => 'Червено';

  @override
  String get swatchCrimson => 'Тъмночервено';

  @override
  String get swatchBurgundy => 'Бордо';

  @override
  String get swatchLavender => 'Лавандула';

  @override
  String get swatchSky => 'Небесносиньо';

  @override
  String get swatchRoyal => 'Кралско синьо';

  @override
  String get swatchNavy => 'Тъмносиньо';

  @override
  String get swatchTeal => 'Петролено';

  @override
  String get swatchEmerald => 'Изумрудено';

  @override
  String get swatchSage => 'Пепелявозелено';

  @override
  String get swatchMustard => 'Горчица';

  @override
  String get dressCodeFull =>
      'Избрани са четири цвята. Махнете един, за да изберете друг.';

  @override
  String get runwayTitle => 'Виртуален подиум';

  @override
  String get runwaySolo => 'Индивидуално';

  @override
  String get runwayDuo => 'Двойки';

  @override
  String get runwayFinale => 'Финал';

  @override
  String get runwayPlay => 'Автоматично дефиле';

  @override
  String get runwayPause => 'Пауза';

  @override
  String get runwayFixNow => 'Поправи на подиума';

  @override
  String get moodboardTitle => 'Цветен Moodboard';

  @override
  String get moodboardSubtitle =>
      'Цветовите акорди на групата, мостри и цветова температура.';

  @override
  String get moodboardExport => 'Запази палитрата';

  @override
  String get moodboardWheelTitle => 'Хроматично колело на хармонията';

  @override
  String get moodboardWheelHint =>
      'Докоснете точка, за да проверите точните CIELAB стойности и съчетания на този участник.';

  @override
  String get moodboardInspectTitle => 'Детайли за цвета';

  @override
  String get moodboardInspectHint =>
      'Изберете участник от колелото, за да видите извлечения нюанс и релациите му.';

  @override
  String get moodboardPairRelations => 'Цветови връзки';

  @override
  String get moodboardPaletteTitle => 'Групова цветова палитра';

  @override
  String get moodboardNoSwatches => 'Все още няма избрани тоалети.';

  @override
  String get moodboardVibeTitle => 'Естетически баланс и кохезия';

  @override
  String get moodboardCohesionScore =>
      'Хармония на групата (най-слабата двойка)';

  @override
  String get moodboardCohesionHigh =>
      'Отлична цветова хармония в цялата група.';

  @override
  String get moodboardCohesionMed =>
      'Добра координация с дребни контрастни вариации.';

  @override
  String get moodboardCohesionLow =>
      'Открити са смущаващи разминавания за коригиране.';

  @override
  String get moodboardTempBalance => 'Температурен баланс на цветовете';

  @override
  String get moodboardWarm => 'Топли (Червени / Розови / Златисти)';

  @override
  String get moodboardCool => 'Студени (Сини / Петролени / Зелени)';

  @override
  String get lookbookTitle => 'Дигитален лукбук';

  @override
  String get lookbookExportSpread => 'Запази страницата като изображение';

  @override
  String get lookbookSpreadCover => 'Корица';

  @override
  String get lookbookSpreadPairs => 'Двойки';

  @override
  String get lookbookSpreadCollection => 'Колекция';

  @override
  String get lookbookSpreadStory => 'Цветова история';

  @override
  String get showcaseDeckTitle => 'Интерактивно представяне';

  @override
  String get showcaseDeckRunway => '3D Подиум';

  @override
  String get showcaseDeckRunwayHint =>
      'Модно дефиле със сценични прожектори и корекции на живо';

  @override
  String get showcaseDeckFrame => 'Групова снимка';

  @override
  String get showcaseDeckFrameHint => 'Всички заедно на рисуван фон';

  @override
  String get showcaseDeckMoodboard => 'Moodboard';

  @override
  String get showcaseDeckMoodboardHint => 'Цветово колело и палитра от мостри';

  @override
  String get showcaseDeckLookbook => 'Lookbook';

  @override
  String get showcaseDeckLookbookHint => 'Гланцирано модно списание';

  @override
  String get lookbookSeal => 'Хармония';

  @override
  String get lookbookPairsHint =>
      'Цветове, подбрани така, че две визии да не си пречат една до друга.';

  @override
  String get lookbookPairNote =>
      'Сравнени със CIEDE2000, същата цветова математика като проверката на хармонията.';

  @override
  String get lookbookCollectionHint =>
      'Всеки тоалет, цвят на червилото и на косата, с цените.';

  @override
  String get lookbookStoryHint =>
      'Палитрата на групата и за кого е направен Wearmony.';

  @override
  String get lookbookChords => 'Цветовете на събитието';

  @override
  String get lookbookInclusionTitle => 'За всички';

  @override
  String get lookbookInclusionBody =>
      'Виртуалното пробване обикновено се тества с изправени модели. Wearmony опитва седналите снимки отново с рамка за горната част на тялото и измерва колко добре работят, преди да публикува каквото и да е число.';

  @override
  String get lookbookMasthead => 'Брой „Хармония“ · Том I';

  @override
  String lookbookIssue(String year) {
    return 'Брой $year';
  }
}
