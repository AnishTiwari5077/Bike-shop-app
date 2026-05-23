import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  final List<Map<String, String>> _notifications = [];
  int _unreadCount = 0;
  static const String _storageKey = 'notifications';

  NotificationProvider() {
    _loadNotifications();
  }

  List<Map<String, String>> get notifications => [..._notifications];
  int get unreadCount => _unreadCount;

  void addNotification(String title, String body) {
    _notifications.insert(0, {
      'title': title,
      'body': body,
      'time': _formatTime(DateTime.now()),
      'isRead': 'false',
    });
    _unreadCount++;
    _saveNotifications();
    notifyListeners();
  }

  void markAllAsRead() {
    for (var notif in _notifications) {
      notif['isRead'] = 'true';
    }
    _unreadCount = 0;
    _saveNotifications();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    _saveNotifications();
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

  // ─── SharedPreferences persistence ───────────────────────────────────
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _notifications.clear();
      int unread = 0;
      for (var item in decoded) {
        final map = Map<String, String>.from(item);
        _notifications.add(map);
        if (map['isRead'] != 'true') unread++;
      }
      _unreadCount = unread;
      debugPrint('✅ Loaded ${_notifications.length} notifications');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_notifications);
    await prefs.setString(_storageKey, jsonString);
  }
}
