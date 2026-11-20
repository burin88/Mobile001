import 'package:material_ui/material_ui.dart';

import '../notifications/notification_open_controller.dart';
import '../notifications/received_message.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({
    super.key,
    required this.pageName,
    required this.controller,
    this.message,
  });

  final String pageName;
  final NotificationOpenController controller;
  final ReceivedMessage? message;

  @override
  Widget build(BuildContext context) {
    final received = message;
    return Scaffold(
      appBar: AppBar(title: Text(pageName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (received == null)
              const Text(
                'ยังไม่มีข้อมูลจาก FCM ให้กดแจ้งเตือนที่ส่ง route มายังหน้านี้',
              )
            else ...[
              Text(
                received.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(received.body),
              const Divider(height: 32),
              SelectableText('ID: ${received.id ?? "ไม่ได้ระบุ"}'),
              SelectableText(
                'Route: ${received.requestedRoute ?? "ไม่ได้ระบุ"}',
              ),
              Text('ที่มา: ${received.source}'),
              if (received.destinationRoute == '/notification')
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'ไม่พบหน้าที่ตรงกับ data.route จึงแสดงข้อมูลแจ้งเตือนที่หน้านี้',
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'ข้อมูลจาก FCM',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(received.data.isEmpty ? '{}' : received.data),
              const Divider(height: 32),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final status = controller.statusFor(received);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status.phase == ClickPhase.sending)
                        const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(status.label),
                      if (status.phase == ClickPhase.failed &&
                          received.id != null)
                        TextButton.icon(
                          onPressed: () => controller.retryClick(received),
                          icon: const Icon(Icons.refresh),
                          label: const Text('ส่งสถานะการกดอีกครั้ง'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
