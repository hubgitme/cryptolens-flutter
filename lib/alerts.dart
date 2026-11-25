// هشدارها و آلارم‌ها — مدل + ارزیابی خالص (بدون وابستگی به Flutter)
// همه اندیکاتورهای اپ پشتیبانی می‌شوند: قیمت، SMA/EMA، بولینگر، VWAP،
// تمساح، RSI، مکدی، استوکستیک، ROC، CCI، WPR، MFI، مومنتوم، ADX، ATR، OBV.
import 'indicators.dart';
import 'models.dart';

/// مشخصات یک نوع هشدار.
class AlertKindSpec {
  final String id;
  final String label; // فارسی
  final String cat; // price | trend | osc
  final String param; // level | period | fastSlow | macd | none
  final double? defLevel;
  final int? defPeriod;
  final int? defFast;
  final int? defSlow;
  final bool priceDomain; // مقدار نمایشی با دقت قیمت فرمت شود (نه ۱ رقم اعشار)
  const AlertKindSpec(
    this.id,
    this.label,
    this.cat,
    this.param, {
    this.defLevel,
    this.defPeriod,
    this.defFast,
    this.defSlow,
    this.priceDomain = false,
  });
}

const alertCategories = {
  'price': 'قیمت',
  'trend': 'روند و میانگین‌ها',
  'osc': 'نوسانگرها',
};

