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

  static const _lastBgKey = 'ta_alerts_last_bg';

  /// آخرین باری که چک پس‌زمینه واقعاً اجرا شد + چند هشدار در آن شلیک شد؛
  /// برای اینکه کاربر ببیند پس‌زمینه کار می‌کند یا سیستم آن را خفه کرده.
  static Future<void> saveLastBgCheck(DateTime at, int fired) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastBgKey,
        jsonEncode({'at': at.toIso8601String(), 'fired': fired}),
      );
    } catch (_) {}
  }

  static Future<({DateTime at, int fired})?> loadLastBgCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastBgKey);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(j['at'] is String ? j['at'] as String : '');
      if (at == null) return null;
      return (
        at: at,
        fired: j['fired'] is num ? (j['fired'] as num).toInt() : 0,
      );
    } catch (_) {
      return null;
    }
  }
}
