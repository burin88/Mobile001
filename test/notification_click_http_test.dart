import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/notifications/notification_click_api.dart';
import 'package:flutter_application_1/notifications/notification_open_controller.dart';
import 'package:flutter_application_1/notifications/received_message.dart';

void main() {
  late HttpServer server;
  late NotificationOpenController controller;
  late List<Map<String, dynamic>> requests;
  late List<String> destinations;
  late int responseCode;
  late Duration responseDelay;

  ReceivedMessage message({
    Map<String, dynamic>? data,
    String messageId = 'message-1',
  }) => ReceivedMessage(
    title: 'inf mobile test',
    body: 'hahaha',
    source: 'test',
    messageId: messageId,
    data: data ?? {'Id': 'noti-123', 'route': 'test2'},
  );

  setUp(() async {
    requests = [];
    destinations = [];
    responseCode = 204;
    responseDelay = Duration.zero;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add({
        'method': request.method,
        'path': request.uri.path,
        'contentType': request.headers.contentType?.mimeType,
        'accept': request.headers.value('accept'),
        'body': jsonDecode(await utf8.decoder.bind(request).join()),
      });
      if (responseDelay != Duration.zero) {
        await Future<void>.delayed(responseDelay);
      }
      request.response.statusCode = responseCode;
      await request.response.close();
    });
    controller = NotificationOpenController(
      api: NotificationClickApi(
        endpoint: Uri.parse(
          'http://127.0.0.1:${server.port}/api/noti/fcm/click',
        ),
        timeout: const Duration(milliseconds: 500),
      ),
      onOpen: (message) => destinations.add(message.destinationRoute),
    );
  });

  tearDown(() async {
    controller.dispose();
    await server.close(force: true);
  });

  test('tap navigates immediately and PATCH sends the exact contract, accepting Id', () async {
    final received = message();
    final opened = controller.open(received);
    expect(destinations, ['/test2']);
    expect(controller.statusFor(received).phase, ClickPhase.sending);
    await opened;
    expect(requests, [
      {
        'method': 'PATCH',
        'path': '/api/noti/fcm/click',
        'contentType': 'application/json',
        'accept': 'application/json',
        'body': {'id': 'noti-123'},
      },
    ]);
    expect(controller.statusFor(received).phase, ClickPhase.succeeded);
  });

  test('lowercase id and /test3 work; duplicate callbacks do not send twice', () async {
    final received = message(
      data: {'id': 'lower-id', 'Id': 'other-id', 'route': '/test3'},
    );
    await Future.wait([controller.open(received), controller.open(received)]);
    expect(requests, hasLength(1));
    expect(requests.single['body'], {'id': 'lower-id'});
    // A later, explicit user click is a new click, unlike duplicate callbacks.
    await controller.open(received, reopen: true);
    expect(destinations, ['/test3', '/test3']);
    expect(requests, hasLength(2));
  });

  test('HTTP failure keeps destination available and retries only on explicit action', () async {
    responseCode = 500;
    final received = message();
    await controller.open(received);
    expect(destinations, ['/test2']);
    expect(controller.statusFor(received).phase, ClickPhase.failed);
    expect(controller.statusFor(received).label, contains('HTTP 500'));
    await controller.open(received);
    expect(requests, hasLength(1));
    responseCode = 200;
    await controller.retryClick(received);
    expect(requests, hasLength(2));
    expect(destinations, ['/test2']);
    expect(controller.statusFor(received).phase, ClickPhase.succeeded);
  });

  test(
    'unknown route and missing id show details without making an invalid PATCH',
    () async {
      final received = message(data: {'route': 'https://example.com/test2'});
      await controller.open(received);
      expect(destinations, ['/notification']);
      expect(requests, isEmpty);
      expect(controller.statusFor(received).label, contains('ไม่พบ data.id'));
    },
  );

  test(
    'request timeout preserves navigation and does not retry automatically',
    () async {
      responseDelay = const Duration(milliseconds: 750);
      final received = message();
      await controller.open(received);
      expect(destinations, ['/test2']);
      expect(controller.statusFor(received).phase, ClickPhase.failed);
      expect(controller.statusFor(received).label, contains('หมดเวลารอ API'));
      expect(requests, hasLength(1));
      // Let the stand-in finish: timeout does not prove the provider did not write.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(requests, hasLength(1));
    },
  );
}
