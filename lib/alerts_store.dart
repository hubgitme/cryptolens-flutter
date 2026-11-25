// ذخیره‌سازی قوانین هشدار با shared_preferences
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'alerts.dart';

class AlertsStore {
  static const _key = 'ta_alerts_v1';

  static Future<List<AlertRule>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(AlertRule.fromJson)
          .where((r) => r.id.isNotEmpty)
          .take(100)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<AlertRule> rules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(rules.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }
}
