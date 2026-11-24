// تنظیمات برنامه + ذخیره‌سازی با shared_preferences (پیش‌فرض‌ها مثل نسخه وب)
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const topCoins = [
  'BTCUSDT',
  'ETHUSDT',
  'BNBUSDT',
  'SOLUSDT',
  'CRVUSDT',
  'ADAUSDT',
  'XLMUSDT',
  'DOGEUSDT',
  'NEARUSDT',
  'XRPUSDT',
  'GRAMUSDT',
  'SUIUSDT',
  'PEPEUSDT',
];
const intervals = ['15m', '30m', '1h', '4h', '1d', '1w'];
final symbolRe = RegExp(r'^[A-Za-z0-9]{2,20}$');

class IndCfg {
  bool on;
  Map<String, num> params;
  int? color; // ARGB؛ null = رنگ پیش‌فرض همان اندیکاتور (خط اول)
  List<int>? lineColors; // رنگ جداگانه هر خط؛ null = پیش‌فرض وب
  double width;
  IndCfg(this.on, this.params, {this.color, this.lineColors, this.width = 1.2});
  num p(String k, num def) => params[k] ?? def;
  Map<String, dynamic> toJson() => {
    'on': on,
    'params': params,
    if (color != null) 'color': color,
    if (lineColors != null) 'lineColors': lineColors,
    'width': width,
  };
  factory IndCfg.fromJson(
    Map<String, dynamic>? j,
    bool defOn,
    Map<String, num> defParams,
  ) {
    final params = Map<String, num>.from(defParams);
    final raw = j?['params'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num && params.containsKey(k)) params[k.toString()] = v;
      });
    }
    final c = j?['color'];
    final w = j?['width'];
    List<int>? lcs;
    final rawLc = j?['lineColors'];
    if (rawLc is List) {
      lcs = rawLc.whereType<int>().map((x) => x | 0xFF000000).take(8).toList();
      if (lcs.isEmpty) lcs = null;
    }
    return IndCfg(
      j?['on'] is bool ? j!['on'] as bool : defOn,
      params,
      color: c is int ? (c | 0xFF000000) : null,
      lineColors: lcs,
      width: w is num ? w.toDouble().clamp(0.5, 4) : 1.2,
    );
  }
}

Map<String, IndCfg> _defaultIndicators() => {
  'rsi': IndCfg(true, {'period': 14, 'ob': 70, 'os': 30}),
  'macd': IndCfg(true, {'fast': 12, 'slow': 26, 'sig': 9}),
  'stoch': IndCfg(false, {'k': 14, 'd': 3, 'smooth': 3}),
  'atr': IndCfg(false, {'period': 14}),
  'obv': IndCfg(false, {'sma': 20}),
  'rsisma': IndCfg(false, {'period': 14, 'sma': 9, 'hi': 70, 'lo': 40}),
  'roc': IndCfg(false, {'period': 9}),
  'rocma': IndCfg(false, {'period': 9, 'sma': 14}),
  'adx': IndCfg(false, {'period': 14}),
  'cci': IndCfg(false, {'period': 20}),
  'wpr': IndCfg(false, {'period': 14}),
  'mom': IndCfg(false, {'period': 10}),
  'mfi': IndCfg(false, {'period': 14}),
};

Map<String, IndCfg> _defaultOverlays() => {
  'sma': IndCfg(false, {'period': 20}),
  'ema': IndCfg(false, {'period': 20}),
  'bb': IndCfg(false, {'period': 20, 'mult': 2}),
  'vwap': IndCfg(false, {}),
  'alligator': IndCfg(false, {'jaw': 13, 'teeth': 8, 'lips': 5}),
  'volume': IndCfg(false, {}),
};

const defaultPaneOrder = [
  'rsi',
  'rsisma',
  'macd',
  'stoch',
  'atr',
  'obv',
  'roc',
  'rocma',
  'adx',
  'cci',
  'wpr',
  'mom',
  'mfi',
];

class AppSettings {
  AppSettings();

