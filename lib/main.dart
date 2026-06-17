import 'package:flutter/material.dart';
import 'package:estatetrack1/notifications/lease_reminder_service.dart';
import 'package:estatetrack1/screens/login/login_screen.dart';
import 'package:estatetrack1/settings/app_settings.dart';
import 'package:estatetrack1/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LeaseReminderService.instance.init();
  runApp(const EstateTrackApp());
}

class EstateTrackApp extends StatefulWidget {
  const EstateTrackApp({super.key});

  @override
  State<EstateTrackApp> createState() => _EstateTrackAppState();
}

class _EstateTrackAppState extends State<EstateTrackApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettingsChanged);
    AppSettings.instance.load();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EstateTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppSettings.instance.themeMode,
      home: const LoginScreen(),
    );
  }
}
