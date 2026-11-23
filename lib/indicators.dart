// محاسبات خالص اندیکاتورها — پورت مستقیم از js/indicators.js نسخه وب (بدون وابستگی به Flutter)
import 'dart:math' as math;

import 'models.dart';

typedef NumList = List<double?>;

NumList _nul(int n) => List<double?>.filled(n, null);

NumList calcSMA(List<double?> a, int p) {
  final out = _nul(a.length);
  for (var i = p - 1; i < a.length; i++) {
    var s = 0.0, ok = true;
    for (var j = i - p + 1; j <= i; j++) {
      final v = a[j];
      if (v == null) {
        ok = false;
        break;
      }
      s += v;
    }
    if (ok) out[i] = s / p;
  }
  return out;
}

NumList calcEMA(List<double?> a, int p) {
  final k = 2 / (p + 1), out = _nul(a.length), sma = calcSMA(a, p);
  double? prev;
  for (var i = p - 1; i < a.length; i++) {
    if (prev == null) {
      prev = sma[i];
      if (prev == null) continue;
    } else {
      prev = a[i]! * k + prev * (1 - k);
    }
    out[i] = prev;
  }
  return out;
}

({NumList mid, NumList up, NumList lo}) calcBB(
  List<double> closes,
  int p,
  double mult,
) {
  final mid = calcSMA(closes, p), up = <double?>[], lo = <double?>[];
  for (var i = 0; i < mid.length; i++) {
    final m = mid[i];
    if (m == null) {
      up.add(null);
      lo.add(null);
      continue;
    }
    var v = 0.0;
    for (var j = i - p + 1; j <= i; j++)
      v += math.pow(closes[j] - m, 2).toDouble();
    final sd = math.sqrt(v / p);
    up.add(m + mult * sd);
    lo.add(m - mult * sd);
  }
  return (mid: mid, up: up, lo: lo);
}

NumList calcVWAP(List<Candle> c, String iv) {
  // ریست روزانه (برای 1D/1W ماهانه)
  var pv = 0.0, vv = 0.0;
  String? key;
  return c.map((x) {
    final d = DateTime.fromMillisecondsSinceEpoch(x.time * 1000, isUtc: true);
    final k =
        '${d.year}-${d.month}${iv == '1d' || iv == '1w' ? '' : '-${d.day}'}';
    if (k != key) {
      key = k;
      pv = 0;
      vv = 0;
    }
    pv += (x.high + x.low + x.close) / 3 * x.volume;
    vv += x.volume;
    return vv != 0 ? pv / vv : null;
  }).toList();
}

({NumList k, NumList d}) calcStoch(List<Candle> c, int kp, int dp, int sm) {
  final raw = List<double?>.generate(c.length, (i) {
    if (i < kp - 1) return null;
    var hh = double.negativeInfinity, ll = double.infinity;
    for (var j = i - kp + 1; j <= i; j++) {
      hh = math.max(hh, c[j].high);
      ll = math.min(ll, c[j].low);
    }
    return hh == ll ? 50.0 : (c[i].close - ll) / (hh - ll) * 100;
  });
  final k = sm > 1 ? calcSMA(raw, sm) : raw;
  return (k: k, d: calcSMA(k, dp));
}

NumList calcATR(List<Candle> c, int p) {
  final out = _nul(c.length);
  if (c.length < p) return out;
  final tr = List<double>.generate(
    c.length,
    (i) => i == 0
        ? c[i].high - c[i].low
        : math.max(
            c[i].high - c[i].low,
            math.max(
              (c[i].high - c[i - 1].close).abs(),
              (c[i].low - c[i - 1].close).abs(),
            ),
          ),
  );
  var a = 0.0;
  for (var i = 0; i < p; i++) a += tr[i];
  a /= p;
  out[p - 1] = a;
  for (var i = p; i < c.length; i++) {
    a = (a * (p - 1) + tr[i]) / p;
    out[i] = a;
  }
  return out;
}

NumList calcRSI(List<double> closes, [int period = 14]) {
  final rsi = _nul(closes.length);
  if (closes.length <= period) return rsi;
  var g = 0.0, l = 0.0;
  for (var i = 1; i <= period; i++) {
    final d = closes[i] - closes[i - 1];
    if (d >= 0) {
      g += d;
    } else {
      l -= d;
    }
  }
  var ag = g / period, al = l / period;
  rsi[period] = al == 0 ? 100 : 100 - 100 / (1 + ag / al);
  for (var i = period + 1; i < closes.length; i++) {
    final d = closes[i] - closes[i - 1];
    ag = (ag * (period - 1) + math.max(d, 0)) / period;
    al = (al * (period - 1) + math.max(-d, 0)) / period;
    rsi[i] = al == 0 ? 100 : 100 - 100 / (1 + ag / al);
  }
  return rsi;
}