const alertKinds = <AlertKindSpec>[
  // قیمت
  AlertKindSpec(
    'priceAbove',
    'قیمت بالاتر از سطح',
    'price',
    'level',
    priceDomain: true,
  ),
  AlertKindSpec(
    'priceBelow',
    'قیمت پایین‌تر از سطح',
    'price',
    'level',
    priceDomain: true,
  ),
  // روند و میانگین‌ها
  AlertKindSpec(
    'smaCrossUp',
    'قیمت SMA را به بالا قطع کرد',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'smaCrossDown',
    'قیمت SMA را به پایین قطع کرد',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'emaPriceCrossUp',
    'قیمت EMA را به بالا قطع کرد',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'emaPriceCrossDown',
    'قیمت EMA را به پایین قطع کرد',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'emaCrossUp',
    'EMA سریع، کند را به بالا قطع کرد',
    'trend',
    'fastSlow',
    defFast: 9,
    defSlow: 21,
    priceDomain: true,
  ),
  AlertKindSpec(
    'emaCrossDown',
    'EMA سریع، کند را به پایین قطع کرد',
    'trend',
    'fastSlow',
    defFast: 9,
    defSlow: 21,
    priceDomain: true,
  ),
  AlertKindSpec(
    'smaFastCrossUp',
    'SMA سریع، کند را به بالا قطع کرد',
    'trend',
    'fastSlow',
    defFast: 9,
    defSlow: 21,
    priceDomain: true,
  ),
  AlertKindSpec(
    'smaFastCrossDown',
    'SMA سریع، کند را به پایین قطع کرد',
    'trend',
    'fastSlow',
    defFast: 9,
    defSlow: 21,
    priceDomain: true,
  ),
  AlertKindSpec(
    'bbUpperUp',
    'قیمت باند بالای بولینگر را شکست',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'bbLowerDown',
    'قیمت باند پایین بولینگر را شکست',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'bbMidUp',
    'قیمت خط وسط بولینگر را به بالا قطع کرد',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'bbMidDown',
    'قیمت خط وسط بولینگر را به پایین قطع کرد',
    'trend',
    'period',
    defPeriod: 20,
    priceDomain: true,
  ),
  AlertKindSpec(
    'vwapCrossUp',
    'قیمت VWAP را به بالا قطع کرد',
    'trend',
    'none',
    priceDomain: true,
  ),
  AlertKindSpec(
    'vwapCrossDown',
    'قیمت VWAP را به پایین قطع کرد',
    'trend',
    'none',
    priceDomain: true,
  ),
  AlertKindSpec(
    'alligatorUp',
    'لب‌های تمساح دندان را به بالا قطع کرد',
    'trend',
    'none',
    priceDomain: true,
  ),
  AlertKindSpec(
    'alligatorDown',
    'لب‌های تمساح دندان را به پایین قطع کرد',
    'trend',
    'none',
    priceDomain: true,
  ),
  // نوسانگرها
  AlertKindSpec('rsiAbove', 'RSI بالاتر از سطح', 'osc', 'level', defLevel: 70),
  AlertKindSpec(
    'rsiBelow',
    'RSI پایین‌تر از سطح',
    'osc',
    'level',
    defLevel: 30,
  ),
  AlertKindSpec(
    'rsiCrossSmaUp',
    'RSI میانگین خودش را به بالا قطع کرد',
    'osc',
    'period',
    defPeriod: 14,
  ),
  AlertKindSpec(
    'rsiCrossSmaDown',
    'RSI میانگین خودش را به پایین قطع کرد',
    'osc',
    'period',
    defPeriod: 14,
  ),
  AlertKindSpec(
    'macdCrossUp',
    'مکدی خط سیگنال را به بالا قطع کرد',
    'osc',
    'macd',
  ),
  AlertKindSpec(
    'macdCrossDown',
    'مکدی خط سیگنال را به پایین قطع کرد',
    'osc',
    'macd',
  ),
  AlertKindSpec(
    'macdHistUp',
    'هیستوگرام مکدی از صفر به بالا گذشت',
    'osc',
    'macd',
  ),
  AlertKindSpec(
    'macdHistDown',
    'هیستوگرام مکدی از صفر به پایین گذشت',
    'osc',
    'macd',
  ),
  AlertKindSpec('stochCrossUp', '%K خط %D را به بالا قطع کرد', 'osc', 'none'),
  AlertKindSpec(
    'stochCrossDown',
    '%K خط %D را به پایین قطع کرد',
    'osc',
    'none',
  ),
  AlertKindSpec('stochAbove', '%K بالاتر از سطح', 'osc', 'level', defLevel: 80),
  AlertKindSpec(
    'stochBelow',
    '%K پایین‌تر از سطح',
    'osc',
    'level',
    defLevel: 20,
  ),
  AlertKindSpec(
    'rocCrossZeroUp',
    'ROC از صفر به بالا گذشت',
    'osc',
    'period',
    defPeriod: 9,
  ),
  AlertKindSpec(
    'rocCrossZeroDown',
    'ROC از صفر به پایین گذشت',
    'osc',
    'period',
    defPeriod: 9,
  ),
  AlertKindSpec(
    'rocCrossMaUp',
    'ROC میانگین خودش را به بالا قطع کرد',
    'osc',
    'period',
    defPeriod: 9,
  ),
  AlertKindSpec(
    'rocCrossMaDown',
    'ROC میانگین خودش را به پایین قطع کرد',
    'osc',
    'period',
    defPeriod: 9,
  ),
  AlertKindSpec('cciAbove', 'CCI بالاتر از سطح', 'osc', 'level', defLevel: 100),
  AlertKindSpec(
    'cciBelow',
    'CCI پایین‌تر از سطح',
    'osc',
    'level',
    defLevel: -100,
  ),
  AlertKindSpec(
    'cciCrossZeroUp',
    'CCI از صفر به بالا گذشت',
    'osc',
    'period',
    defPeriod: 20,
  ),
  AlertKindSpec(
    'cciCrossZeroDown',
    'CCI از صفر به پایین گذشت',
    'osc',
    'period',
    defPeriod: 20,
  ),
  AlertKindSpec('wprAbove', 'WPR بالاتر از سطح', 'osc', 'level', defLevel: -20),
  AlertKindSpec(
    'wprBelow',
    'WPR پایین‌تر از سطح',
    'osc',
    'level',
    defLevel: -80,
  ),
  AlertKindSpec('mfiAbove', 'MFI بالاتر از سطح', 'osc', 'level', defLevel: 80),
  AlertKindSpec(
    'mfiBelow',
    'MFI پایین‌تر از سطح',
    'osc',
    'level',
    defLevel: 20,
  ),
  AlertKindSpec(
    'momCrossZeroUp',
    'مومنتوم از صفر به بالا گذشت',
    'osc',
    'period',
    defPeriod: 10,
  ),
  AlertKindSpec(
    'momCrossZeroDown',
    'مومنتوم از صفر به پایین گذشت',
    'osc',
    'period',
    defPeriod: 10,
  ),
  AlertKindSpec('adxAbove', 'ADX بالاتر از سطح', 'osc', 'level', defLevel: 25),
  AlertKindSpec(
    'adxBelow',
    'ADX پایین‌تر از سطح',
    'osc',
    'level',
    defLevel: 20,
  ),
  AlertKindSpec(
    'atrAbove',
    'ATR بالاتر از مقدار',
    'osc',
    'level',
    priceDomain: true,
  ),
  AlertKindSpec(
    'atrBelow',
    'ATR پایین‌تر از مقدار',
    'osc',
    'level',
    priceDomain: true,
  ),
  AlertKindSpec(
    'obvCrossSmaUp',
    'OBV میانگین خودش را به بالا قطع کرد',
    'osc',
    'period',
    defPeriod: 20,
  ),
  AlertKindSpec(
    'obvCrossSmaDown',
    'OBV میانگین خودش را به پایین قطع کرد',
    'osc',
    'period',
    defPeriod: 20,
  ),
];

