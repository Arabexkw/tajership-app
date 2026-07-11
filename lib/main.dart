import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api.dart';
import 'config.dart';
import 'screens/driver_home.dart';
import 'screens/login.dart';
import 'screens/merchant_home.dart';

void main() {
  runApp(const TajerShipApp());
}

class TajerShipApp extends StatelessWidget {
  const TajerShipApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(AppConfig.inkBlack);
    const amber = Color(AppConfig.amber);

    final scheme = ColorScheme.fromSeed(
      seedColor: amber,
      brightness: Brightness.dark,
      surface: ink,
      primary: amber,
    );

    return MaterialApp(
      title: 'تاجرشِب',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: ink,
        appBarTheme: const AppBarTheme(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1D232B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: amber,
            foregroundColor: ink,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1D232B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final session = await api.restore();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homeForSession(session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تاجرشِب',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(AppConfig.amber),
                )),
            SizedBox(height: 8),
            Text('تجارتك توصل أبعد — مع أرابكس',
                style: TextStyle(fontSize: 15, color: Colors.white70)),
            SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

/// يوجه المستخدم لواجهته حسب دوره — نفس فلسفة الدخول الموحد بالمنصة
Widget homeForSession(Session? session) {
  if (session == null) return const LoginScreen();
  switch (session.role) {
    case UserRole.driver:
      return const DriverHomeScreen();
    case UserRole.merchant:
    case UserRole.admin:
    case UserRole.carrier:
      return const MerchantHomeScreen();
  }
}