// EMA با شروع از اولین مقدار غیرخالی (برای MACD)
NumList ema(List<double?> arr, int p) {
  final k = 2 / (p + 1), out = _nul(arr.length);
  var s = 0;
  while (s < arr.length && arr[s] == null) s++;
  if (s >= arr.length) return out;
  out[s] = arr[s];
  for (var i = s + 1; i < arr.length; i++) {
    out[i] = arr[i] != null ? arr[i]! * k + out[i - 1]! * (1 - k) : null;
  }
  return out;
}

({NumList ml, NumList sl, NumList hl}) calcMACD(
  List<double> closes, [
  int fast = 12,
  int slow = 26,
  int sig = 9,
]) {
  final ef = ema(closes, fast), es = ema(closes, slow);
  final ml = List<double?>.generate(
    closes.length,
    (i) => ef[i] != null && es[i] != null ? ef[i]! - es[i]! : null,
  );
  final sl = ema(ml, sig);
  final hl = List<double?>.generate(
    ml.length,
    (i) => ml[i] != null && sl[i] != null ? ml[i]! - sl[i]! : null,
  );
  return (ml: ml, sl: sl, hl: hl);
}

List<double> calcOBV(List<Candle> c) {
  var o = 0.0;
  return List<double>.generate(c.length, (i) {
    if (i > 0) {
      o += c[i].close > c[i - 1].close
          ? c[i].volume
          : c[i].close < c[i - 1].close
          ? -c[i].volume
          : 0;
    }
    return o;
  });
}

NumList calcROC(List<double?> src, int p) => List<double?>.generate(
  src.length,
  (i) => i >= p && src[i] != null && src[i - p] != null && src[i - p] != 0
      ? (src[i]! - src[i - p]!) / src[i - p]! * 100
      : null,
);

({NumList adx, NumList pdi, NumList mdi}) calcADX(List<Candle> c, int p) {
  final n = c.length;
  final out = (adx: _nul(n), pdi: _nul(n), mdi: _nul(n));
  if (n <= 2 * p) return out;
  final tr = <double>[0], pdm = <double>[0], mdm = <double>[0];
  for (var i = 1; i < n; i++) {
    final up = c[i].high - c[i - 1].high, dn = c[i - 1].low - c[i].low;
    pdm.add(up > dn && up > 0 ? up : 0);
    mdm.add(dn > up && dn > 0 ? dn : 0);
    tr.add(
      math.max(
        c[i].high - c[i].low,
        math.max(
          (c[i].high - c[i - 1].close).abs(),
          (c[i].low - c[i - 1].close).abs(),
        ),
      ),
    );
  }
  var st = 0.0, sp = 0.0, sm = 0.0;
  final dx = _nul(n);
  for (var i = 1; i <= p; i++) {
    st += tr[i];
    sp += pdm[i];
    sm += mdm[i];
  }
  for (var i = p; i < n; i++) {
    if (i > p) {
      st = st - st / p + tr[i];
      sp = sp - sp / p + pdm[i];
      sm = sm - sm / p + mdm[i];
    }
    final pd = st != 0 ? 100 * sp / st : 0.0,
        md = st != 0 ? 100 * sm / st : 0.0;
    out.pdi[i] = pd;
    out.mdi[i] = md;
    dx[i] = pd + md != 0 ? 100 * (pd - md).abs() / (pd + md) : 0;
  }
  var a = 0.0;
  for (var i = p; i < 2 * p; i++) a += dx[i]!;
  a /= p;
  out.adx[2 * p - 1] = a;
  for (var i = 2 * p; i < n; i++) {
    a = (a * (p - 1) + dx[i]!) / p;
    out.adx[i] = a;
  }
  return out;
}

// OBV: همترازی با TradingView با لنگر (مثل نسخه وب)
({List<double> values, ({int t, double v})? anchor, bool matched}) calibrateOBV(
  List<double> raw,
  List<int> times,
  ({int t, double v})? anchor,
) {
  if (anchor == null) return (values: raw, anchor: null, matched: false);
  final j = times.indexOf(anchor.t);
  if (j < 0) return (values: raw, anchor: anchor, matched: false);
  final off = anchor.v - raw[j];
  final values = raw.map((x) => x + off).toList();
  final k = times.length - 2;
  return (
    values: values,
    anchor: k >= 0 ? (t: times[k], v: values[k]) : anchor,
    matched: true,
  );
}

({int t, double v})? makeObvAnchor(
  List<double> raw,
  List<int> times,
  double target,
) {
  final n = raw.length;
  if (n < 3) return null;
  return (t: times[n - 2], v: raw[n - 2] + (target - raw[n - 1]));
}

