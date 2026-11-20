import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

class ReceivedMessage {
  ReceivedMessage({
    required this.title,
    required this.body,
    required Map<String, dynamic> data,
    required this.source,
    this.messageId,
  }) : payload = Map.unmodifiable(data);

  factory ReceivedMessage.fromRemote(
    RemoteMessage message,
    String source,
  ) => ReceivedMessage(
    title:
        message.notification?.title ??
        message.data['title']?.toString() ??
        'ข้อความใหม่',
    body: message.notification?.body ?? message.data['body']?.toString() ?? '',
    data: message.data,
    source: source,
    messageId: message.messageId,
  );

  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final String source;
  final String? messageId;

  String get data => payload.isEmpty
      ? ''
      : const JsonEncoder.withIndent('  ').convert(payload);

  String? get id => _nonEmpty(payload['id']) ?? _nonEmpty(payload['Id']);
  String? get requestedRoute => _nonEmpty(payload['route']);

  // Only known application routes can be opened from notification data.
  String get destinationRoute => switch (requestedRoute) {
    'page2' || '/page2' => '/page2',
    'page3' || '/page3' => '/page3',
    'test2' || '/test2' => '/test2',
    'test3' || '/test3' => '/test3',
    _ => '/notification',
  };

  String get eventKey => messageId ?? jsonEncode([title, body, payload]);

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
