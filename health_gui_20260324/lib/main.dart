import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_uploader.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('has_new_notice', true);
  debugPrint("Handling a background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 권한 요청 및 all_users 토픽 구독
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  await FirebaseMessaging.instance.subscribeToTopic('all_users');

  final prefs = await SharedPreferences.getInstance();
  final isSetupComplete = prefs.getBool('isSetupComplete') ?? false;

  String startRoute = isSetupComplete ? '/screen5' : '/screen1';
  
  // 강제 종료 상태에서 푸시를 터치하여 앱이 시작된 경우
  final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMsg != null && initialMsg.data['screen'] == 'notice') {
    startRoute = '/screen7';
  }

  await initializeService();

  runApp(MyApp(startRoute: startRoute));
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) {
         return true;
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final String startRoute;

  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {

    // 앱이 포그라운드 상태일 때 푸시가 도착한 경우
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_new_notice', true);
    });

    // 앱이 백그라운드 상태일 때 푸시를 눌러 전환된 경우
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['screen'] == 'notice') {
        navigatorKey.currentState?.pushNamed('/screen7');
      }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Health GUI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      initialRoute: startRoute,
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