double? parseCompact(String text) {
  // 40.5K، 1.2M، 1,250,000، −3.1K
  final m = RegExp(r'^(-?\d*\.?\d+)([kmb]?)$', caseSensitive: false).firstMatch(
    text.trim().replaceAll(RegExp(r'[,\s]'), '').replaceAll('\u2212', '-'),
  );
  if (m == null) return null;
  final mult = {
    '': 1.0,
    'k': 1e3,
    'm': 1e6,
    'b': 1e9,
  }[m.group(2)!.toLowerCase()]!;
  return double.parse(m.group(1)!) * mult;
}

// ادغام کندل‌های تازه در داده‌ی فعلی (بروزرسانی خودکار)
({List<Candle> candles, int removed}) mergeCandles(
  List<Candle> old,
  List<Candle> fresh,
  int maxLen,
  int keepLen,
) {
  final map = <int, Candle>{};
  for (final c in old) map[c.time] = c;
  for (final c in fresh) map[c.time] = c;
  var arr = map.values.toList()..sort((a, b) => a.time.compareTo(b.time));
  var removed = 0;
  if (arr.length > maxLen) {
    removed = arr.length - keepLen;
    arr = arr.sublist(removed);
  }
  return (candles: arr, removed: removed);
}

NumList calcCCI(List<Candle> c, int p) {
  final tp = c.map((x) => (x.high + x.low + x.close) / 3).toList();
  final sma = calcSMA(tp, p), out = _nul(c.length);
  for (var i = p - 1; i < c.length; i++) {
    var dev = 0.0;
    for (var j = i - p + 1; j <= i; j++) dev += (tp[j] - sma[i]!).abs();
    dev /= p;
    out[i] = dev != 0 ? (tp[i] - sma[i]!) / (0.015 * dev) : 0;
  }
  return out;
}

NumList calcWPR(List<Candle> c, int p) => List<double?>.generate(c.length, (i) {
  if (i < p - 1) return null;
  var hh = double.negativeInfinity, ll = double.infinity;
  for (var j = i - p + 1; j <= i; j++) {
    hh = math.max(hh, c[j].high);
    ll = math.min(ll, c[j].low);
  }
  return hh == ll ? -50.0 : -100 * (hh - c[i].close) / (hh - ll);
});

NumList calcMOM(List<double?> src, int p) => List<double?>.generate(
  src.length,
  (i) => i >= p && src[i] != null && src[i - p] != null
      ? src[i]! - src[i - p]!
      : null,
);

NumList calcMFI(List<Candle> c, int p) {
  final tp = c.map((x) => (x.high + x.low + x.close) / 3).toList();
  final out = _nul(c.length);
  for (var i = p; i < c.length; i++) {
    var up = 0.0, dn = 0.0;
    for (var j = i - p + 1; j <= i; j++) {
      final f = tp[j] * c[j].volume;
      if (tp[j] > tp[j - 1]) {
        up += f;
      } else if (tp[j] < tp[j - 1]) {
        dn += f;
      }
    }
    out[i] = dn != 0 ? 100 - 100 / (1 + up / dn) : (up != 0 ? 100 : 50);
  }
  return out;
}

NumList calcSMMA(List<double> a, int n) {
  // میانگین هموار (Wilder/RMA) با شروع از SMA
  final out = _nul(a.length);
  if (a.length < n) return out;
  var s = 0.0;
  for (var i = 0; i < n; i++) s += a[i];
  var prev = s / n;
  out[n - 1] = prev;
  for (var i = n; i < a.length; i++) {
    prev = (prev * (n - 1) + a[i]) / n;
    out[i] = prev;
  }
  return out;
}

const alligatorShift = (jaw: 8, teeth: 5, lips: 3);

({NumList jaw, NumList teeth, NumList lips}) calcAlligator(
  List<Candle> c,
  int jaw,
  int teeth,
  int lips,
) {
  final hl2 = c.map((x) => (x.high + x.low) / 2).toList();
  return (
    jaw: calcSMMA(hl2, jaw),
    teeth: calcSMMA(hl2, teeth),
    lips: calcSMMA(hl2, lips),
  );
}

List<Candle> toHeikinAshi(List<Candle> c) {
  final out = <Candle>[];
  var po = 0.0, pc = 0.0;
  for (var i = 0; i < c.length; i++) {
    final x = c[i];
    final cl = (x.open + x.high + x.low + x.close) / 4;
    final op = i == 0 ? (x.open + x.close) / 2 : (po + pc) / 2;
    out.add(
      Candle(
        x.time,
        op,
        math.max(x.high, math.max(op, cl)),
        math.min(x.low, math.min(op, cl)),
        cl,
        x.volume,
      ),
    );
    po = op;
    pc = cl;
  }
  return out;
}

// دقت نمایش قیمت بر اساس بزرگی آن (فقط نمایش)
int calcPricePrecision(double price) {
  final p = price.abs();
  if (!p.isFinite || p >= 1) return 2;
  if (p >= 0.01) return 4;
  if (p >= 0.0001) return 6;
  return 8;
}
