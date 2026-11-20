import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/notifications/fcm_service.dart';
import 'package:flutter_application_1/notifications/notification_click_api.dart';
import 'package:flutter_application_1/notifications/received_message.dart';

class FakeFcmService extends FcmService {
  FakeFcmService(void Function(ReceivedMessage) onOpened, {this.initial})
    : super(onNotificationOpened: onOpened);
  final ReceivedMessage? initial;

  @override
  Future<void> initialize() async {
    if (initial != null) {
      onNotificationOpened?.call(initial!);
    }
  }
}

class RecordingClickApi extends NotificationClickApi {
  final ids = <String>[];
  @override
  Future<void> markClicked(String id) async => ids.add(id);
}

ReceivedMessage fromFcm(String route, String idKey) =>
    ReceivedMessage.fromRemote(
      RemoteMessage.fromMap({
        'messageId': 'fcm-$route',
        'notification': {'title': 'inf mobile test', 'body': 'hahaha'},
        'data': {idKey: 'id-$route', 'route': route, 'extra': 'received-value'},
      }),
      'FCM notification tap',
    );

void main() {
  for (final page in ['test2', 'page2']) {
    testWidgets(
      'cold-start tap opens $page after Navigator is ready with full FCM payload',
      (tester) async {
        final api = RecordingClickApi();
        final message = fromFcm(page, 'Id');
        await tester.pumpWidget(
          MainApp(
            clickApi: api,
            createFcmService: (onOpened) =>
                FakeFcmService(onOpened, initial: message),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(page), findsOneWidget);
        expect(find.text('inf mobile test'), findsOneWidget);
        expect(find.text('hahaha'), findsOneWidget);
        expect(find.text('ID: id-$page'), findsOneWidget);
        expect(find.textContaining('received-value'), findsOneWidget);
        expect(api.ids, ['id-$page']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final page in ['test3', 'page3']) {
    testWidgets(
      'notification tap while running opens $page, and back returns home',
      (tester) async {
        final api = RecordingClickApi();
        late FakeFcmService fcm;
        await tester.pumpWidget(
          MainApp(
            clickApi: api,
            createFcmService: (onOpened) => fcm = FakeFcmService(onOpened),
          ),
        );
        await tester.pumpAndSettle();
        expect(api.ids, isEmpty);
        fcm.onNotificationOpened!(fromFcm('/$page', 'id'));
        await tester.pumpAndSettle();
        expect(find.text(page), findsOneWidget);
        expect(find.text('ID: id-/$page'), findsOneWidget);
        expect(api.ids, ['id-/$page']);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Firebase Cloud Messaging'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
