import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LocalNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'budget', 'slab', 'power', 'peak'
  final DateTime timestamp;
  final bool isRead;

  LocalNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory LocalNotificationItem.fromJson(Map<String, dynamic> json) => LocalNotificationItem(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    type: json['type'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
  );

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM dd').format(timestamp);
  }
}

class NotificationProvider extends ChangeNotifier {
  List<LocalNotificationItem> _notifications = [];
  List<LocalNotificationItem> get notifications => _notifications;

  NotificationProvider() {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('local_notifications_history');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _notifications = decoded.map((item) => LocalNotificationItem.fromJson(item)).toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> addNotification(String title, String body, String type) async {
    final newNotif = LocalNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, newNotif);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = LocalNotificationItem(
        id: old.id,
        title: old.title,
        body: old.body,
        type: old.type,
        timestamp: old.timestamp,
        isRead: true,
      );
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString('local_notifications_history', data);
  }
}
