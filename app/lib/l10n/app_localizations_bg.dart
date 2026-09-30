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
  String get apiStatusMock => 'API: тестов режим (mock)';

  @override
  String get apiStatusLive => 'API: реален режим';

  @override
  String get apiStatusOffline => 'API е недостъпно';

  @override
  String get createEventTitle => 'Ново събитие';

  @override
  String get eventNameLabel => 'Име на събитието';

  @override
  String get templateLabel => 'Шаблон';

  @override
  String get templateProm => 'Бал';

  @override
  String get templateTheatre => 'Театър';

  @override
  String get templateGroup => 'Групова снимка';

  @override
  String get createEventButton => 'Създай събитие';

  @override
  String get joinTitle => 'Влез в събитие';

  @override
  String get joinCodeLabel => 'Код на събитието';

  @override
  String get joinButton => 'Влез';

  @override
  String get notConnectedYet =>
      'Още не е свързано: записването идва с настройката на акаунтите.';

  @override
  String get vendorTitle => 'Споделена визия';

  @override
  String get vendorReadOnly =>
      'Страницата е само за преглед и връзката изтича.';

  @override
  String get pipelineTitle => 'Проверка на пробването';

  @override
  String get pipelineRunSuccess => 'Пусни успешно пробване';

  @override
  String get pipelineRunFailure => 'Пусни неуспешно пробване';

  @override
  String get tryOnQueued => 'Чака на опашка…';

  @override
  String tryOnRunning(int percent) {
    return 'Генерира се… $percent%';
  }

  @override
  String get tryOnSuccess => 'Готово.';

  @override
  String get tryOnFailed => 'Пробването не успя';

  @override
  String get tryOnTimeout => 'Отнема твърде дълго. Опитай отново.';

  @override
  String get failureGarmentNotApplied =>
      'Тоалетът не беше приложен върху снимката. Това често се случва, когато дрехите на снимката са тъмни или обемни; опитай снимка с по-светли, прилепнали дрехи.';

  @override
  String get failureGeneric => 'Нещо се обърка при генерирането.';

  @override
  String get mockBadge =>
      'Симулиран резултат (mock режим, без извикване към YouCam)';

  @override
  String get previewDisclaimer => 'Визуален преглед, не гаранция за размера.';
}
