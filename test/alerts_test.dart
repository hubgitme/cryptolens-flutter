// تست‌های هشدارها — ارزیابی خالص (بدون Flutter)
import 'package:cryptolens_app/alerts.dart';
import 'package:cryptolens_app/indicators.dart';
import 'package:cryptolens_app/models.dart';
import 'package:flutter_test/flutter_test.dart';

List<Candle> candles(List<double> closes) => List<Candle>.generate(
  closes.length,
  (i) => Candle(i * 60, closes[i], closes[i], closes[i], closes[i], 100),
);

AlertRule rule(String kind, {double? level, int period = 20}) => AlertRule(
  id: 't-$kind',
  symbol: 'BTCUSDT',
  kind: kind,
  level: level,
  period: period,
  fast: 9,
  slow: 21,
  interval: '1h',
);

void main() {
  test('kind table has unique ids and covers all indicators', () {
    final ids = alertKinds.map((k) => k.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.length, greaterThanOrEqualTo(50));
    for (final id in [
      'priceAbove',
      'smaCrossUp',
      'emaCrossUp',
      'bbUpperUp',
      'vwapCrossUp',
      'alligatorUp',
      'rsiAbove',
      'macdCrossUp',
      'stochCrossUp',
      'rocCrossZeroUp',
      'cciAbove',
      'wprAbove',
      'mfiAbove',
      'momCrossZeroUp',
      'adxAbove',
      'atrAbove',
      'obvCrossSmaUp',
    ]) {
      expect(ids, contains(id));
    }
  });

  test('priceAbove fires immediately when already above the level', () {
    // رگرسیون باگ گزارش‌شده: هشدار ساخته‌شده وقتی قیمت همین حالا هم
    // بالاتر از سطح است باید در اولین چک زنگ بزند، نه فقط لحظه عبور.
    final r = rule('priceAbove', level: 100);
    const key = 'BTCUSDT|1h';
    final fired = evaluateAll(
      [r],
      {
        key: candles([101, 102, 103]),
      },
    );
    expect(fired.length, 1);
    expect(r.armed, isFalse);
  });

  test('priceAbove fires once and re-arms after dipping below', () {
    final r = rule('priceAbove', level: 100);
    const key = 'BTCUSDT|1h';
    var fired = evaluateAll(
      [r],
      {
        key: candles([98, 99, 101]),
      },
    );
    expect(fired.length, 1);
    // همان کندل‌ها دوباره: نباید دوباره شلیک شود
    fired = evaluateAll(
      [r],
      {
        key: candles([98, 99, 101]),
      },
    );
    expect(fired, isEmpty);
    // برگشت به زیر سطح: دوباره مسلح می‌شود
    fired = evaluateAll(
      [r],
      {
        key: candles([98, 99, 101, 99]),
      },
    );
    expect(fired, isEmpty);
    expect(r.armed, isTrue);
    // عبور دوباره: شلیک
    fired = evaluateAll(
      [r],
      {
        key: candles([98, 99, 101, 99, 102]),
      },
    );
    expect(fired.length, 1);
  });

  test('priceBelow fires on crossing down', () {
    final r = rule('priceBelow', level: 100);
    final ev = evaluateRule(r, candles([102, 101, 99]));
    expect(ev.hit, isTrue);
    expect(evaluateRule(r, candles([102, 101, 100.5])).hit, isFalse);
  });

  test('rsiAbove fires when RSI is above the level at the last candle', () {
    // نزول بعد صعود: RSI بالا می‌آید؛ همین که آخرین مقدار بالای ۷۰ باشد
    // کافی است، لازم نیست عبور دقیقاً در آخرین کندل رخ داده باشد.
    final down = [for (var i = 0; i < 20; i++) 100.0 - i];
    var found = false;
    for (var k = 1; k <= 30; k++) {
      final closes = [...down, for (var j = 1; j <= k; j++) 81.0 + j];
      final rsi = calcRSI(closes);
      final n = closes.length;
      if (rsi[n - 1] != null && rsi[n - 1]! > 70) {
        expect(
          evaluateRule(rule('rsiAbove', level: 70), candles(closes)).hit,
          isTrue,
        );
        found = true;
        break;
      }
    }
    expect(found, isTrue);
  });

  test('macdCrossUp fires when MACD line is above the signal line', () {
    final base = [for (var i = 0; i < 40; i++) 100 - i.toDouble()];
    var found = false;
    for (var k = 1; k <= 20; k++) {
      final closes = [...base, for (var j = 1; j <= k; j++) 61 + j * 3.0];
      final m = calcMACD(closes);
      final n = closes.length;
      if (m.ml[n - 1] != null &&
          m.sl[n - 1] != null &&
          m.ml[n - 1]! > m.sl[n - 1]!) {
        expect(evaluateRule(rule('macdCrossUp'), candles(closes)).hit, isTrue);
        found = true;
        break;
      }
    }
    expect(found, isTrue);
  });

  test('emaCrossUp fires when fast EMA is above slow EMA', () {
    final base = [for (var i = 0; i < 40; i++) 100 - i.toDouble()];
    var found = false;
    for (var k = 1; k <= 20; k++) {
      final closes = [...base, for (var j = 1; j <= k; j++) 61 + j * 3.0];
      final f = calcEMA(closes, 9), s = calcEMA(closes, 21);
      final n = closes.length;
      if (f[n - 1] != null && s[n - 1] != null && f[n - 1]! > s[n - 1]!) {
        expect(evaluateRule(rule('emaCrossUp'), candles(closes)).hit, isTrue);
        found = true;
        break;
      }
    }
    expect(found, isTrue);
  });

  test('cross kind fires even when the cross happened long ago', () {
    // رگرسیون: کراسی که چند کندل قبل رخ داده هم باید زنگ بزند — وضعیت
    // فعلی مهم است، نه فقط عبور بین دو کندل آخر.
    final rising = [for (var i = 0; i < 60; i++) 50.0 + i * 2];
    expect(evaluateRule(rule('emaCrossUp'), candles(rising)).hit, isTrue);
    expect(evaluateRule(rule('emaCrossDown'), candles(rising)).hit, isFalse);
  });

  test('smaCrossUp fires on price crossing SMA20', () {
    final closes = [...List<double>.filled(30, 100), 99.0, 110.0];
    expect(evaluateRule(rule('smaCrossUp'), candles(closes)).hit, isTrue);
    expect(evaluateRule(rule('smaCrossDown'), candles(closes)).hit, isFalse);
  });

  test('bbUpperUp fires on breaking the upper band', () {
    final closes = [...List<double>.filled(30, 100), 99.0, 120.0];
    expect(evaluateRule(rule('bbUpperUp'), candles(closes)).hit, isTrue);
  });

  test('evaluateRule returns false with too few candles', () {
    expect(
      evaluateRule(rule('rsiAbove', level: 70), candles([100])).hit,
      isFalse,
    );
    expect(
      evaluateRule(rule('rsiAbove', level: 70), candles([100, 101])).hit,
      isFalse,
    );
  });

  test('AlertRule json roundtrip', () {
    final r = AlertRule(
      id: 'abc',
      symbol: 'ethusdt',
      kind: 'emaCrossUp',
      level: null,
      period: 14,
      fast: 9,
      slow: 21,
      interval: '4h',
      enabled: false,
      armed: false,
    );
    final back = AlertRule.fromJson(r.toJson());
    expect(back.id, 'abc');
    expect(back.symbol, 'ETHUSDT');
    expect(back.kind, 'emaCrossUp');
    expect(back.fast, 9);
    expect(back.slow, 21);
    expect(back.interval, '4h');
    expect(back.enabled, isFalse);
    expect(back.armed, isFalse);
  });
}