  String symbol = 'BTCUSDT';
  String iv = '4h';
  int limit = 500;
  String chartType = 'candles'; // candles | ha
  int refresh = 60; // ثانیه؛ 0 = خاموش
  String apiBase =
      ''; // خالی = مستقیم Binance؛ وگرنه آدرس پروکسی کاربر (مثل Vercel)
  List<String> savedSymbols = [];
  List<String> watchlistHidden = [];
  String watchlistSort = 'default'; // default | change | volume
  Map<String, IndCfg> indicators = _defaultIndicators();
  Map<String, IndCfg> overlays = _defaultOverlays();
  List<String> paneOrder = List.of(defaultPaneOrder);
  Map<String, double> paneHeights =
      {}; // ارتفاع هر پنل (+ 'price')؛ خالی = پیش‌فرض
  bool magnet = true; // چسبیدن نقطه رسم به OHLC
  bool lockAll = false; // قفل همه رسم‌ها
  int drawColor = 0xFFF59E0B; // رنگ پیش‌فرض رسم تازه
  List<double> fibLevels = [
    0,
    0.236,
    0.382,
    0.5,
    0.618,
    0.786,
    1,
    1.272,
    1.618,
  ];

  List<String> get watchlistSymbols => {
    ...topCoins,
    ...savedSymbols,
  }.where((s) => !watchlistHidden.contains(s)).toList();

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'iv': iv,
    'limit': limit,
    'chartType': chartType,
    'refresh': refresh,
    'apiBase': apiBase,
    'savedSymbols': savedSymbols,
    'watchlistHidden': watchlistHidden,
    'watchlistSort': watchlistSort,
    'indicators': indicators.map((k, v) => MapEntry(k, v.toJson())),
    'overlays': overlays.map((k, v) => MapEntry(k, v.toJson())),
    'paneOrder': paneOrder,
    'paneHeights': paneHeights,
    'magnet': magnet,
    'lockAll': lockAll,
    'drawColor': drawColor,
    'fibLevels': fibLevels,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    if (j['symbol'] is String && symbolRe.hasMatch(j['symbol'] as String)) {
      s.symbol = (j['symbol'] as String).toUpperCase();
    }
    if (intervals.contains(j['iv'])) s.iv = j['iv'] as String;
    if (j['limit'] is num)
      s.limit = (j['limit'] as num).toInt().clamp(100, 1000);
    if (j['chartType'] == 'ha') s.chartType = 'ha';
    if ([0, 15, 30, 60, 300].contains(j['refresh']))
      s.refresh = j['refresh'] as int;
    if (j['apiBase'] is String) s.apiBase = (j['apiBase'] as String).trim();
    List<String> strList(dynamic v) => v is List
        ? v
              .whereType<String>()
              .where((x) => symbolRe.hasMatch(x))
              .map((x) => x.toUpperCase())
              .toSet()
              .take(100)
              .toList()
        : [];
    s.savedSymbols = strList(j['savedSymbols']);
    s.watchlistHidden = strList(j['watchlistHidden']);
    if (['default', 'change', 'volume'].contains(j['watchlistSort'])) {
      s.watchlistSort = j['watchlistSort'] as String;
    }
    void loadMap(dynamic raw, Map<String, IndCfg> into) {
      if (raw is Map) {
        into.forEach((k, def) {
          final v = raw[k];
          if (v is Map<String, dynamic>)
            into[k] = IndCfg.fromJson(v, def.on, def.params);
        });
      }
    }

    loadMap(j['indicators'], s.indicators);
    loadMap(j['overlays'], s.overlays);
    if (j['paneOrder'] is List) {
      final seen = <String>{};
      final order = <String>[];
      for (final k in (j['paneOrder'] as List).whereType<String>()) {
        if (s.indicators.containsKey(k) && seen.add(k)) order.add(k);
      }
      for (final k in defaultPaneOrder) {
        if (seen.add(k)) order.add(k);
      }
      s.paneOrder = order;
    }
    if (j['paneHeights'] is Map) {
      final m = <String, double>{};
      (j['paneHeights'] as Map).forEach((k, v) {
        if (k is String &&
            v is num &&
            (k == 'price' || s.indicators.containsKey(k))) {
          m[k] = v.toDouble().clamp(60, 1500);
        }
      });
      s.paneHeights = m;
    }
    if (j['magnet'] is bool) s.magnet = j['magnet'] as bool;
    if (j['lockAll'] is bool) s.lockAll = j['lockAll'] as bool;
    if (j['drawColor'] is int) {
      s.drawColor = (j['drawColor'] as int) | 0xFF000000;
    }
    if (j['fibLevels'] is List) {
      final f = (j['fibLevels'] as List)
          .whereType<num>()
          .map((x) => x.toDouble())
          .where((x) => x.isFinite && x >= -10 && x <= 20)
          .take(15)
          .toList();
      if (f.isNotEmpty) s.fibLevels = f;
    }
    return s;
  }
}

class SettingsStore {
  static const _key = 'ta_settings_v1';
  static Future<AppSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return AppSettings();
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  static Future<void> save(AppSettings s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(s.toJson()));
    } catch (_) {}
  }
}
