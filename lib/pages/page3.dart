import 'package:material_ui/material_ui.dart';

import '../notifications/notification_open_controller.dart';
import '../notifications/received_message.dart';
import 'notification_page.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key, required this.controller, this.message});

  static const routeName = '/page3';
  final NotificationOpenController controller;
  final ReceivedMessage? message;

  @override
  Widget build(BuildContext context) => NotificationPage(
    pageName: 'page3',
    controller: controller,
    message: message,
  );
}