AlertKindSpec alertKindSpec(String id) =>
    alertKinds.firstWhere((k) => k.id == id, orElse: () => alertKinds.first);

class AlertRule {
  String id;
  String symbol;
  String kind;
  double? level;
  int period;
  int fast;
  int slow;
  String interval;
  bool enabled;
  bool armed; // true = آماده شلیک؛ بعد از شلیک false تا شرط برگردد

  AlertRule({
    required this.id,
    required this.symbol,
    required this.kind,
    this.level,
    required this.period,
    required this.fast,
    required this.slow,
    required this.interval,
    this.enabled = true,
    this.armed = true,
  });

  AlertKindSpec get spec => alertKindSpec(kind);
  String get kindLabel => spec.label;
  String get categoryLabel => alertCategories[spec.cat] ?? spec.cat;
  int get notifId => id.hashCode & 0x7fffffff;

  String get paramText {
    switch (spec.param) {
      case 'level':
        return level != null ? 'سطح ${_fmtNum(level!)}' : '';
      case 'period':
        return 'دوره $period';
      case 'fastSlow':
        return '$fast / $slow';
      case 'macd':
        return '۱۲ / ۲۶ / ۹';
      case 'none':
        return '';
    }
    return '';
  }

  String describe() =>
      '$symbol · $kindLabel${paramText.isEmpty ? '' : ' · $paramText'} · $interval';

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'kind': kind,
    if (level != null) 'level': level,
    'period': period,
    'fast': fast,
    'slow': slow,
    'interval': interval,
    'enabled': enabled,
    'armed': armed,
  };

  factory AlertRule.fromJson(Map<String, dynamic> j) {
    final spec = alertKindSpec(j['kind'] is String ? j['kind'] as String : '');
    final lv = j['level'];
    return AlertRule(
      id: j['id'] is String ? j['id'] as String : '',
      symbol: j['symbol'] is String
          ? (j['symbol'] as String).toUpperCase()
          : 'BTCUSDT',
      kind: spec.id,
      level: lv is num ? lv.toDouble() : spec.defLevel,
      period: j['period'] is num
          ? (j['period'] as num).toInt().clamp(2, 500)
          : (spec.defPeriod ?? 14),
      fast: j['fast'] is num
          ? (j['fast'] as num).toInt().clamp(2, 500)
          : (spec.defFast ?? 9),
      slow: j['slow'] is num
          ? (j['slow'] as num).toInt().clamp(2, 500)
          : (spec.defSlow ?? 21),
      interval: j['interval'] is String ? j['interval'] as String : '1h',
      enabled: j['enabled'] is bool ? j['enabled'] as bool : true,
      armed: j['armed'] is bool ? j['armed'] as bool : true,
    );
  }
}

String _fmtNum(double v) {
  if (!v.isFinite) return '—';
  final p = calcPricePrecision(v);
  var s = v.toStringAsFixed(p);
  // حذف صفرهای انتهایی برای خوانایی
  if (s.contains('.'))
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s;
}

