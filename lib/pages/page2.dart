import 'package:material_ui/material_ui.dart';

import '../notifications/notification_open_controller.dart';
import '../notifications/received_message.dart';
import 'notification_page.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key, required this.controller, this.message});

  static const routeName = '/page2';
  final NotificationOpenController controller;
  final ReceivedMessage? message;

  @override
  Widget build(BuildContext context) => NotificationPage(
    pageName: 'page2',
    controller: controller,
    message: message,
  );
}
