// پنل اندیکاتورها و تنظیمات (Bottom Sheet): روشن/خاموش، پارامتر، رنگ، ضخامت، ترتیب پنل‌ها
import 'package:flutter/material.dart';

import '../settings.dart';
import '../theme.dart';

// رنگ پیش‌فرض خط اول هر اندیکاتور — دقیقاً مثل نسخه وب (js/chart.js)
const _defColors = {
  'sma': 0xFFF59E0B,
  'ema': 0xFF3B82F6,
  'bb': 0xFFA855F7,
  'vwap': 0xFF14B8A6,
  'alligator': 0xFF2962FF,
  'volume': 0xFF9CA3AF,
  'rsi': 0xFFFFC107,
  'rsisma': 0xFFFFC107,
  'macd': 0xFF2962FF,
  'stoch': 0xFF2962FF,
  'atr': 0xFFFFC107,
  'obv': 0xFF2962FF,
  'roc': 0xFFA855F7,
  'rocma': 0xFFA855F7,
  'adx': 0xFFF59E0B,
  'cci': 0xFF2962FF,
  'wpr': 0xFF7E57C2,
  'mom': 0xFFFFA726,
  'mfi': 0xFF00BCD4,
};

// رنگ پیش‌فرض همه خط‌های هر اندیکاتور (مثل وب)
const _defLineColors = {
  'sma': [0xFFF59E0B],
  'ema': [0xFF3B82F6],
  'bb': [0xFFA855F7, 0xFFA855F7, 0xFFA855F7],
  'vwap': [0xFF14B8A6],
  'alligator': [0xFF2962FF, 0xFFEF5350, 0xFF26A69A],
  'volume': [0xFF9CA3AF],
  'rsi': [0xFFFFC107],
  'rsisma': [0xFFFFC107, 0xFF3B82F6],
  'macd': [0xFF2962FF, 0xFFFF6D00],
  'stoch': [0xFF2962FF, 0xFFFF6D00],
  'atr': [0xFFFFC107],
  'obv': [0xFF2962FF, 0xFFFF6D00],
  'roc': [0xFFA855F7],
  'rocma': [0xFFA855F7, 0xFFFF6D00],
  'adx': [0xFFF59E0B, 0xFF26A69A, 0xFFEF5350],
  'cci': [0xFF2962FF],
  'wpr': [0xFF7E57C2],
  'mom': [0xFFFFA726],
  'mfi': [0xFF00BCD4],
};

// نام هر خط برای دکمه رنگ جداگانه
const _lineLabels = {
  'sma': ['SMA'],
  'ema': ['EMA'],
  'bb': ['Mid', 'Up', 'Low'],
  'vwap': ['VWAP'],
  'alligator': ['Jaw', 'Teeth', 'Lips'],
  'volume': ['Vol'],
  'rsi': ['RSI'],
  'rsisma': ['RSI', 'SMA'],
  'macd': ['MACD', 'Signal'],
  'stoch': ['%K', '%D'],
  'atr': ['ATR'],
  'obv': ['OBV', 'SMA'],
  'roc': ['ROC'],
  'rocma': ['ROC', 'MA'],
  'adx': ['ADX', '+DI', '-DI'],
  'cci': ['CCI'],
  'wpr': ['%R'],
  'mom': ['MOM'],
  'mfi': ['MFI'],
};

const _paneTitles = {
  'rsi': 'RSI',
  'rsisma': 'RSI+SMA',
  'macd': 'MACD',
  'stoch': 'Stochastic',
  'atr': 'ATR',
  'obv': 'OBV+SMA',
  'roc': 'ROC',
  'rocma': 'ROC+MA',
  'adx': 'ADX',
  'cci': 'CCI',
  'wpr': 'Williams %R',
  'mom': 'Momentum',
  'mfi': 'MFI',
};

const _widthOptions = [0.8, 1.2, 1.8, 2.5];

class IndicatorSheet extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onChanged;
  const IndicatorSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<IndicatorSheet> createState() => _IndicatorSheetState();
}

