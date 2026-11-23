// پنل اندیکاتورها و تنظیمات (Bottom Sheet): روشن/خاموش، پارامتر، رنگ، ضخامت، ترتیب پنل‌ها
import 'package:flutter/material.dart';

import '../settings.dart';
import '../theme.dart';

const _defColors = {
  'sma': 0xFFF59E0B,
  'ema': 0xFF3B82F6,
  'bb': 0xFFA855F7,
  'vwap': 0xFF14B8A6,
  'alligator': 0xFF3B82F6,
  'volume': 0xFF9CA3AF,
  'rsi': 0xFFA855F7,
  'rsisma': 0xFFA855F7,
  'macd': 0xFF2962FF,
  'stoch': 0xFF2962FF,
  'atr': 0xFFF59E0B,
  'obv': 0xFF2962FF,
  'roc': 0xFF14B8A6,
  'adx': 0xFFFFFFFF,
  'cci': 0xFF14B8A6,
  'wpr': 0xFFEC4899,
  'mom': 0xFF84CC16,
  'mfi': 0xFFA855F7,
};

const _paneTitles = {
  'rsi': 'RSI',
  'rsisma': 'RSI+SMA',
  'macd': 'MACD',
  'stoch': 'Stochastic',
  'atr': 'ATR',
  'obv': 'OBV+SMA',
  'roc': 'ROC',
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

  Widget _row(
    String title,
    String key,
    IndCfg cfg, {
    bool isPane = false,
    int paneIndex = -1,
  }) {
    final s = widget.settings;
    final dotColor = Color(cfg.color ?? _defColors[key] ?? 0xFF9CA3AF);
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
              GestureDetector(
                onTap: () async {
                  final picked = await showColorPalette(context, dotColor);
                  if (picked != null) {
                    cfg.color = picked.toARGB32();
                    widget.onChanged();
                    setState(() {});
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cBorder),
                  ),
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
