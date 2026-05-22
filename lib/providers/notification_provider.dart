import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final List<Map<String, String>> _notifications = [];
  int _unreadCount = 0;

  List<Map<String, String>> get notifications => [..._notifications];
  int get unreadCount => _unreadCount;

  void addNotification(String title, String body) {
    _notifications.insert(0, {
      'title': title,
      'body': body,
      'time': _formatTime(DateTime.now()),
      'isRead': 'false', // stored as string for simplicity
    });
    _unreadCount++;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var notif in _notifications) {
      notif['isRead'] = 'true';
    }
    _unreadCount = 0;
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