class _IndicatorSheetState extends State<IndicatorSheet> {
  Widget _numField(
    IndCfg cfg,
    String key,
    String label, {
    double min = 1,
    double max = 500,
  }) {
    return SizedBox(
      width: 92,
      child: TextFormField(
        initialValue: cfg.p(key, min).toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (v) {
          final n = double.tryParse(v);
          if (n != null) {
            cfg.params[key] = n.clamp(min, max);
            widget.onChanged();
          }
        },
      ),
    );
  }

  List<Widget> _fieldsFor(String key, IndCfg cfg) {
    switch (key) {
      case 'sma':
      case 'ema':
        return [_numField(cfg, 'period', 'دوره')];
      case 'bb':
        return [
          _numField(cfg, 'period', 'دوره'),
          _numField(cfg, 'mult', 'ضریب', min: 0.1, max: 10),
        ];
      case 'alligator':
        return [
          _numField(cfg, 'jaw', 'فک'),
          _numField(cfg, 'teeth', 'دندان'),
          _numField(cfg, 'lips', 'لب'),
        ];
      case 'rsi':
        return [
          _numField(cfg, 'period', 'دوره'),
          _numField(cfg, 'ob', 'اشباع خرید', max: 100),
          _numField(cfg, 'os', 'اشباع فروش', max: 100),
        ];
      case 'rsisma':
        return [
          _numField(cfg, 'period', 'دوره'),
          _numField(cfg, 'sma', 'SMA'),
          _numField(cfg, 'hi', 'بالا', max: 100),
          _numField(cfg, 'lo', 'پایین', max: 100),
        ];
      case 'macd':
        return [
          _numField(cfg, 'fast', 'سریع'),
          _numField(cfg, 'slow', 'کند'),
          _numField(cfg, 'sig', 'سیگنال'),
        ];
      case 'stoch':
        return [
          _numField(cfg, 'k', '%K'),
          _numField(cfg, 'd', '%D'),
          _numField(cfg, 'smooth', 'نرم'),
        ];
      case 'obv':
        return [_numField(cfg, 'sma', 'SMA')];
      case 'rocma':
        return [_numField(cfg, 'period', 'دوره'), _numField(cfg, 'sma', 'MA')];
      default:
        return cfg.params.containsKey('period')
            ? [_numField(cfg, 'period', 'دوره')]
            : [];
    }
  }

  double _nearestWidth(double w) {
    var best = _widthOptions.first;
    for (final o in _widthOptions) {
      if ((o - w).abs() < (best - w).abs()) best = o;
    }
    return best;
  }

  int _lineColorAt(IndCfg cfg, String key, int i) {
    if (cfg.lineColors != null && i < cfg.lineColors!.length) {
      return cfg.lineColors![i];
    }
    final defs = _defLineColors[key];
    if (defs != null && i < defs.length) return defs[i];
    return cfg.color ?? _defColors[key] ?? 0xFF9CA3AF;
  }

  void _setLineColor(IndCfg cfg, String key, int i, int argb) {
    final n = (_lineLabels[key] ?? const ['']).length;
    final cur = List<int>.generate(n, (j) => _lineColorAt(cfg, key, j));
    cur[i] = argb;
    cfg.lineColors = cur;
    if (i == 0) cfg.color = argb;
  }

