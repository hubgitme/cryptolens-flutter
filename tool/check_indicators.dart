// ignore_for_file: avoid_print, avoid_relative_lib_imports
// بررسی مقادیر مرجع اندیکاتورها با Dart خالص (بدون Flutter): dart tool/check_indicators.dart
import 'dart:math' as math;

import '../lib/indicators.dart';
import '../lib/models.dart';

int _fail = 0;
void check(bool ok, String name) {
  if (!ok) {
    _fail++;
    print('FAIL: $name');
  }
}

void near(double? a, double b, String name, [double e = 1e-9]) =>
    check(a != null && (a - b).abs() < e, '$name ($a ≉ $b)');

List<Candle> mk(double Function(int) f, [int n = 120]) => List.generate(n, (i) {
  final c = f(i);
  return Candle(i, c, c + 2, c - 2, c, 10);
});

void main() {
  final s = calcSMA([1, 2, 3, 4, 5], 3);
  check(
    s[0] == null && s[1] == null && s[2] == 2 && s[3] == 3 && s[4] == 4,
    'SMA',
  );
  final e = calcEMA([1, 2, 3, 4, 5], 3);
  near(e[2], 2, 'EMA2');
  near(e[3], 3, 'EMA3');
  near(e[4], 4, 'EMA4');

  final obv = calcOBV([
    Candle(0, 0, 0, 0, 1, 5),
    Candle(1, 0, 0, 0, 2, 3),
    Candle(2, 0, 0, 0, 2, 9),
    Candle(3, 0, 0, 0, 1, 4),
  ]);
  check(obv.toString() == [0.0, 3.0, 3.0, -1.0].toString(), 'OBV $obv');
  final r = calcROC([100, 110, 121], 1);
  check(r[0] == null, 'ROC0');
  near(r[1], 10, 'ROC1');
  near(r[2], 10, 'ROC2');

  final up = calcADX(mk((i) => 100 + i * 1.5), 14);
  final dn = calcADX(mk((i) => 300 - i * 1.5), 14);
  check(up.pdi.indexWhere((v) => v != null) == 14, 'ADX pdi start');
  check(up.adx.indexWhere((v) => v != null) == 27, 'ADX start');
  check(
    up.pdi[119]! > up.mdi[119]! && dn.mdi[119]! > dn.pdi[119]!,
    'ADX direction',
  );
  for (final rr in [up, dn]) {
    for (final a in [rr.adx, rr.pdi, rr.mdi]) {
      check(
        a.where((v) => v != null).every((v) => v! >= 0 && v <= 100),
        'ADX range',
      );
    }
  }

  final c = mk((i) => 100 + 10 * math.sin(i / 7));
  final cl = c.map((x) => x.close).toList();
  check(
    calcRSI(cl, 14).where((v) => v != null).every((v) => v! >= 0 && v <= 100),
    'RSI range',
  );
  final st = calcStoch(c, 14, 3, 3);
  check(
    st.k.where((v) => v != null).every((v) => v! >= 0 && v <= 100),
    'Stoch range',
  );
  check(calcATR(c, 14).where((v) => v != null).every((v) => v! > 0), 'ATR > 0');
  check(calcMACD(cl, 12, 26, 9).ml.length == cl.length, 'MACD length');
  final b = calcBB(cl, 20, 2);
  check(b.up[30]! > b.mid[30]! && b.mid[30]! > b.lo[30]!, 'BB order');

  // OBV anchor
  final closes = <double>[10, 11, 10, 10, 12, 13],
      vols = <double>[5, 3, 4, 2, 6, 7];
  final candles = List.generate(
    6,
    (i) => Candle(100 + i, 0, 0, 0, closes[i], vols[i]),
  );
  final times = candles.map((x) => x.time).toList();
  final raw = calcOBV(candles);
  final anchor = makeObvAnchor(raw, times, 40500);
  final r1 = calibrateOBV(raw, times, anchor);
  check(r1.matched, 'OBV anchor matched');
  near(r1.values[5], 40500, 'OBV anchor last');
  near(r1.values[5] - r1.values[4], raw[5] - raw[4], 'OBV anchor shape');
  final c2 = [...candles.sublist(1), Candle(106, 0, 0, 0, 12, 9)];
  final t2 = c2.map((x) => x.time).toList();
  final r2 = calibrateOBV(calcOBV(c2), t2, r1.anchor);
  check(r2.matched, 'OBV anchor matched 2');
  near(r2.values[4], 40500, 'OBV anchor keeps');
  near(r2.values[5], 40500 - 9, 'OBV anchor new candle');
  check(
    !calibrateOBV(raw, times, (t: 1, v: 5.0)).matched,
    'OBV anchor outside',
  );

  check(parseCompact('40.5K') == 40500, 'parseCompact K');
  check(parseCompact('1.2m') == 1200000, 'parseCompact m');
  check(parseCompact('1,250,000') == 1250000, 'parseCompact commas');
  check(parseCompact('\u22123.1K') == -3100, 'parseCompact minus');
  check(parseCompact('abc') == null, 'parseCompact null');

  Candle mkc(int t, double cl2) => Candle(t, 0, 0, 0, cl2, 0);
  final old = [1, 2, 3, 4, 5].map((t) => mkc(t, t.toDouble())).toList();
  final a = mergeCandles(old, [mkc(5, 50), mkc(6, 6)], 100, 100);
  check(
    a.candles.length == 6 &&
        a.candles[4].close == 50 &&
        a.candles[5].time == 6 &&
        a.removed == 0,
    'merge a',
  );
  final bb = mergeCandles(old, [mkc(6, 6)], 5, 4);
  check(
    bb.removed == 2 && bb.candles.length == 4 && bb.candles[0].time == 3,
    'merge b',
  );
  final dd = mergeCandles(old, [mkc(7, 7), mkc(6, 6)], 100, 100);
  check(
    dd.candles.map((x) => x.time).join(',') == '1,2,3,4,5,6,7',
    'merge sorted',
  );

  Candle tp(double v) => Candle(0, v, v, v, v, 0);
  final cci = calcCCI([tp(1), tp(2), tp(3)], 3);
  check(cci[0] == null && cci[1] == null, 'CCI nulls');
  near(cci[2], 100, 'CCI 100');
  near(calcCCI([tp(3), tp(2), tp(1)], 3)[2], -100, 'CCI -100');
  check(calcCCI([tp(5), tp(5), tp(5)], 3)[2] == 0, 'CCI flat');

  Candle cc(double h, double l, double cl3) => Candle(0, cl3, h, l, cl3, 0);
  final w = calcWPR([cc(10, 0, 5), cc(10, 0, 10), cc(10, 0, 0)], 3);
  check(w[0] == null, 'WPR null');
  near(w[2], -100, 'WPR -100');
  near(calcWPR([cc(10, 0, 5), cc(10, 2, 5), cc(10, 0, 10)], 3)[2], 0, 'WPR 0');
  near(
    calcWPR([cc(10, 0, 5), cc(10, 0, 5), cc(10, 0, 5)], 3)[2],
    -50,
    'WPR -50',
  );

  final m = calcMOM([10, 12, 15, 11, 20], 2);
  check(m[0] == null && m[1] == null, 'MOM nulls');
  near(m[2], 5, 'MOM2');
  near(m[3], -1, 'MOM3');
  near(m[4], 5, 'MOM4');

  List<Candle> mkt(List<double> tps) =>
      tps.map((v) => Candle(0, v, v, v, v, 10)).toList();
  final upM = calcMFI(mkt([1, 2, 3, 4, 5, 6]), 4);
  check(upM[3] == null, 'MFI null');
  near(upM[4], 100, 'MFI up4');
  near(upM[5], 100, 'MFI up5');
  near(calcMFI(mkt([6, 5, 4, 3, 2, 1]), 4)[5], 0, 'MFI dn');
  near(
    calcMFI(mkt([10, 11, 10, 11, 10]), 4)[4],
    100 - 100 / (1 + 22 / 20),
    'MFI ref',
  );

  final sm = calcSMMA([1, 2, 3, 4], 2);
  check(sm[0] == null, 'SMMA null');
  near(sm[1], 1.5, 'SMMA1');
  near(sm[2], 2.25, 'SMMA2');
  near(sm[3], 3.125, 'SMMA3');
  final ac = List.generate(
    60,
    (i) => Candle(i, 100.0 + i, 102.0 + i, 98.0 + i, 100.0 + i, 0),
  );
  final al = calcAlligator(ac, 13, 8, 5);
  check(al.jaw.indexWhere((v) => v != null) == 12, 'Alligator jaw start');
  check(al.teeth.indexWhere((v) => v != null) == 7, 'Alligator teeth start');
  check(al.lips.indexWhere((v) => v != null) == 4, 'Alligator lips start');
  near(al.lips[4], 102, 'Alligator lips value');
  check(
    al.lips[59]! > al.teeth[59]! && al.teeth[59]! > al.jaw[59]!,
    'Alligator order',
  );

  final h = toHeikinAshi([
    Candle(1, 10, 20, 5, 15, 7),
    Candle(2, 15, 25, 10, 20, 8),
    Candle(3, 20, 22, 8, 9, 9),
  ]);
  near(h[0].close, 12.5, 'HA0c');
  near(h[0].open, 12.5, 'HA0o');
  near(h[0].high, 20, 'HA0h');
  near(h[0].low, 5, 'HA0l');
  near(h[1].close, 17.5, 'HA1c');
  near(h[1].open, 12.5, 'HA1o');
  near(h[1].high, 25, 'HA1h');
  near(h[1].low, 10, 'HA1l');
  near(h[2].close, 14.75, 'HA2c');
  near(h[2].open, 15, 'HA2o');
  near(h[2].high, 22, 'HA2h');
  near(h[2].low, 8, 'HA2l');

  check(calcPricePrecision(67000) == 2, 'PP 67000');
  check(calcPricePrecision(1) == 2, 'PP 1');
  check(calcPricePrecision(0.5) == 4, 'PP 0.5');
  check(calcPricePrecision(0.01) == 4, 'PP 0.01');
  check(calcPricePrecision(0.005) == 6, 'PP 0.005');
  check(calcPricePrecision(0.0001) == 6, 'PP 0.0001');
  check(calcPricePrecision(0.00001) == 8, 'PP PEPE');
  check(calcPricePrecision(0) == 8, 'PP 0');
  check(calcPricePrecision(double.nan) == 2, 'PP NaN');

  if (_fail == 0) {
    print('ALL CHECKS PASSED');
  } else {
    print('$_fail CHECK(S) FAILED');
    throw StateError('checks failed');
  }
}
