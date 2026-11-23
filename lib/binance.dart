// دریافت داده از Binance — مستقیم (بدون سرور واسط) با چند هاست جایگزین؛
// اگر کاربر آدرس پروکسی خودش (مثل دیپلوی Vercel نسخه وب) را در تنظیمات بگذارد، از همان استفاده میشود.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

const _binanceBases = [
  'https://data-api.binance.vision',
  'https://api.binance.com',
  'https://api1.binance.com',
  'https://api2.binance.com',
  'https://api3.binance.com',
  'https://api4.binance.com',
];

Future<dynamic> _getJson(String path, String? customBase) async {
  final bases = (customBase != null && customBase.isNotEmpty)
      ? [customBase]
      : _binanceBases;
  Object? lastErr;
  for (final base in bases) {
    try {
      final res = await http
          .get(Uri.parse('$base$path'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return jsonDecode(res.body);
    } catch (e) {
      lastErr = e;
    }
  }
  throw Exception('دریافت داده ناموفق بود: $lastErr');
}

Future<List<Candle>> fetchKlines(
  String symbol,
  String iv,
  int limit, {
  String? customBase,
}) async {
  final useProxy = customBase != null && customBase.isNotEmpty;
  final path = useProxy
      ? '/api/klines?symbol=$symbol&interval=$iv&limit=$limit'
      : '/api/v3/klines?symbol=$symbol&interval=$iv&limit=$limit';
  final data = await _getJson(path, customBase);
  if (useProxy) {
    final m = data as Map<String, dynamic>;
    if (m['success'] != true) throw Exception(m['error'] ?? 'خطای سرور');
    return (m['data'] as List).map((e) {
      final x = e as Map<String, dynamic>;
      return Candle(
        (x['time'] as num).toInt(),
        (x['open'] as num).toDouble(),
        (x['high'] as num).toDouble(),
        (x['low'] as num).toDouble(),
        (x['close'] as num).toDouble(),
        (x['volume'] as num).toDouble(),
      );
    }).toList();
  }
  return (data as List).map((e) {
    final x = e as List;
    return Candle(
      (x[0] as num).toInt() ~/ 1000,
      double.parse(x[1].toString()),
      double.parse(x[2].toString()),
      double.parse(x[3].toString()),
      double.parse(x[4].toString()),
      double.parse(x[5].toString()),
    );
  }).toList();
}

Future<List<Ticker>> fetchTickers(
  List<String> symbols, {
  String? customBase,
}) async {
  final useProxy = customBase != null && customBase.isNotEmpty;
  final path = useProxy
      ? '/api/tickers?symbols=${Uri.encodeComponent(symbols.join(','))}'
      : '/api/v3/ticker/24hr?symbols=${Uri.encodeComponent(jsonEncode(symbols))}';
  final data = await _getJson(path, customBase);
  if (useProxy) {
    final m = data as Map<String, dynamic>;
    if (m['success'] != true) throw Exception(m['error'] ?? 'خطای سرور');
    return (m['data'] as List).map((e) {
      final x = e as Map<String, dynamic>;
      return Ticker(
        x['symbol'].toString(),
        (x['price'] as num).toDouble(),
        (x['change24h'] as num).toDouble(),
        (x['volume'] as num).toDouble(),
      );
    }).toList();
  }
  final bySymbol = <String, Ticker>{};
  for (final e in data as List) {
    final x = e as Map<String, dynamic>;
    bySymbol[x['symbol'].toString()] = Ticker(
      x['symbol'].toString(),
      double.parse(x['lastPrice'].toString()),
      double.parse(x['priceChangePercent'].toString()),
      double.parse(x['quoteVolume'].toString()),
    );
  }
  return symbols.map((s) => bySymbol[s]).whereType<Ticker>().toList();
}
