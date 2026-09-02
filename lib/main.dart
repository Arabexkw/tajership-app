import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'screens/home.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة الإشعارات (تعمل بصمت إن لم تكن Firebase مهيأة بعد)
  await PushService.instance.init();
  // شريط الحالة بلون داكن يناسب الهوية
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(AppConfig.inkBlack),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const TajerShipApp());
}

class TajerShipApp extends StatelessWidget {
  const TajerShipApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(AppConfig.inkBlack);
    const amber = Color(AppConfig.amber);

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: amber,
          brightness: Brightness.dark,
          surface: ink,
          primary: amber,
        ),
        scaffoldBackgroundColor: ink,
      ),
      home: const SplashScreen(),
    );
  }
}

/// شاشة بداية أصلية بهوية تاجرشِب (تظهر ثانية ونصف ثم الرئيسية)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(AppConfig.inkBlack);
    const amber = Color(AppConfig.amber);
    return Scaffold(
      backgroundColor: ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/app_icon.png', width: 120, height: 120),
            const SizedBox(height: 22),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(text: 'تاجر', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'شِب', style: TextStyle(color: amber)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('تسوّق وتاجر — توصيل وشحن وتتبع',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: amber),
            ),
          ],
        ),
      ),
    );
  }
}
