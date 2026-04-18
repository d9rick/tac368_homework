// version 2 of demo of localization

// 0. Flutter project and put THIS file in lib/ to run.
//
// 1. pubspec.yaml must have ...
//
//dependencies:
//  flutter:
//    sdk: flutter
//  flutter_localizations:
//    sdk: flutter
//  intl: any
//
//flutter:
//  uses-material-design: true
//  generate: true
// ............ the additions here are intl:any and generate:true .
//
// 2. add l10n.yaml in the project root containing:
// arb-dir: lib/l10n
// template-arb-file: app_en.arb
// output-localization-file: app_localizations.dart
// output-class: AppLocalizations
//
// 3. make a directory lib/l10n/ and put in it files
// of the form app_en.arb where the 'en' is a language code.
// I am encloding those files separately, but you have to
// put them in the right place.
//
// 4. in the terminal ...
// flutter pub get
// flutter gen-l10n
// flutter run
//
// ...... 'pub get' should fix the imports.   The gen-l10n
// adds files to the l10n directory.  You could write out those
// files by hand, but the generation proecess obviously makes
// it easier.  'Run' you can do in the IDE.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'chatv2/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(onLocaleChanged: _setLocale),
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;

  const HomePage({super.key, required this.onLocaleChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          TextButton(
            onPressed: () => widget.onLocaleChanged(const Locale('en')),
            child: const Text('EN'),
          ),
          TextButton(
            onPressed: () => widget.onLocaleChanged(const Locale('es')),
            child: const Text('ES'),
          ),
          TextButton(
            onPressed: () => widget.onLocaleChanged(const Locale('fr')),
            child: const Text('FR'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.helloWorld, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 16),
            Text(t.counterMessage(_count)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
