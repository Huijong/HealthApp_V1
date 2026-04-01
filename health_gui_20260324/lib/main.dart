import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/screen1_id_input.dart';
import 'screens/screen2_body_info.dart';
import 'screens/screen3_watch_model.dart';
import 'screens/screen4_strap_selection.dart';
import 'screens/screen5_activity_list.dart';
import 'screens/screen6_upload.dart';
import 'screens/screen7_notices.dart';
import 'screens/screen8_history.dart';
import 'screens/screen9_settings.dart';
import 'screens/screen10_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isSetupComplete = prefs.getBool('isSetupComplete') ?? false;

  runApp(MyApp(isSetupComplete: isSetupComplete));
}

class MyApp extends StatelessWidget {
  final bool isSetupComplete;

  const MyApp({super.key, required this.isSetupComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health GUI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: isSetupComplete ? '/screen5' : '/screen1',
      routes: {
        '/screen1': (context) => const Screen1IdInput(),
        '/screen2': (context) => const Screen2BodyInfo(),
        '/screen3': (context) => const Screen3WatchModel(),
        '/screen4': (context) => const Screen4StrapSelection(),
        '/screen5': (context) => const Screen5ActivityList(),
        '/screen6': (context) => const Screen6Upload(),
        '/screen7': (context) => const Screen7Notices(),
        '/screen8': (context) => const Screen8History(),
        '/screen9': (context) => const Screen9Settings(),
        '/screen10': (context) => const Screen10Admin(),
      },
    );
  }
}
