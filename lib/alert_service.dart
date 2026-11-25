// سرویس هشدار: نوتیفیکیشن محلی + چک پس‌زمینه (Workmanager هر ۱۵ دقیقه)
// + چک پیش‌زمینه با هر بروزرسانی چارت.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'alerts.dart';
import 'alerts_store.dart';
import 'binance.dart';
import 'models.dart';
import 'settings.dart';

@pragma('vm:entry-point')
void alertCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await AlertService.runBackgroundCheck();
    } catch (_) {}
    return Future.value(true);
  });
}

class AlertService {
  static const _taskUniqueName = 'cryptolens-alerts';
  static const _taskName = 'cryptolens-alert-check';
  static const _channelId = 'cryptolens_alerts';
  static const _channelName = 'هشدارهای کریپتو لنز';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'هشدار قیمت و کراس اندیکاتورها',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
  );

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );
    await Workmanager().initialize(alertCallbackDispatcher);
    await syncBackgroundTask();
  }

  /// درخواست اجازه اعلان (اندروید ۱۳+)؛ true یعنی اجازه داده شد.
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _details);
  }

  static Future<void> showTest() async {
    await showAlert(
      id: 999001,
      title: '🔔 کریپتو لنز',
      body: 'اعلان آزمایشی — هشدارها فعال‌اند.',
    );
  }

  /// اگر حداقل یک هشدار فعال هست، تسک دوره‌ای را ثبت می‌کند؛
  /// وگرنه آن را لغو می‌کند.
  static Future<void> syncBackgroundTask() async {
    try {
      final rules = await AlertsStore.load();
      if (rules.any((r) => r.enabled)) {
        await Workmanager().registerPeriodicTask(
          _taskUniqueName,
          _taskName,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        );
      } else {
        await Workmanager().cancelByUniqueName(_taskUniqueName);
      }
    } catch (_) {}
  }

  // کش کندل‌های تایم‌فریم‌های غیر از چارت فعلی (حداکثر ۶۰ ثانیه) تا با
  // هر رفرش چارت دوباره دانلود نشوند.
  static final _otherIntervalCache =
      <String, ({List<Candle> candles, DateTime at})>{};

  /// چک پیش‌زمینه: همه هشدارهای فعال همین نماد ارزیابی می‌شوند، در هر
  /// تایم‌فریمی که باشند؛ تایم‌فریم چارت با کندل‌های همین چارت، بقیه با
  /// یک دانلود (کش‌شده ۶۰ ثانیه). بدون دانلود اضافه برای تایم‌فریم چارت.
  static Future<List<FiredAlert>> checkForeground(
    String symbol,
    String interval,
    List<Candle> candles,
  ) async {
    final rules = await AlertsStore.load();
    final mine = rules.where((r) => r.enabled && r.symbol == symbol).toList();
    if (mine.isEmpty) return const [];
    String? apiBase;
    try {
      apiBase = (await SettingsStore.load()).apiBase;
    } catch (_) {}
    final byKey = <String, List<Candle>>{'$symbol|$interval': candles};
    final now = DateTime.now();
    for (final r in mine) {
      if (r.interval == interval) continue;
      final key = '${r.symbol}|${r.interval}';
      if (byKey.containsKey(key)) continue;
      final cached = _otherIntervalCache[key];
      if (cached != null && now.difference(cached.at).inSeconds < 60) {
        byKey[key] = cached.candles;
        continue;
      }
      try {
        final data = await fetchKlines(
          r.symbol,
          r.interval,
          150,
          customBase: apiBase,
        );
        byKey[key] = data;
        _otherIntervalCache[key] = (candles: data, at: now);
      } catch (_) {}
    }
    final fired = evaluateAll(mine, byKey);
    for (final f in fired) {
      try {
        await showAlert(
          id: f.rule.notifId,
          title: '🔔 ${f.rule.symbol} — ${f.rule.kindLabel}',
          body: f.message,
        );
      } catch (_) {}
    }
    await AlertsStore.save(rules); // ذخیره پرچم‌های armed
    return fired;
  }

  /// چک پس‌زمینه (در ایزوله جدا اجرا می‌شود): برای هر (نماد، تایم‌فریم)
  /// متمایز یک بار کندل می‌گیرد و همه هشدارهای فعال را ارزیابی می‌کند.
  static Future<void> runBackgroundCheck() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(android: androidInit));
    final rules = await AlertsStore.load();
    final enabled = rules.where((r) => r.enabled).toList();
    if (enabled.isEmpty) return;

    String? apiBase;
    try {
      apiBase = (await SettingsStore.load()).apiBase;
    } catch (_) {}

    final keys = <String>{for (final r in enabled) '${r.symbol}|${r.interval}'};
    final byKey = <String, List<Candle>>{};
    for (final key in keys) {
      final parts = key.split('|');
      try {
        byKey[key] = await fetchKlines(
          parts[0],
          parts[1],
          150,
          customBase: apiBase,
        );
      } catch (_) {}
    }
    final fired = evaluateAll(enabled, byKey);
    for (final f in fired) {
      try {
        await plugin.show(
          f.rule.notifId,
          '🔔 ${f.rule.symbol} — ${f.rule.kindLabel}',
          f.message,
          _details,
        );
      } catch (_) {}
    }
    await AlertsStore.save(rules);
  }
}
