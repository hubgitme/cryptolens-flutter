// پنل اندیکاتورها و تنظیمات (Bottom Sheet)
import 'package:flutter/material.dart';

import '../settings.dart';
import '../theme.dart';

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

  Widget _row(String title, IndCfg cfg, List<Widget> fields) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
            width: 56,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Wrap(spacing: 8, runSpacing: 4, children: fields)),
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
            _row('SMA', ov['sma']!, [_numField(ov['sma']!, 'period', 'دوره')]),
            _row('EMA', ov['ema']!, [_numField(ov['ema']!, 'period', 'دوره')]),
            _row('Bollinger', ov['bb']!, [
              _numField(ov['bb']!, 'period', 'دوره'),
              _numField(ov['bb']!, 'mult', 'ضریب', min: 0.1, max: 10),
            ]),
            _row('VWAP', ov['vwap']!, []),
            _row('Alligator', ov['alligator']!, [
              _numField(ov['alligator']!, 'jaw', 'فک'),
              _numField(ov['alligator']!, 'teeth', 'دندان'),
              _numField(ov['alligator']!, 'lips', 'لب'),
            ]),
            _row('Volume', ov['volume']!, []),
            Divider(color: cBorder),
            Text('پنل‌ها', style: TextStyle(color: cMuted, fontSize: 12)),
            _row('RSI', ind['rsi']!, [
              _numField(ind['rsi']!, 'period', 'دوره'),
              _numField(ind['rsi']!, 'ob', 'اشباع خرید', max: 100),
              _numField(ind['rsi']!, 'os', 'اشباع فروش', max: 100),
            ]),
            _row('RSI+SMA', ind['rsisma']!, [
              _numField(ind['rsisma']!, 'period', 'دوره'),
              _numField(ind['rsisma']!, 'sma', 'SMA'),
              _numField(ind['rsisma']!, 'hi', 'بالا', max: 100),
              _numField(ind['rsisma']!, 'lo', 'پایین', max: 100),
            ]),
            _row('MACD', ind['macd']!, [
              _numField(ind['macd']!, 'fast', 'سریع'),
              _numField(ind['macd']!, 'slow', 'کند'),
              _numField(ind['macd']!, 'sig', 'سیگنال'),
            ]),
            _row('Stochastic', ind['stoch']!, [
              _numField(ind['stoch']!, 'k', '%K'),
              _numField(ind['stoch']!, 'd', '%D'),
              _numField(ind['stoch']!, 'smooth', 'نرم'),
            ]),
            _row('ATR', ind['atr']!, [
              _numField(ind['atr']!, 'period', 'دوره'),
            ]),
            _row('OBV+SMA', ind['obv']!, [
              _numField(ind['obv']!, 'sma', 'SMA'),
            ]),
            _row('ROC', ind['roc']!, [
              _numField(ind['roc']!, 'period', 'دوره'),
            ]),
            _row('ADX', ind['adx']!, [
              _numField(ind['adx']!, 'period', 'دوره'),
            ]),
            _row('CCI', ind['cci']!, [
              _numField(ind['cci']!, 'period', 'دوره'),
            ]),
            _row('Williams %R', ind['wpr']!, [
              _numField(ind['wpr']!, 'period', 'دوره'),
            ]),
            _row('Momentum', ind['mom']!, [
              _numField(ind['mom']!, 'period', 'دوره'),
            ]),
            _row('MFI', ind['mfi']!, [
              _numField(ind['mfi']!, 'period', 'دوره'),
            ]),
            Divider(color: cBorder),
            Text('عمومی', style: TextStyle(color: cMuted, fontSize: 12)),
            Row(
              children: [
                Text('بروزرسانی خودکار', style: TextStyle(color: Colors.white)),
                Spacer(),
                DropdownButton<int>(
                  value: s.refresh,
                  dropdownColor: cSurface,
                  items: [
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
                  items: [
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