/// سری a در آخرین کندل سری b را به بالا قطع کرده؟ (مقدار قبلی <= و مقدار جدید >)
bool _crossUp(NumList a, NumList b) {
  if (a.length < 2 || b.length < 2) return false;
  final a0 = a[a.length - 2], a1 = a.last;
  final b0 = b[b.length - 2], b1 = b.last;
  if (a0 == null || a1 == null || b0 == null || b1 == null) return false;
  return a0 <= b0 && a1 > b1;
}

bool _crossDown(NumList a, NumList b) {
  if (a.length < 2 || b.length < 2) return false;
  final a0 = a[a.length - 2], a1 = a.last;
  final b0 = b[b.length - 2], b1 = b.last;
  if (a0 == null || a1 == null || b0 == null || b1 == null) return false;
  return a0 >= b0 && a1 < b1;
}

bool _levelUp(NumList a, double level) {
  if (a.length < 2) return false;
  final a0 = a[a.length - 2], a1 = a.last;
  if (a0 == null || a1 == null) return false;
  return a0 <= level && a1 > level;
}

bool _levelDown(NumList a, double level) {
  if (a.length < 2) return false;
  final a0 = a[a.length - 2], a1 = a.last;
  if (a0 == null || a1 == null) return false;
  return a0 >= level && a1 < level;
}

String _fmtVal(double? v, bool priceDomain) {
  if (v == null || !v.isFinite) return '—';
  return priceDomain ? _fmtNum(v) : v.toStringAsFixed(1);
}

