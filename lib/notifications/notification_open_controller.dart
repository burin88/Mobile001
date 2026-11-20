import 'package:flutter/foundation.dart';

import 'notification_click_api.dart';
import 'received_message.dart';

enum ClickPhase { pending, sending, succeeded, failed }

class ClickStatus {
  const ClickStatus(this.phase, this.label);
  final ClickPhase phase;
  final String label;
}

/// All actual notification taps use this path, including cold-start taps.
class NotificationOpenController extends ChangeNotifier {
  NotificationOpenController({required this.onOpen, NotificationClickApi? api})
    : _api = api ?? NotificationClickApi();

  final void Function(ReceivedMessage) onOpen;
  final NotificationClickApi _api;
  final Set<String> _opened = {};
  final Map<String, ClickStatus> _statuses = {};
  bool _disposed = false;

  ClickStatus statusFor(ReceivedMessage message) =>
      _statuses[message.eventKey] ??
      const ClickStatus(ClickPhase.pending, 'ยังไม่ได้ส่งสถานะการกด');

  Future<void> open(ReceivedMessage message, {bool reopen = false}) async {
    if (_disposed) return;
    final firstOpen = _opened.add(message.eventKey);
    if (!firstOpen && !reopen) return;
    // Navigation does not wait for a private-network HTTP request.
    onOpen(message);
    if (firstOpen ||
        (reopen && statusFor(message).phase != ClickPhase.sending)) {
      await _report(message);
    }
  }

  Future<void> retryClick(ReceivedMessage message) async {
    if (statusFor(message).phase != ClickPhase.failed) return;
    await _report(message);
  }

  Future<void> _report(ReceivedMessage message) async {
    if (_disposed) return;
    final id = message.id;
    if (id == null) {
      _set(
        message,
        const ClickStatus(
          ClickPhase.failed,
          'ไม่พบ data.id หรือ data.Id จึงไม่ได้เรียก API',
        ),
      );
      return;
    }
    _set(
      message,
      const ClickStatus(ClickPhase.sending, 'กำลังบันทึกการกดแจ้งเตือน…'),
    );
    try {
      await _api.markClicked(id);
      _set(
        message,
        const ClickStatus(ClickPhase.succeeded, 'บันทึกการกดแจ้งเตือนแล้ว'),
      );
    } catch (error) {
      _set(message, ClickStatus(ClickPhase.failed, 'บันทึกไม่สำเร็จ: $error'));
    }
  }

  void _set(ReceivedMessage message, ClickStatus status) {
    if (_disposed) return;
    _statuses[message.eventKey] = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _api.dispose();
    super.dispose();
  }
}
