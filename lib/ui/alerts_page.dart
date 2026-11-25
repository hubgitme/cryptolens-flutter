// صفحه جدا برای هشدارها و آلارم‌ها — مثل تریدینگ‌ویو:
// اول نوع را انتخاب می‌کنی (قیمت / میانگین متحرک / اندیکاتور)،
// بعد شرط و مقدار (یا میانگین دوم)، بعد فعالش می‌کنی.
import 'package:flutter/material.dart';

import '../alert_service.dart';
import '../alerts.dart';
import '../alerts_store.dart';
import '../indicators.dart';
import '../settings.dart';
import '../theme.dart';

Future<void> showAlertsPage(BuildContext context, String currentSymbol) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AlertsPage(currentSymbol: currentSymbol)),
  );
}

const _sources = [
  ('price', 'قیمت'),
  ('ma', 'میانگین متحرک'),
  ('indicator', 'اندیکاتور'),
];

const _indicators = [
  ('rsi', 'RSI'),
  ('macd', 'مکدی (MACD)'),
  ('stoch', 'استوکستیک'),
  ('roc', 'ROC'),
  ('cci', 'CCI'),
  ('wpr', 'WPR'),
  ('mfi', 'MFI'),
  ('mom', 'مومنتوم'),
  ('adx', 'ADX'),
  ('atr', 'ATR'),
  ('obv', 'OBV'),
  ('bb', 'بولینگر'),
  ('vwap', 'VWAP'),
  ('alligator', 'تمساح (Alligator)'),
];

/// شرط‌های هر اندیکاتور: (kind، برچسب فارسی)
const _indicatorConditions = <String, List<(String, String)>>{
  'rsi': [
    ('rsiAbove', 'بالاتر از سطح'),
    ('rsiBelow', 'پایین‌تر از سطح'),
    ('rsiCrossSmaUp', 'میانگین خودش را به بالا قطع کرد'),
    ('rsiCrossSmaDown', 'میانگین خودش را به پایین قطع کرد'),
  ],
  'macd': [
    ('macdCrossUp', 'خط سیگنال را به بالا قطع کرد'),
    ('macdCrossDown', 'خط سیگنال را به پایین قطع کرد'),
    ('macdHistUp', 'هیستوگرام از صفر به بالا گذشت'),
    ('macdHistDown', 'هیستوگرام از صفر به پایین گذشت'),
  ],
  'stoch': [
    ('stochCrossUp', '%K خط %D را به بالا قطع کرد'),
    ('stochCrossDown', '%K خط %D را به پایین قطع کرد'),
    ('stochAbove', '%K بالاتر از سطح'),
    ('stochBelow', '%K پایین‌تر از سطح'),
  ],
  'roc': [
    ('rocCrossZeroUp', 'از صفر به بالا گذشت'),
    ('rocCrossZeroDown', 'از صفر به پایین گذشت'),
    ('rocCrossMaUp', 'میانگین خودش را به بالا قطع کرد'),
    ('rocCrossMaDown', 'میانگین خودش را به پایین قطع کرد'),
  ],
  'cci': [
    ('cciAbove', 'بالاتر از سطح'),
    ('cciBelow', 'پایین‌تر از سطح'),
    ('cciCrossZeroUp', 'از صفر به بالا گذشت'),
    ('cciCrossZeroDown', 'از صفر به پایین گذشت'),
  ],
  'wpr': [('wprAbove', 'بالاتر از سطح'), ('wprBelow', 'پایین‌تر از سطح')],
  'mfi': [('mfiAbove', 'بالاتر از سطح'), ('mfiBelow', 'پایین‌تر از سطح')],
  'mom': [
    ('momCrossZeroUp', 'از صفر به بالا گذشت'),
    ('momCrossZeroDown', 'از صفر به پایین گذشت'),
  ],
  'adx': [('adxAbove', 'بالاتر از سطح'), ('adxBelow', 'پایین‌تر از سطح')],
  'atr': [('atrAbove', 'بالاتر از مقدار'), ('atrBelow', 'پایین‌تر از مقدار')],
  'obv': [
    ('obvCrossSmaUp', 'میانگین خودش را به بالا قطع کرد'),
    ('obvCrossSmaDown', 'میانگین خودش را به پایین قطع کرد'),
  ],
  'bb': [
    ('bbUpperUp', 'باند بالا را به بالا شکست'),
    ('bbLowerDown', 'باند پایین را به پایین شکست'),
    ('bbMidUp', 'خط وسط را به بالا قطع کرد'),
    ('bbMidDown', 'خط وسط را به پایین قطع کرد'),
  ],
  'vwap': [
    ('vwapCrossUp', 'VWAP را به بالا قطع کرد'),
    ('vwapCrossDown', 'VWAP را به پایین قطع کرد'),
  ],
  'alligator': [
    ('alligatorUp', 'لب‌ها دندان را به بالا قطع کرد'),
    ('alligatorDown', 'لب‌ها دندان را به پایین قطع کرد'),
  ],
};