({bool hit, String detail}) evaluateRule(AlertRule r, List<Candle> c) {
  if (c.length < 2) return (hit: false, detail: '');
  final closes = c.map((x) => x.close).toList();
  final pd = r.spec.priceDomain;
  String det(NumList s) => _fmtVal(s.isEmpty ? null : s.last, pd);
  switch (r.kind) {
    case 'priceAbove':
      return (
        hit: r.level != null && _levelUp(closes, r.level!),
        detail: 'قیمت ${_fmtVal(closes.last, true)}',
      );
    case 'priceBelow':
      return (
        hit: r.level != null && _levelDown(closes, r.level!),
        detail: 'قیمت ${_fmtVal(closes.last, true)}',
      );
    case 'smaCrossUp':
      final s = calcSMA(closes, r.period);
      return (hit: _crossUp(closes, s), detail: 'SMA ${det(s)}');
    case 'smaCrossDown':
      final s = calcSMA(closes, r.period);
      return (hit: _crossDown(closes, s), detail: 'SMA ${det(s)}');
    case 'emaPriceCrossUp':
      final s = calcEMA(closes, r.period);
      return (hit: _crossUp(closes, s), detail: 'EMA ${det(s)}');
    case 'emaPriceCrossDown':
      final s = calcEMA(closes, r.period);
      return (hit: _crossDown(closes, s), detail: 'EMA ${det(s)}');
    case 'emaCrossUp':
      final f = calcEMA(closes, r.fast), s = calcEMA(closes, r.slow);
      return (hit: _crossUp(f, s), detail: 'EMA ${det(f)}');
    case 'emaCrossDown':
      final f = calcEMA(closes, r.fast), s = calcEMA(closes, r.slow);
      return (hit: _crossDown(f, s), detail: 'EMA ${det(f)}');
    case 'smaFastCrossUp':
      final f = calcSMA(closes, r.fast), s = calcSMA(closes, r.slow);
      return (hit: _crossUp(f, s), detail: 'SMA ${det(f)}');
    case 'smaFastCrossDown':
      final f = calcSMA(closes, r.fast), s = calcSMA(closes, r.slow);
      return (hit: _crossDown(f, s), detail: 'SMA ${det(f)}');
    case 'bbUpperUp':
      final b = calcBB(closes, r.period, 2);
      return (hit: _crossUp(closes, b.up), detail: 'باند بالا ${det(b.up)}');
    case 'bbLowerDown':
      final b = calcBB(closes, r.period, 2);
      return (hit: _crossDown(closes, b.lo), detail: 'باند پایین ${det(b.lo)}');
    case 'bbMidUp':
      final b = calcBB(closes, r.period, 2);
      return (hit: _crossUp(closes, b.mid), detail: 'خط وسط ${det(b.mid)}');
    case 'bbMidDown':
      final b = calcBB(closes, r.period, 2);
      return (hit: _crossDown(closes, b.mid), detail: 'خط وسط ${det(b.mid)}');
    case 'vwapCrossUp':
      final v = calcVWAP(c, r.interval);
      return (hit: _crossUp(closes, v), detail: 'VWAP ${det(v)}');
    case 'vwapCrossDown':
      final v = calcVWAP(c, r.interval);
      return (hit: _crossDown(closes, v), detail: 'VWAP ${det(v)}');
    case 'alligatorUp':
      final g = calcAlligator(c, 13, 8, 5);
      return (hit: _crossUp(g.lips, g.teeth), detail: 'لب‌ها ${det(g.lips)}');
    case 'alligatorDown':
      final g = calcAlligator(c, 13, 8, 5);
      return (hit: _crossDown(g.lips, g.teeth), detail: 'لب‌ها ${det(g.lips)}');
    case 'rsiAbove':
      final s = calcRSI(closes);
      return (
        hit: r.level != null && _levelUp(s, r.level!),
        detail: 'RSI ${det(s)}',
      );
    case 'rsiBelow':
      final s = calcRSI(closes);
      return (
        hit: r.level != null && _levelDown(s, r.level!),
        detail: 'RSI ${det(s)}',
      );
    case 'rsiCrossSmaUp':
      final s = calcRSI(closes, r.period);
      final m = calcSMA(s, 9);
      return (hit: _crossUp(s, m), detail: 'RSI ${det(s)}');
    case 'rsiCrossSmaDown':
      final s = calcRSI(closes, r.period);
      final m = calcSMA(s, 9);
      return (hit: _crossDown(s, m), detail: 'RSI ${det(s)}');
    case 'macdCrossUp':
      final m = calcMACD(closes);
      return (hit: _crossUp(m.ml, m.sl), detail: 'MACD ${det(m.ml)}');
    case 'macdCrossDown':
      final m = calcMACD(closes);
      return (hit: _crossDown(m.ml, m.sl), detail: 'MACD ${det(m.ml)}');
    case 'macdHistUp':
      final m = calcMACD(closes);
      return (hit: _levelUp(m.hl, 0), detail: 'هیستوگرام ${det(m.hl)}');
    case 'macdHistDown':
      final m = calcMACD(closes);
      return (hit: _levelDown(m.hl, 0), detail: 'هیستوگرام ${det(m.hl)}');
    case 'stochCrossUp':
      final s = calcStoch(c, 14, 3, 3);
      return (hit: _crossUp(s.k, s.d), detail: '%K ${det(s.k)}');
    case 'stochCrossDown':
      final s = calcStoch(c, 14, 3, 3);
      return (hit: _crossDown(s.k, s.d), detail: '%K ${det(s.k)}');
    case 'stochAbove':
      final s = calcStoch(c, 14, 3, 3);
      return (
        hit: r.level != null && _levelUp(s.k, r.level!),
        detail: '%K ${det(s.k)}',
      );
    case 'stochBelow':
      final s = calcStoch(c, 14, 3, 3);
      return (
        hit: r.level != null && _levelDown(s.k, r.level!),
        detail: '%K ${det(s.k)}',
      );
    case 'rocCrossZeroUp':
      final s = calcROC(closes, r.period);
      return (hit: _levelUp(s, 0), detail: 'ROC ${det(s)}');
    case 'rocCrossZeroDown':
      final s = calcROC(closes, r.period);
      return (hit: _levelDown(s, 0), detail: 'ROC ${det(s)}');
    case 'rocCrossMaUp':
      final s = calcROC(closes, r.period);
      final m = calcSMA(s, 14);
      return (hit: _crossUp(s, m), detail: 'ROC ${det(s)}');
    case 'rocCrossMaDown':
      final s = calcROC(closes, r.period);
      final m = calcSMA(s, 14);
      return (hit: _crossDown(s, m), detail: 'ROC ${det(s)}');
    case 'cciAbove':
      final s = calcCCI(c, 20);
      return (
        hit: r.level != null && _levelUp(s, r.level!),
        detail: 'CCI ${det(s)}',
      );
    case 'cciBelow':
      final s = calcCCI(c, 20);
      return (
        hit: r.level != null && _levelDown(s, r.level!),
        detail: 'CCI ${det(s)}',
      );
    case 'cciCrossZeroUp':
      final s = calcCCI(c, r.period);
      return (hit: _levelUp(s, 0), detail: 'CCI ${det(s)}');
    case 'cciCrossZeroDown':
      final s = calcCCI(c, r.period);
      return (hit: _levelDown(s, 0), detail: 'CCI ${det(s)}');
    case 'wprAbove':
      final s = calcWPR(c, 14);
      return (
        hit: r.level != null && _levelUp(s, r.level!),
        detail: 'WPR ${det(s)}',
      );
    case 'wprBelow':
      final s = calcWPR(c, 14);
      return (
        hit: r.level != null && _levelDown(s, r.level!),
        detail: 'WPR ${det(s)}',
      );
    case 'mfiAbove':
      final s = calcMFI(c, 14);
      return (
        hit: r.level != null && _levelUp(s, r.level!),
        detail: 'MFI ${det(s)}',
      );
    case 'mfiBelow':
      final s = calcMFI(c, 14);
      return (
        hit: r.level != null && _levelDown(s, r.level!),
        detail: 'MFI ${det(s)}',
      );
    case 'momCrossZeroUp':
      final s = calcMOM(closes, r.period);
      return (hit: _levelUp(s, 0), detail: 'مومنتوم ${det(s)}');
    case 'momCrossZeroDown':
      final s = calcMOM(closes, r.period);
      return (hit: _levelDown(s, 0), detail: 'مومنتوم ${det(s)}');
    case 'adxAbove':
      final s = calcADX(c, 14).adx;
      return (
        hit: r.level != null && _levelUp(s, r.level!),
        detail: 'ADX ${det(s)}',
      );
    case 'adxBelow':
      final s = calcADX(c, 14).adx;
      return (
        hit: r.level != null && _levelDown(s, r.level!),
        detail: 'ADX ${det(s)}',
      );
    case 'atrAbove':
      final s = calcATR(c, 14);
      return (
        hit: r.level != null && _levelUp(s, r.level!),
        detail: 'ATR ${det(s)}',
      );
    case 'atrBelow':
      final s = calcATR(c, 14);
      return (
        hit: r.level != null && _levelDown(s, r.level!),
        detail: 'ATR ${det(s)}',
      );
    case 'obvCrossSmaUp':
      final o = calcOBV(c);
      final m = calcSMA(o, r.period);
      return (hit: _crossUp(o, m), detail: 'OBV ${det(o)}');
    case 'obvCrossSmaDown':
      final o = calcOBV(c);
      final m = calcSMA(o, r.period);
      return (hit: _crossDown(o, m), detail: 'OBV ${det(o)}');
    default:
      return (hit: false, detail: '');
  }
}

