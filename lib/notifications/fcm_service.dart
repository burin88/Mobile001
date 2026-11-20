import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'received_message.dart';

const _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'การแจ้งเตือนทั่วไป',
  description: 'ข้อความแจ้งเตือนจาก Firebase Cloud Messaging',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Android displays notification payloads automatically in the background.
  // Add short, idempotent background processing for data messages here.
  debugPrint('Background FCM message: ${message.messageId}');
}

class FcmService extends ChangeNotifier {
  FcmService({this.onNotificationOpened});

  final void Function(ReceivedMessage)? onNotificationOpened;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<ReceivedMessage> _messages = [];
  bool _disposed = false;
  bool ready = false;
  bool busy = false;
  String? error;
  String? token;
  AuthorizationStatus? _permission;

  List<ReceivedMessage> get messages => List.unmodifiable(_messages);

  String get permissionLabel => switch (_permission) {
    AuthorizationStatus.authorized => 'อนุญาตแล้ว',
    AuthorizationStatus.provisional => 'อนุญาตชั่วคราว',
    AuthorizationStatus.denied =>
      'ยังไม่ได้อนุญาต (หากปฏิเสธแล้ว ให้เปิดใน Settings ของแอป)',
    _ => 'ยังไม่ได้ขอสิทธิ์',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
    } catch (exception) {
      error = 'ตั้งค่า FCM ไม่สำเร็จ: $exception';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> initialize() => _perform(() async {
    if (ready) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'การตั้งค่านี้รองรับ Android กรุณารันบนมือถือหรือ Android emulator ที่มี Google Play services',
      );
    }
    // Android reads options from android/app/google-services.json via Gradle.
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openLocalMessage(response.payload),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!
        .createNotificationChannel(_channel);
    if (_disposed) return;
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) {
        _record(message, 'รับขณะเปิดแอป');
        unawaited(_showForegroundNotification(message));
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _openRemoteMessage(message, 'เปิดจากการแจ้งเตือน');
      }),
    );
    _subscriptions.add(
      // Console test messages and existing HTTP v1 backends use registration
      // tokens, while onRegistered emits a Firebase Installation ID (FID).
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (value) {
          token = value;
          // Send refreshed tokens to your authenticated backend when one is added.
          _notify();
        },
        onError: (Object exception) {
          error = 'อัปเดต token ไม่สำเร็จ: $exception';
          _notify();
        },
      ),
    );
    ready = true;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _openRemoteMessage(initial, 'เปิดแอปจาก FCM ขณะปิดแอป');
    }
    final localLaunch = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (localLaunch?.didNotificationLaunchApp ?? false) {
      _openLocalMessage(localLaunch?.notificationResponse?.payload);
    }
    await _updateTokenAndPermission();
  });

  Future<void> refreshToken() => _perform(_updateTokenAndPermission);

  Future<void> requestPermission() => _perform(() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _updateTokenAndPermission();
  });

  Future<void> _updateTokenAndPermission() async {
    _permission = (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
    // Keep a registration token for Firebase Console's test-message field.
    // ignore: deprecated_member_use
    token = await FirebaseMessaging.instance.getToken();
  }

  void _record(RemoteMessage message, String source) {
    _messages.insert(0, ReceivedMessage.fromRemote(message, source));
    if (_messages.length > 30) _messages.removeLast();
    _notify();
  }

  void _openRemoteMessage(RemoteMessage message, String source) {
    if (_disposed) return;
    _record(message, source);
    onNotificationOpened?.call(ReceivedMessage.fromRemote(message, source));
  }

  void _openLocalMessage(String? payload) {
    if (payload == null) return;
    try {
      final message = RemoteMessage.fromMap(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
      _openRemoteMessage(message, 'เปิดจากการแจ้งเตือนในแอป');
    } catch (exception) {
      error = 'อ่านข้อความแจ้งเตือนไม่สำเร็จ: $exception';
      _notify();
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Data-only messages are recorded in the UI without inventing a banner.
    if (message.notification == null) return;
    try {
      await _localNotifications.show(
        id:
            message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title: message.notification?.title,
        body: message.notification?.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'การแจ้งเตือนทั่วไป',
            channelDescription: 'ข้อความแจ้งเตือนจาก Firebase Cloud Messaging',
            icon: 'ic_stat_notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    } catch (exception) {
      error = 'รับข้อความแล้ว แต่แสดงแจ้งเตือนไม่สำเร็จ: $exception';
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
