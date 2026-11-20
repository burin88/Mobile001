import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationClickException implements Exception {
  const NotificationClickException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NotificationClickApi {
  NotificationClickApi({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       endpoint =
           endpoint ??
           Uri.parse(
             const String.fromEnvironment(
               'FCM_CLICK_URL',
               defaultValue: 'https://192.168.199.131:5000/api/noti/fcm/click',
             ),
           );

  final http.Client _client;
  final Uri endpoint;
  final Duration timeout;

  Future<void> markClicked(String id) async {
    try {
      final response = await _client
          .patch(
            endpoint,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'id': id}),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NotificationClickException(
          'API ตอบกลับ HTTP ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw const NotificationClickException(
        'หมดเวลารอ API ยังไม่ทราบผลการบันทึกบนเซิร์ฟเวอร์',
      );
    } on http.ClientException {
      throw const NotificationClickException(
        'ติดต่อ API ไม่สำเร็จ ตรวจสอบเครือข่ายและ HTTPS certificate',
      );
    }
  }

  void dispose() => _client.close();
}
