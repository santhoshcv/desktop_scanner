import 'package:desktop_scanner/config/app_settings.dart';
import 'package:desktop_scanner/screens/main_desktop_screen.dart';
import 'package:desktop_scanner/screens/settings_screen.dart';
import 'package:desktop_scanner/screens/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1400, 900),
    maximumSize: Size(1400, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: "Flutter Window Demo",
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const DesktopScannerApp());
}

class DesktopScannerApp extends StatelessWidget {
  const DesktopScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Scanner Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B46C1),
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home:
          AppSettings.instance.isConfigured
              ? const MainDesktopScreen()
              : const SetupScreen(),
      routes: {
        '/main': (context) => const MainDesktopScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/setup': (context) => const SetupScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