class FiredAlert {
  final AlertRule rule;
  final String message; // متن کامل اعلان
  FiredAlert(this.rule, this.message);
}

/// همه قوانین را روی داده‌های داده‌شده ارزیابی می‌کند؛ کلید نقشه
/// «SYMBOL|interval» است. قوانین شلیک‌شده برمی‌گردند و پرچم armed
/// قوانین به‌روز می‌شود (بعد از فراخوانی باید ذخیره شوند).
/// منطق لبه: فقط وقتی شلیک می‌شود که شرط تازه برقرار شده باشد و قانون
/// مسلح باشد؛ وقتی شرط برطرف شد، قانون دوباره مسلح می‌شود.
List<FiredAlert> evaluateAll(
  List<AlertRule> rules,
  Map<String, List<Candle>> byKey,
) {
  final fired = <FiredAlert>[];
  for (final r in rules) {
    if (!r.enabled) continue;
    final candles = byKey['${r.symbol}|${r.interval}'];
    if (candles == null || candles.length < 2) continue;
    final ev = evaluateRule(r, candles);
    if (ev.hit) {
      if (r.armed) {
        r.armed = false;
        fired.add(FiredAlert(r, '${r.describe()} — ${ev.detail}'));
      }
    } else {
      r.armed = true;
    }
  }
  return fired;
}
