// مدل رسم‌های روی چارت (روند، افقی، فیبوناچی، الیوت) + ذخیره‌سازی
// پورت رفتار نسخه وب (js/drawings.js): نقطه‌ها با زمان کندل (ثانیه) و قیمت ذخیره می‌شوند
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart' show symbolRe;

const drawPointCount = {
  'trend': 2,
  'hline': 1,
  'fib': 2,
  'ewi': 6,
  'ewc': 4,
  'long': 3,
  'short': 3,
  'range': 2,
};
const drawLabels = {
  'ewi': ['0', '1', '2', '3', '4', '5'],
  'ewc': ['0', 'A', 'B', 'C'],
};
const drawHints = {
  'trend': 'خط روند',
  'hline': 'خط افقی',
  'fib': 'فیبوناچی (شروع، پایان)',
  'ewi': 'الیوت ۱-۵',
  'ewc': 'الیوت ABC',
  'long': 'پوزیشن خرید (ورود، حد سود، حد ضرر)',
  'short': 'پوزیشن فروش (ورود، حد سود، حد ضرر)',
  'range': 'بازه قیمت (تغییر، درصد، تعداد کندل)',
};
const fibColors = [
  0xFF9CA3AF,
  0xFFEF5350,
  0xFFF59E0B,
  0xFF26A69A,
  0xFF3B82F6,
  0xFFA855F7,
  0xFF9CA3AF,
  0xFFEC4899,
  0xFF14B8A6,
];
const ivSeconds = {
  '15m': 900,
  '30m': 1800,
  '1h': 3600,
  '4h': 14400,
  '1d': 86400,
  '1w': 604800,
};

class DrawPt {
  int t; // زمان کندل (ثانیه UTC)
  double p; // قیمت
  DrawPt(this.t, this.p);
  Map<String, dynamic> toJson() => {'t': t, 'p': p};
}

class Drawing {
  String id;
  String type; // trend | hline | fib | ewi | ewc
  int color; // ARGB
  bool locked;
  List<DrawPt> pts;
  Drawing({
    required this.id,
    required this.type,
    required this.color,
    this.locked = false,
    required this.pts,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'color': color,
    'locked': locked,
    'pts': pts.map((e) => e.toJson()).toList(),
  };

  static Drawing? fromJson(dynamic j) {
    if (j is! Map) return null;
    final type = j['type'];
    if (type is! String || !drawPointCount.containsKey(type)) return null;
    final rawPts = j['pts'];
    if (rawPts is! List) return null;
    final pts = <DrawPt>[];
    for (final rp in rawPts) {
      if (rp is Map && rp['t'] is num && rp['p'] is num) {
        final t = (rp['t'] as num).toInt();
        final p = (rp['p'] as num).toDouble();
        if (p.isFinite) pts.add(DrawPt(t, p));
      }
      if (pts.length >= drawPointCount[type]!) break;
    }
    final minPts = type == 'hline'
        ? 1
        : (type == 'long' || type == 'short' ? 3 : 2);
    if (pts.length < minPts) return null;
    final c = j['color'];
    return Drawing(
      id: j['id'] is String ? j['id'] as String : newDrawId(),
      type: type,
      color: c is int ? (c | 0xFF000000) : 0xFFF59E0B,
      locked: j['locked'] == true,
      pts: pts,
    );
  }
}

String newDrawId() =>
    'd${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${math.Random().nextInt(9999)}';

Map<String, List<Drawing>> sanitizeDrawings(dynamic raw) {
  final out = <String, List<Drawing>>{};
  if (raw is! Map) return out;
  for (final e in raw.entries.take(200)) {
    final sym = e.key.toString().toUpperCase();
    if (!symbolRe.hasMatch(sym) || e.value is! List) continue;
    final list = <Drawing>[];
    for (final item in (e.value as List).take(100)) {
      final d = Drawing.fromJson(item);
      if (d != null) list.add(d);
    }
    if (list.isNotEmpty) out[sym] = list;
  }
  return out;
}

class DrawingsStore {
  static const _key = 'ta_drawings_v1';
  static Future<Map<String, List<Drawing>>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      return sanitizeDrawings(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Map<String, List<Drawing>> all) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pruned = {
        for (final e in all.entries)
          if (e.value.isNotEmpty)
            e.key: e.value.map((d) => d.toJson()).toList(),
      };
      await prefs.setString(_key, jsonEncode(pruned));
    } catch (_) {}
  }
}
