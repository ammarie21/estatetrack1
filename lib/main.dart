import 'package:flutter/material.dart';

import 'package:estatetrack1/screens/login/login_screen.dart';
import 'package:estatetrack1/theme/app_theme.dart';

void main() {
  runApp(const EstateTrackApp());
}

class EstateTrackApp extends StatelessWidget {
  const EstateTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EstateTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}
