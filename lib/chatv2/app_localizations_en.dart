// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Localization Demo';

  @override
  String get helloWorld => 'Hello World!';

  @override
  String counterMessage(int count) {
    return 'You have clicked $count times';
  }
}
