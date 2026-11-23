// کریپتو لنز — نسخه نیتیو Flutter (بدون WebView)
import 'package:flutter/material.dart';

import 'settings.dart';
import 'theme.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CryptoLensApp());
}

class CryptoLensApp extends StatelessWidget {
  const CryptoLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کریپتو لنز',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: cBg,
        colorScheme: ColorScheme.dark(primary: cAccent, surface: cSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cAccent),
          ),
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: FutureBuilder<AppSettings>(
        future: SettingsStore.load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return HomePage(settings: snap.data!);
        },
      ),
    );
  }
}
