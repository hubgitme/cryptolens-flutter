// کریپتو لنز — نسخه نیتیو Flutter (بدون WebView)
import 'package:flutter/material.dart';

import 'alert_service.dart';
import 'settings.dart';
import 'theme.dart';
import 'ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AlertService.init();
  } catch (_) {}
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
        canvasColor: cBg,
        cardColor: cSurface,
        dialogBackgroundColor: cSurface,
        dividerColor: cBorder,
        colorScheme: ColorScheme.dark(
          primary: cAccent,
          secondary: cAccent,
          surface: cSurface,
          onSurface: cText,
        ),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: cSurface),
        chipTheme: ChipThemeData(
          backgroundColor: cBg,
          selectedColor: cAccent,
          disabledColor: cBg,
          side: BorderSide(color: cBorder),
          labelStyle: TextStyle(color: cText),
          secondaryLabelStyle: TextStyle(color: Colors.white),
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : cMuted,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? cAccent : cBorder,
          ),
        ),
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
