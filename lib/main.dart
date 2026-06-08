import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase non configuré (clés placeholder) — push désactivé silencieusement.
    // Exécutez `flutterfire configure` pour activer les notifications push.
  }

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const LeoniApp(),
    ),
  );
}

class LeoniApp extends StatelessWidget {
  const LeoniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final locale = localeProvider.locale;
    final isRtl = locale.languageCode == 'ar';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotivUp',
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection:
              isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
}
