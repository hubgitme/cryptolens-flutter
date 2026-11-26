// ساخت و خواندن فایل پشتیبان (خالص — بدون وابستگی به Flutter)
// پشتیبان شامل تنظیمات، رسم‌ها و هشدارها می‌شود؛ مقدار هر کلید دقیقاً
// همان رشته JSON ذخیره‌شده در SharedPreferences است تا بازیابی بی‌کم‌وکاست
// همان داده را برگرداند.
import 'dart:convert';

/// کلیدهای SharedPreferences که در پشتیبان می‌آیند.
/// (ta_alerts_last_bg عمداً نیست: فقط زمان آخرین چک پس‌زمینه است و
/// با اولین چک دوباره ساخته می‌شود.)
const backupKeys = ['ta_settings_v1', 'ta_drawings_v1', 'ta_alerts_v1'];

/// از مقدارهای خام ذخیره‌شده (کلید -> رشته JSON) فایل پشتیبان می‌سازد.
String buildBackupFile(Map<String, String> data) {
  final decoded = <String, Object?>{};
  for (final e in data.entries) {
    decoded[e.key] = jsonDecode(e.value);
  }
  return jsonEncode({
    'app': 'cryptolens',
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'data': decoded,
  });
}

/// فایل پشتیبان را می‌خواند و مقدارهای خام (کلید -> رشته JSON) را برمی‌گرداند.
/// اگر فایل مال کریپتو لنز نباشد یا خراب باشد FormatException می‌دهد.
/// کلیدهای ناشناخته نادیده گرفته می‌شوند؛ نبودن یک بخش هم اشکالی ندارد.
Map<String, String> parseBackupFile(String text) {
  final j = jsonDecode(text);
  if (j is! Map<String, dynamic>) {
    throw const FormatException('فایل پشتیبان معتبر نیست');
  }
  if (j['app'] != 'cryptolens' || j['version'] != 1) {
    throw const FormatException('این فایل پشتیبان کریپتو لنز نیست');
  }
  final data = j['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException('فایل پشتیبان داده ندارد');
  }
  final out = <String, String>{};
  for (final k in backupKeys) {
    final v = data[k];
    if (v == null) continue;
    if (k == 'ta_alerts_v1' && v is! List) {
      throw const FormatException('بخش هشدارها خراب است');
    }
    if (k != 'ta_alerts_v1' && v is! Map) {
      throw FormatException('بخش $k خراب است');
    }
    out[k] = jsonEncode(v);
  }
  if (out.isEmpty) {
    throw const FormatException('فایل پشتیبان خالی است');
  }
  return out;
}
