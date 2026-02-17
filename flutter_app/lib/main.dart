import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SwabbitApp());
}

class SwabbitApp extends StatelessWidget {
  const SwabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swabbit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SwabbitTheme.bg,
        colorScheme: const ColorScheme.dark(
          primary: SwabbitTheme.accent,
          secondary: SwabbitTheme.accent2,
          surface: SwabbitTheme.surface,
        ),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

/// ─── THEME ───────────────────────────────────────────────────────────────────
class SwabbitTheme {
  SwabbitTheme._();

  static const Color bg       = Color(0xFF0A0A0F);
  static const Color surface  = Color(0xFF111118);
  static const Color surface2 = Color(0xFF18181F);
  static const Color surface3 = Color(0xFF1E1E27);
  static const Color border   = Color(0x12FFFFFF);
  static const Color accent   = Color(0xFF00E5CC);
  static const Color accent2  = Color(0xFF7B5CEA);
  static const Color accent3  = Color(0xFFFF5A36);
  static const Color text     = Color(0xFFF0F0F5);
  static const Color text2    = Color(0xFF8888A0);
  static const Color text3    = Color(0xFF55556A);
  static const Color green    = Color(0xFF22D87A);
  static const Color yellow   = Color(0xFFFFD445);

  static const double radius   = 16.0;
  static const double radiusSm = 10.0;

  // Category gradients
  static const gpuGrad  = LinearGradient(colors: [Color(0xFF1a0d30), Color(0xFF2d1654)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const cpuGrad  = LinearGradient(colors: [Color(0xFF0d1a2d), Color(0xFF0f2e54)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const ramGrad  = LinearGradient(colors: [Color(0xFF0d2d1a), Color(0xFF0e4228)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const ssdGrad  = LinearGradient(colors: [Color(0xFF2d1a0d), Color(0xFF4a2a0e)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const mbGrad   = LinearGradient(colors: [Color(0xFF2d0d1a), Color(0xFF4a0e2a)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const coolGrad = LinearGradient(colors: [Color(0xFF0d2d2d), Color(0xFF0e4040)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const accentGrad = LinearGradient(colors: [accent2, accent], begin: Alignment.topLeft, end: Alignment.bottomRight);

  static const TextStyle displayStyle = TextStyle(
    fontFamily: 'Syne', fontWeight: FontWeight.w800,
    color: text, letterSpacing: -0.5,
  );
  static const TextStyle monoStyle = TextStyle(
    fontFamily: 'SpaceMono', fontWeight: FontWeight.w700, color: text,
  );

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
    color: surface2,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? border),
  );
}