// پشتیبان‌گیری و بازیابی: تنظیمات + رسم‌ها + هشدارها در یک فایل JSON.
// خروجی با منوی اشتراک‌گذاری سیستم فرستاده می‌شود (ذخیره در درایو،
// تلگرام، …) و ورودی با انتخاب فایل خوانده می‌شود؛ نیازی به دسترسی
// حافظه نیست.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_service.dart';
import 'backup_codec.dart';

class BackupService {
  /// فایل پشتیبان می‌سازد و منوی اشتراک‌گذاری را باز می‌کند.
  static Future<void> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{};
    for (final k in backupKeys) {
      final raw = prefs.getString(k);
      if (raw != null) data[k] = raw;
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/cryptolens-backup-${_stamp(DateTime.now())}.json',
    );
    await file.writeAsString(buildBackupFile(data));
    await Share.shareXFiles([XFile(file.path)], text: 'پشتیبان کریپتو لنز');
  }

  /// فایل پشتیبان را از کاربر می‌گیرد و جایگزین داده‌های فعلی می‌کند.
  /// نتیجه را برمی‌گرداند تا صفحه پیام مناسب را نشان دهد.
  static Future<({bool ok, String message})> importBackup() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = res?.files.single.path;
      if (path == null) {
        return (ok: false, message: 'فایلی انتخاب نشد');
      }
      final text = await File(path).readAsString();
      final data = parseBackupFile(text);
      final prefs = await SharedPreferences.getInstance();
      for (final e in data.entries) {
        await prefs.setString(e.key, e.value);
      }
      // هشدارهای بازیابی‌شده باید در پس‌زمینه هم ثبت شوند.
      await AlertService.syncBackgroundTask();
      return (ok: true, message: 'بازیابی انجام شد');
    } on FormatException catch (e) {
      return (ok: false, message: 'فایل پشتیبان معتبر نیست: ${e.message}');
    } catch (_) {
      return (ok: false, message: 'بازیابی انجام نشد');
    }
  }

  static String _stamp(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${p2(d.month)}${p2(d.day)}-${p2(d.hour)}${p2(d.minute)}';
  }
}