const _priceConditions = [
  ('above', 'بالاتر از'),
  ('below', 'پایین‌تر از'),
  ('crossUp', 'قطع کرد به بالا'),
  ('crossDown', 'قطع کرد به پایین'),
];

class AlertsPage extends StatefulWidget {
  final String currentSymbol;
  const AlertsPage({super.key, required this.currentSymbol});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<AlertRule> _rules = [];
  bool _loading = true;

  // فرم
  final _symbolCtrl = TextEditingController();
  String _source = 'price';
  // قیمت
  String _priceCond = 'above';
  final _priceLevelCtrl = TextEditingController();
  // میانگین متحرک
  String _maType = 'sma';
  String _maMode = 'price'; // price | maVsMa
  String _maCond = 'up';
  final _maPeriodCtrl = TextEditingController(text: '20');
  final _maFastCtrl = TextEditingController(text: '9');
  final _maSlowCtrl = TextEditingController(text: '21');
  // اندیکاتور
  String _indicator = 'rsi';
  String _indKind = 'rsiAbove';
  final _valueCtrl = TextEditingController(text: '70');
  final _periodCtrl = TextEditingController(text: '14');
  String _interval = '1h';

  @override
  void initState() {
    super.initState();
    _symbolCtrl.text = widget.currentSymbol;
    _loadRules();
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _priceLevelCtrl.dispose();
    _maPeriodCtrl.dispose();
    _maFastCtrl.dispose();
    _maSlowCtrl.dispose();
    _valueCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    final rules = await AlertsStore.load();
    if (mounted) {
      setState(() {
        _rules = rules;
        _loading = false;
      });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  AlertRule? _buildRule() {
    final sym = _symbolCtrl.text.trim().toUpperCase();
    if (!symbolRe.hasMatch(sym)) {
      _snack('نماد معتبر نیست');
      return null;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    int parsePeriod(TextEditingController c, int def) {
      final v = int.tryParse(c.text.trim());
      return v == null ? def : v.clamp(2, 500);
    }

    if (_source == 'price') {
      final level = parseCompact(_priceLevelCtrl.text);
      if (level == null || level <= 0) {
        _snack('قیمت را وارد کن (مثل 100000)');
        return null;
      }
      final up = _priceCond == 'above' || _priceCond == 'crossUp';
      return AlertRule(
        id: id,
        symbol: sym,
        kind: up ? 'priceAbove' : 'priceBelow',
        level: level,
        period: 14,
        fast: 9,
        slow: 21,
        interval: _interval,
      );
    }

    if (_source == 'ma') {
      final up = _maCond == 'up';
      if (_maMode == 'maVsMa') {
        final fast = parsePeriod(_maFastCtrl, 9);
        final slow = parsePeriod(_maSlowCtrl, 21);
        if (fast >= slow) {
          _snack('دوره میانگین سریع باید کوچک‌تر از کند باشد');
          return null;
        }
        return AlertRule(
          id: id,
          symbol: sym,
          kind: _maType == 'sma'
              ? (up ? 'smaFastCrossUp' : 'smaFastCrossDown')
              : (up ? 'emaCrossUp' : 'emaCrossDown'),
          period: 14,
          fast: fast,
          slow: slow,
          interval: _interval,
        );
      }
      final period = parsePeriod(_maPeriodCtrl, 20);
      return AlertRule(
        id: id,
        symbol: sym,
        kind: _maType == 'sma'
            ? (up ? 'smaCrossUp' : 'smaCrossDown')
            : (up ? 'emaPriceCrossUp' : 'emaPriceCrossDown'),
        period: period,
        fast: 9,
        slow: 21,
        interval: _interval,
      );
    }

    // اندیکاتور
    final spec = alertKindSpec(_indKind);
    double? level;
    var period = spec.defPeriod ?? 14;
    if (spec.param == 'level') {
      level = parseCompact(_valueCtrl.text) ?? spec.defLevel;
      if (level == null) {
        _snack('مقدار را وارد کن');
        return null;
      }
    } else if (spec.param == 'period') {
      period = parsePeriod(_periodCtrl, spec.defPeriod ?? 14);
    }
    return AlertRule(
      id: id,
      symbol: sym,
      kind: _indKind,
      level: level,
      period: period,
      fast: 9,
      slow: 21,
      interval: _interval,
    );
  }

  Future<void> _createRule() async {
    final rule = _buildRule();
    if (rule == null) return;
    _rules.add(rule);
    await AlertsStore.save(_rules);
    await AlertService.syncBackgroundTask();
    // اولین هشدار: اجازه اعلان را بگیر (اگر رد شد، هشدارها فقط بنر می‌شوند)
    await AlertService.requestPermission();
    if (!mounted) return;
    setState(() {});
    _snack('هشدار فعال شد — هر ۱۵ دقیقه در پس‌زمینه چک می‌شود');
  }

  Future<void> _toggle(AlertRule r, bool v) async {
    r.enabled = v;
    r.armed = true;
    await AlertsStore.save(_rules);
    await AlertService.syncBackgroundTask();
    if (mounted) setState(() {});
  }

  Future<void> _delete(AlertRule r) async {
    _rules.removeWhere((x) => x.id == r.id);
    await AlertsStore.save(_rules);
    await AlertService.syncBackgroundTask();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final indSpec = alertKindSpec(_indKind);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cSurface,
        title: const Text('هشدارها و آلارم‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: cText),
            tooltip: 'اعلان آزمایشی',
            onPressed: () async {
              await AlertService.showTest();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ——— فرم ساخت هشدار ———
                  Card(
                    color: cSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'هشدار تازه',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _symbolCtrl,
                            textDirection: TextDirection.ltr,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'نماد',
                              hintText: 'BTCUSDT',
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _source,
                            decoration: const InputDecoration(
                              labelText: 'نوع هشدار',
                            ),
                            items: [
                              for (final (v, l) in _sources)
                                DropdownMenuItem(value: v, child: Text(l)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _source = v);
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_source == 'price') ...[
                            DropdownButtonFormField<String>(
                              value: _priceCond,
                              decoration: const InputDecoration(
                                labelText: 'شرط',
                              ),
                              items: [
                                for (final (v, l) in _priceConditions)
                                  DropdownMenuItem(value: v, child: Text(l)),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _priceCond = v);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _priceLevelCtrl,
                              textDirection: TextDirection.ltr,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'قیمت',
                                hintText: 'مثل 100000',
                              ),
                            ),
                          ],
                          if (_source == 'ma') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _maType,
                                    decoration: const InputDecoration(
                                      labelText: 'نوع میانگین',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'sma',
                                        child: Text('SMA'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ema',
                                        child: Text('EMA'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _maType = v);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _maMode,
                                    decoration: const InputDecoration(
                                      labelText: 'مقایسه با',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'price',
                                        child: Text('قیمت'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'maVsMa',
                                        child: Text('میانگین دیگر'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _maMode = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_maMode == 'price')
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _maPeriodCtrl,
                                      textDirection: TextDirection.ltr,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'دوره میانگین',
                                        hintText: '20',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _maCond,
                                      decoration: const InputDecoration(
                                        labelText: 'شرط',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'up',
                                          child: Text('قطع کرد به بالا'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'down',
                                          child: Text('قطع کرد به پایین'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _maCond = v);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _maFastCtrl,
                                      textDirection: TextDirection.ltr,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'دوره سریع',
                                        hintText: '9',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _maSlowCtrl,
                                      textDirection: TextDirection.ltr,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'دوره کند',
                                        hintText: '21',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _maCond,
                                      decoration: const InputDecoration(
                                        labelText: 'شرط',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'up',
                                          child: Text('به بالا'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'down',
                                          child: Text('به پایین'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _maCond = v);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                          if (_source == 'indicator') ...[
                            DropdownButtonFormField<String>(
                              value: _indicator,
                              decoration: const InputDecoration(
                                labelText: 'اندیکاتور',
                              ),
                              items: [
                                for (final (v, l) in _indicators)
                                  DropdownMenuItem(value: v, child: Text(l)),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                final conds = _indicatorConditions[v]!;
                                setState(() {
                                  _indicator = v;
                                  _indKind = conds.first.$1;
                                  final s = alertKindSpec(_indKind);
                                  if (s.defLevel != null) {
                                    _valueCtrl.text = _trimNum(s.defLevel!);
                                  }
                                  if (s.defPeriod != null) {
                                    _periodCtrl.text = '${s.defPeriod}';
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _indKind,
                              decoration: const InputDecoration(
                                labelText: 'شرط',
                              ),
                              items: [
                                for (final (k, l)
                                    in _indicatorConditions[_indicator]!)
                                  DropdownMenuItem(value: k, child: Text(l)),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _indKind = v;
                                  final s = alertKindSpec(v);
                                  if (s.defLevel != null) {
                                    _valueCtrl.text = _trimNum(s.defLevel!);
                                  }
                                  if (s.defPeriod != null) {
                                    _periodCtrl.text = '${s.defPeriod}';
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            if (indSpec.param == 'level')
                              TextField(
                                controller: _valueCtrl,
                                textDirection: TextDirection.ltr,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'مقدار',
                                  hintText: 'مثل 70',
                                ),
                              )
                            else if (indSpec.param == 'period')
                              TextField(
                                controller: _periodCtrl,
                                textDirection: TextDirection.ltr,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'دوره',
                                  hintText: '14',
                                ),
                              )
                            else if (indSpec.param == 'macd')
                              const Text(
                                'پارامتر ثابت: مکدی ۱۲ / ۲۶ / ۹',
                                style: TextStyle(color: cMuted),
                              )
                            else
                              const Text(
                                'بدون پارامتر اضافه',
                                style: TextStyle(color: cMuted),
                              ),
                          ],
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _interval,
                            decoration: const InputDecoration(
                              labelText: 'تایم‌فریم',
                            ),
                            items: [
                              for (final iv in intervals)
                                DropdownMenuItem(
                                  value: iv,
                                  child: Text(iv.toUpperCase()),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _interval = v);
                            },
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _createRule,
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('ایجاد و فعال‌سازی هشدار'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'هشدارهای من',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_rules.isEmpty)
                    const Card(
                      color: cSurface,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'هنوز هشداری نساخته‌ای — از فرم بالا بساز.',
                          style: TextStyle(color: cMuted),
                        ),
                      ),
                    )
                  else
                    for (final r in _rules)
                      Card(
                        color: cSurface,
                        child: ListTile(
                          title: Text(r.describe()),
                          subtitle: Text(
                            r.enabled ? 'فعال' : 'خاموش',
                            style: TextStyle(
                              color: r.enabled ? cGreen : cMuted,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: r.enabled,
                                onChanged: (v) => _toggle(r, v),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: cRed,
                                ),
                                onPressed: () => _delete(r),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                  const Text(
                    'چک پس‌زمینه هر ۱۵ دقیقه انجام می‌شود (حداقل اندروید)؛ وقتی چارت باز است و تایم‌فریم با هشدار یکی باشد، با هر بروزرسانی هم چک می‌شود. برای اینکه آلارم در پس‌زمینه برسد، اجازه اعلان را بده و بهینه‌سازی باتری را برای اپ خاموش کن.',
                    style: TextStyle(color: cMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }
}

String _trimNum(double v) {
  if (v == v.truncateToDouble()) return '${v.truncate()}';
  return '$v';
}
