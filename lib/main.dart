import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:stress_notificator/src/ui/pages/login/login_page.dart';
import 'package:stress_notificator/src/ui/pages/home/home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:stress_notificator/src/ui/pages/notification/notification_controller.dart';
import 'package:stress_notificator/src/infra/health_repository.dart'; // Import repository

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final healthRepository = HealthRepository();
  healthRepository.getTingkatStresStream().listen((data) {});

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;
  late NotificationController notificationController;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    initializeBackground();

    // Inisialisasi NotificationController
    notificationController = NotificationController();
  }

  Future<void> initializeBackground() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'App Background Service',
      notificationText: 'Background service is running',
      notificationImportance: AndroidNotificationImportance.Max,
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    // Ensure FlutterBackground is properly initialized before enabling background execution
    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      hasPermissions =
          await FlutterBackground.initialize(androidConfig: androidConfig);
    }

    if (hasPermissions) {
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationController().navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: user == null ? const LoginPage() : HomePage(),
    );
  }
}
