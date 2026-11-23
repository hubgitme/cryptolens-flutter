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
  IndCfg(this.on, this.params);
  num p(String k, num def) => params[k] ?? def;
  Map<String, dynamic> toJson() => {'on': on, 'params': params};
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
    return IndCfg(j?['on'] is bool ? j!['on'] as bool : defOn, params);
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

class AppSettings {
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
