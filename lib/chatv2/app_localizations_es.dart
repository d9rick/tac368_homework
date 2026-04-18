// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Demostración de localización';

  @override
  String get helloWorld => '¡Hola Mundo!';

  @override
  String counterMessage(int count) {
    return 'Has pulsado $count veces';
  }
}
