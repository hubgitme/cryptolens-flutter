// تست مقادیر مرجع اندیکاتورها (پورت از tests/indicators.test.js نسخه وب)
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:cryptolens_app/indicators.dart';
import 'package:cryptolens_app/models.dart';

void main() {
  List<Candle> mk(double Function(int) f, [int n = 120]) =>
      List.generate(n, (i) {
        final c = f(i);
        return Candle(i, c, c + 2, c - 2, c, 10);
      });

  test('SMA / EMA', () {
    expect(calcSMA([1, 2, 3, 4, 5], 3), [null, null, 2.0, 3.0, 4.0]);
    final e = calcEMA([1, 2, 3, 4, 5], 3);
    expect(e[2], closeTo(2, 1e-9));
    expect(e[3], closeTo(3, 1e-9));
    expect(e[4], closeTo(4, 1e-9));
  });

  test('OBV و ROC', () {
    final obv = calcOBV([
      Candle(0, 0, 0, 0, 1, 5),
      Candle(1, 0, 0, 0, 2, 3),
      Candle(2, 0, 0, 0, 2, 9),
      Candle(3, 0, 0, 0, 1, 4),
    ]);
    expect(obv, [0.0, 3.0, 3.0, -1.0]);
    final r = calcROC([100, 110, 121], 1);
    expect(r[0], isNull);
    expect(r[1], closeTo(10, 1e-9));
    expect(r[2], closeTo(10, 1e-9));
  });

  test('ADX: ساختار و جهت', () {
    final up = calcADX(mk((i) => 100 + i * 1.5), 14);
    final dn = calcADX(mk((i) => 300 - i * 1.5), 14);
    expect(up.pdi.indexWhere((v) => v != null), 14);
    expect(up.adx.indexWhere((v) => v != null), 27);
    expect(up.pdi[119]! > up.mdi[119]!, isTrue);
    expect(dn.mdi[119]! > dn.pdi[119]!, isTrue);
  });

  test('RSI / Stoch / ATR / MACD / BB در بازه‌ی درست', () {
    final c = mk((i) => 100 + 10 * math.sin(i / 7));
    final cl = c.map((x) => x.close).toList();
    expect(
      calcRSI(cl, 14).where((v) => v != null).every((v) => v! >= 0 && v <= 100),
      isTrue,
    );
    final st = calcStoch(c, 14, 3, 3);
    expect(
      st.k.where((v) => v != null).every((v) => v! >= 0 && v <= 100),
      isTrue,
    );
    expect(calcATR(c, 14).where((v) => v != null).every((v) => v! > 0), isTrue);
    expect(calcMACD(cl, 12, 26, 9).ml.length, cl.length);
    final b = calcBB(cl, 20, 2);
    expect(b.up[30]! > b.mid[30]! && b.mid[30]! > b.lo[30]!, isTrue);
  });

  test('CCI و Williams %R و Momentum و MFI', () {
    Candle tp(double v) => Candle(0, v, v, v, v, 0);
    expect(calcCCI([tp(1), tp(2), tp(3)], 3)[2], closeTo(100, 1e-9));
    expect(calcCCI([tp(5), tp(5), tp(5)], 3)[2], 0);
    Candle cc(double h, double l, double cl) => Candle(0, cl, h, l, cl, 0);
    expect(
      calcWPR([cc(10, 0, 5), cc(10, 0, 10), cc(10, 0, 0)], 3)[2],
      closeTo(-100, 1e-9),
    );
    final m = calcMOM([10, 12, 15, 11, 20], 2);
    expect(m[2], closeTo(5, 1e-9));
    expect(m[3], closeTo(-1, 1e-9));
    List<Candle> mkt(List<double> tps) =>
        tps.map((v) => Candle(0, v, v, v, v, 10)).toList();
    expect(
      calcMFI(mkt([10, 11, 10, 11, 10]), 4)[4],
      closeTo(100 - 100 / (1 + 22 / 20), 1e-9),
    );
  });

  test('SMMA و Alligator و Heikin Ashi', () {
    final sm = calcSMMA([1, 2, 3, 4], 2);
    expect(sm[1], closeTo(1.5, 1e-9));
    expect(sm[3], closeTo(3.125, 1e-9));
    final h = toHeikinAshi([
      Candle(1, 10, 20, 5, 15, 7),
      Candle(2, 15, 25, 10, 20, 8),
      Candle(3, 20, 22, 8, 9, 9),
    ]);
    expect(h[0].close, closeTo(12.5, 1e-9));
    expect(h[1].open, closeTo(12.5, 1e-9));
    expect(h[2].close, closeTo(14.75, 1e-9));
    expect(h[2].open, closeTo(15, 1e-9));
  });

  test('calcPricePrecision', () {
    expect(calcPricePrecision(67000), 2);
    expect(calcPricePrecision(0.5), 4);
    expect(calcPricePrecision(0.005), 6);
    expect(calcPricePrecision(0.00001), 8);
    expect(calcPricePrecision(double.nan), 2);
  });

  test('mergeCandles و parseCompact', () {
    Candle mkc(int t, double c) => Candle(t, 0, 0, 0, c, 0);
    final old = [1, 2, 3, 4, 5].map((t) => mkc(t, t.toDouble())).toList();
    final a = mergeCandles(old, [mkc(5, 50), mkc(6, 6)], 100, 100);
    expect(a.candles.length, 6);
    expect(a.candles[4].close, 50);
    expect(parseCompact('40.5K'), 40500);
    expect(parseCompact('abc'), isNull);
  });
}
