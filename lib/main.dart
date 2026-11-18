import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'notifications/fcm_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  final _fcm = FcmService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_fcm.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _fcm.ready) {
      unawaited(_fcm.refreshToken());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Mobile',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Cloud Messaging')),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _fcm,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Android · burin-test',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _fcm.ready ? 'เชื่อมต่อ Firebase แล้ว' : 'ยังไม่พร้อมใช้งาน',
                ),
                Text('สิทธิ์แจ้งเตือน: ${_fcm.permissionLabel}'),
                if (_fcm.busy) const LinearProgressIndicator(),
                if (_fcm.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SelectableText(
                      _fcm.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: !_fcm.ready || _fcm.busy
                          ? null
                          : _fcm.requestPermission,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('อนุญาตการแจ้งเตือน'),
                    ),
                    OutlinedButton(
                      onPressed: _fcm.busy
                          ? null
                          : () => _fcm.ready
                                ? _fcm.refreshToken()
                                : _fcm.initialize(),
                      child: const Text('รีเฟรช / ลองใหม่'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'FCM registration token',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(_fcm.token ?? 'กำลังรอ token จากอุปกรณ์'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _fcm.token == null
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: _fcm.token!),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('คัดลอก token แล้ว'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('คัดลอก token'),
                  ),
                ),
                const Divider(height: 40),
                Text(
                  'ข้อความล่าสุด',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (_fcm.messages.isEmpty)
                  const Text(
                    'นำ token ไปใส่ใน Firebase Console > Messaging > Send test message',
                  ),
                for (final message in _fcm.messages)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(message.body),
                          if (message.data.isNotEmpty)
                            SelectableText(message.data),
                          const SizedBox(height: 8),
                          Text(
                            message.source,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
