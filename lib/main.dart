import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:arabic_converter/home_page.dart';
import 'package:arabic_converter/documents_page.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return AppLocalizations.of(context)?.app_title ??
            "Evase Error"; // ignore: undefined_identifier
      },
      theme: ThemeData(
          fontFamily: "Lateef",
          textTheme: Theme.of(context).textTheme.apply(fontSizeDelta: 4)),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale("en", ""),
        Locale("de", ""),
      ],
      routes: {
        "/": (context) => const HomePage(),
        "/documents": (context) => const DocumentsPage(),
      },
    );
  }
}