  Widget _row(
    String title,
    String key,
    IndCfg cfg, {
    bool isPane = false,
    int paneIndex = -1,
  }) {
    final s = widget.settings;
    final labels = _lineLabels[key] ?? const [''];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: cfg.on,
                onChanged: (v) {
                  cfg.on = v;
                  widget.onChanged();
                  setState(() {});
                },
              ),
              SizedBox(
                width: 86,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // رنگ جداگانه هر خط
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final cur = Color(_lineColorAt(cfg, key, i));
                          final picked = await showColorPalette(context, cur);
                          if (picked != null) {
                            _setLineColor(cfg, key, i, picked.toARGB32());
                            widget.onChanged();
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Color(_lineColorAt(cfg, key, i)),
                            shape: BoxShape.circle,
                            border: Border.all(color: cBorder),
                          ),
                        ),
                      ),
                      SizedBox(width: 3),
                      Text(
                        labels[i],
                        style: TextStyle(color: cMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              SizedBox(width: 8),
              DropdownButton<double>(
                value: _nearestWidth(cfg.width),
                dropdownColor: cSurface,
                isDense: true,
                items: [
                  for (final w in _widthOptions)
                    DropdownMenuItem(value: w, child: Text('ضخامت $w')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    cfg.width = v;
                    widget.onChanged();
                    setState(() {});
                  }
                },
              ),
              Spacer(),
              if (isPane) ...[
                IconButton(
                  icon: Icon(Icons.arrow_upward, size: 18, color: cText),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'بالا',
                  onPressed: paneIndex <= 0
                      ? null
                      : () => setState(() {
                          final o = s.paneOrder;
                          final t = o[paneIndex - 1];
                          o[paneIndex - 1] = o[paneIndex];
                          o[paneIndex] = t;
                          widget.onChanged();
                        }),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward, size: 18, color: cText),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'پایین',
                  onPressed:
                      paneIndex < 0 || paneIndex >= s.paneOrder.length - 1
                      ? null
                      : () => setState(() {
                          final o = s.paneOrder;
                          final t = o[paneIndex + 1];
                          o[paneIndex + 1] = o[paneIndex];
                          o[paneIndex] = t;
                          widget.onChanged();
                        }),
                ),
              ],
            ],
          ),
          if (_fieldsFor(key, cfg).isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 52, top: 2),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _fieldsFor(key, cfg),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final ind = s.indicators, ov = s.overlays;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        color: cSurface,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'اندیکاتورها و تنظیمات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text('روی قیمت', style: TextStyle(color: cMuted, fontSize: 12)),
            _row('SMA', 'sma', ov['sma']!),
            _row('EMA', 'ema', ov['ema']!),
            _row('Bollinger', 'bb', ov['bb']!),
            _row('VWAP', 'vwap', ov['vwap']!),
            _row('Alligator', 'alligator', ov['alligator']!),
            _row('Volume', 'volume', ov['volume']!),
            Divider(color: cBorder),
            Text(
              'پنل‌ها (با ↑↓ ترتیبشان را عوض کنید)',
              style: TextStyle(color: cMuted, fontSize: 12),
            ),
            for (var i = 0; i < s.paneOrder.length; i++)
              _row(
                _paneTitles[s.paneOrder[i]] ?? s.paneOrder[i],
                s.paneOrder[i],
                ind[s.paneOrder[i]]!,
                isPane: true,
                paneIndex: i,
              ),
            Divider(color: cBorder),
            Text('عمومی', style: TextStyle(color: cMuted, fontSize: 12)),
            Row(
              children: [
                Text('بروزرسانی خودکار', style: TextStyle(color: Colors.white)),
                Spacer(),
                DropdownButton<int>(
                  value: s.refresh,
                  dropdownColor: cSurface,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('خاموش')),
                    DropdownMenuItem(value: 15, child: Text('۱۵ ثانیه')),
                    DropdownMenuItem(value: 30, child: Text('۳۰ ثانیه')),
                    DropdownMenuItem(value: 60, child: Text('۱ دقیقه')),
                    DropdownMenuItem(value: 300, child: Text('۵ دقیقه')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      s.refresh = v;
                      widget.onChanged();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text('نوع کندل', style: TextStyle(color: Colors.white)),
                Spacer(),
                DropdownButton<String>(
                  value: s.chartType,
                  dropdownColor: cSurface,
                  items: const [
                    DropdownMenuItem(value: 'candles', child: Text('معمولی')),
                    DropdownMenuItem(value: 'ha', child: Text('هیکن آشی')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      s.chartType = v;
                      widget.onChanged();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            TextFormField(
              initialValue: s.apiBase,
              decoration: InputDecoration(
                labelText: 'آدرس API جایگزین (خالی = مستقیم Binance)',
                hintText: 'https://your-app.vercel.app',
                isDense: true,
              ),
              onChanged: (v) {
                s.apiBase = v.trim();
                widget.onChanged();
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
