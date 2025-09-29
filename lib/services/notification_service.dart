import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_item.dart';

class NotificationService {
  static const _kKey = 'app_notifications_v1';
  static NotificationService? _instance;
  late SharedPreferences _prefs;

  final ValueNotifier<List<NotificationItem>> notifications = ValueNotifier([]);

  NotificationService._internal();

  static Future<NotificationService> getInstance() async {
    if (_instance != null) return _instance!;
    final svc = NotificationService._internal();
    await svc._init();
    _instance = svc;
    return svc;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_kKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        notifications.value = list.map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {
        notifications.value = [];
      }
    }
  }

  Future<void> add(NotificationItem item) async {
    final list = List<NotificationItem>.from(notifications.value);
    list.insert(0, item);
    notifications.value = list;
    await _save();
  }

  // Helper para adicionar a partir de payload simples (título + corpo)
  Future<void> addLocalFromPayload({required String title, required String body}) async {
    final item = NotificationItem(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, body: body, createdAt: DateTime.now());
    await add(item);
  }

  Future<void> markRead(String id, {bool read = true}) async {
    final list = notifications.value.map((n) => n.id == id ? NotificationItem(id: n.id, title: n.title, body: n.body, createdAt: n.createdAt, read: read) : n).toList();
    notifications.value = list;
    await _save();
  }

  Future<void> remove(String id) async {
    notifications.value = notifications.value.where((n) => n.id != id).toList();
    await _save();
  }

  Future<void> clear() async {
    notifications.value = [];
    await _save();
  }

  Future<void> _save() async {
    final raw = jsonEncode(notifications.value.map((n) => n.toJson()).toList());
    await _prefs.setString(_kKey, raw);
  }
}
