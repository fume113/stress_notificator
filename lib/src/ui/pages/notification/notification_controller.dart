import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stress_notificator/src/infra/health_repository.dart';
import 'package:stress_notificator/src/models/tingkat_stress.dart';
import 'package:stress_notificator/src/ui/pages/saran/saran_ringan.dart';
import 'package:stress_notificator/src/ui/pages/saran/saran_sedang.dart';
import 'package:stress_notificator/src/ui/pages/saran/saran_tinggi.dart';

class NotificationController {
  static final NotificationController _instance =
      NotificationController._internal();
  factory NotificationController() => _instance;

  NotificationController._internal() {
    _initializeNotifications();
    _startListeningToData();
  }

  final HealthRepository repository = HealthRepository();
  final ValueNotifier<TingkatStres?> tingkatStres =
      ValueNotifier<TingkatStres?>(null);
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<Map<String, List<TingkatStres>>>? _subscription;
  String? _lastNotificationTitle;
  int? _lastStressValue;

  void _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('app_icon');
    final settings = InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationClick(response.payload!);
        }
      },
    );
  }

  Future<void> _fetchInitialData() async {
    final cachedData = await repository.getCachedData();
    if (cachedData.isNotEmpty) {
      final latestStres = cachedData['latest']?.last;
      if (latestStres != null) {
        tingkatStres.value = latestStres;
        _lastStressValue = latestStres.value;
        await _checkAndShowNotification(latestStres);
      }
    }
  }

  void _startListeningToData() {
    _fetchInitialData(); // Fetch initial data once
    _subscription = repository.getCachedDataStream().listen((data) async {
      final latestHistory = data['latest'] ?? [];
      if (latestHistory.isNotEmpty) {
        final latestStres = latestHistory.last;
        if (latestStres.value != _lastStressValue) {
          tingkatStres.value = latestStres;
          _lastStressValue = latestStres.value;
          await _checkAndShowNotification(latestStres);
          await repository.cacheData(data); // Ensure data is cached
        }
      }
    }, onError: (error) {
      print('Error in data stream: $error');
    });
  }

  void stopListeningToData() => _subscription?.cancel();

  Future<void> _checkAndShowNotification(TingkatStres stress) async {
    final notificationDetails = {
      'Tingkat Stres Tinggi': 'Stres Anda berada pada tingkat Tinggi.',
      'Tingkat Stres Sedang': 'Stres Anda berada pada tingkat Sedang.',
      'Tingkat Stres Ringan': 'Stres Anda berada pada tingkat Ringan.',
      'Tingkat Stres Santai': 'Stres Anda berada pada tingkat Santai.'
    };

    final notificationTitle = notificationDetails.keys.firstWhere(
      (title) =>
          (title == 'Tingkat Stres Tinggi' && stress.value >= 80) ||
          (title == 'Tingkat Stres Sedang' && stress.value >= 60) ||
          (title == 'Tingkat Stres Ringan' && stress.value >= 40) ||
          (title == 'Tingkat Stres Santai' && stress.value < 40),
      orElse: () => '',
    );

    if (notificationTitle.isNotEmpty &&
        notificationTitle != _lastNotificationTitle) {
      await _showLocalNotification(
          notificationTitle, notificationDetails[notificationTitle]!, stress);
      _lastNotificationTitle = notificationTitle;
    }
  }

  Future<void> _showLocalNotification(
      String title, String body, TingkatStres stress) async {
    String payload;
    if (stress.value >= 80) {
      payload = 'SaranTinggi';
    } else if (stress.value >= 60) {
      payload = 'SaranSedang';
    } else if (stress.value >= 40) {
      payload = 'SaranRingan';
    } else {
      payload = 'SaranSantai'; // Tambahkan SaranSantai jika diperlukan
    }

    const androidDetails = AndroidNotificationDetails(
      'your_channel_id', // Harus sesuai dengan channel yang telah dibuat
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true,
    );

    await notificationsPlugin.show(
        0, title, body, NotificationDetails(android: androidDetails),
        payload: payload);
  }

  void _handleNotificationClick(String payload) {
    switch (payload) {
      case 'SaranTinggi':
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => SaranTinggi(),
        ));
        break;
      case 'SaranSedang':
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => SaranSedang(),
        ));
        break;
      case 'SaranRingan':
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => SaranRingan(),
        ));
        break;
      default:
        break;
    }
  }
}
