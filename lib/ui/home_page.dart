// صفحه اصلی: هدر، تایم‌فریم‌ها، چارت، لجند OHLC و وضعیت
import 'dart:async';

import 'package:flutter/material.dart';

import '../binance.dart';
import '../chart/chart_widget.dart';
import '../format.dart';
import '../indicators.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import 'indicator_sheet.dart';
import 'watchlist_drawer.dart';

class HomePage extends StatefulWidget {
  final AppSettings settings;
  const HomePage({super.key, required this.settings});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _symbolCtrl = TextEditingController();
  List<Candle> _candles = [];
  bool _loading = false;
  String _status = 'آماده';
  int? _selected;
  int _version = 0;
  Timer? _timer;

  AppSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    _symbolCtrl.text = s.symbol;
    _load();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _symbolCtrl.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (s.refresh > 0)
      _timer = Timer.periodic(
        Duration(seconds: s.refresh),
        (_) => _refreshLatest(),
      );
  }

  void _saveAndRefresh() {
    SettingsStore.save(s);
    _restartTimer();
    setState(() => _version++);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = 'در حال دریافت داده…';
    });
    try {
      final data = await fetchKlines(
        s.symbol,
        s.iv,
        s.limit,
        customBase: s.apiBase,
      );
      if (!mounted) return;
      setState(() {
        _candles = data;
        _selected = null;
        _version++;
        _status = 'آخرین بروزرسانی ${fmtClock(DateTime.now())}';
      });
    } catch (e) {
      if (mounted) setState(() => _status = '❌ $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshLatest() async {
    if (_candles.isEmpty) return _load();
    try {
      final fresh = await fetchKlines(s.symbol, s.iv, 5, customBase: s.apiBase);
      if (!mounted) return;
      setState(() {
        _candles = mergeCandles(_candles, fresh, 1500, 1000).candles;
        _version++;
        _status = 'آخرین بروزرسانی ${fmtClock(DateTime.now())}';
      });
    } catch (_) {}
  }

  void _pickSymbol(String sym) {
    s.symbol = sym;
    _symbolCtrl.text = sym;
    SettingsStore.save(s);
    _load();
  }

  void _toggleSave() {
    final sym = _symbolCtrl.text.trim().toUpperCase();
    if (!symbolRe.hasMatch(sym)) return;
    if (s.savedSymbols.contains(sym)) {
      s.savedSymbols.remove(sym);
    } else {
      s.savedSymbols.add(sym);
      s.watchlistHidden.remove(sym); // ستاره دوباره = برگرداندن به لیست
    }
    SettingsStore.save(s);
    setState(() {});
  }

  ({List<LineSeries> overlays, List<PaneSpec> panes}) _buildSeries(
    List<Candle> d,
  ) {
    final closes = d.map((c) => c.close).toList();
    final ov = <LineSeries>[];
    final o = s.overlays;
    if (o['sma']!.on)
      ov.add(
        LineSeries(
          calcSMA(closes, o['sma']!.p('period', 20).toInt()),
          Color(0xFFF59E0B),
        ),
      );
    if (o['ema']!.on)
      ov.add(
        LineSeries(
          calcEMA(closes, o['ema']!.p('period', 20).toInt()),
          Color(0xFF3B82F6),
        ),
      );
    if (o['bb']!.on) {
      final bb = calcBB(
        closes,
        o['bb']!.p('period', 20).toInt(),
        o['bb']!.p('mult', 2).toDouble(),
      );
      ov.add(LineSeries(bb.mid, Color(0xFFA855F7)));
      ov.add(LineSeries(bb.up, Color(0xFFA855F7), width: 0.8));
      ov.add(LineSeries(bb.lo, Color(0xFFA855F7), width: 0.8));
    }
    if (o['vwap']!.on) ov.add(LineSeries(calcVWAP(d, s.iv), Color(0xFF14B8A6)));
    if (o['alligator']!.on) {
      final a = calcAlligator(
        d,
        o['alligator']!.p('jaw', 13).toInt(),
        o['alligator']!.p('teeth', 8).toInt(),
        o['alligator']!.p('lips', 5).toInt(),
      );
      ov.add(LineSeries(a.jaw, Color(0xFF3B82F6), shift: alligatorShift.jaw));
      ov.add(LineSeries(a.teeth, cRed, shift: alligatorShift.teeth));
      ov.add(LineSeries(a.lips, cGreen, shift: alligatorShift.lips));
    }

    final panes = <PaneSpec>[];
    final ind = s.indicators;
    int pi(String k, String p, int def) => ind[k]!.p(p, def).toInt();
    if (ind['rsi']!.on) {
      final p = pi('rsi', 'period', 14);
      panes.add(
        PaneSpec(
          'RSI ($p)',
          [LineSeries(calcRSI(closes, p), Color(0xFFA855F7))],
          range: (0, 100),
          hlines: [
            ind['rsi']!.p('ob', 70).toDouble(),
            ind['rsi']!.p('os', 30).toDouble(),
          ],
        ),
      );
    }
    if (ind['rsisma']!.on) {
      final p = pi('rsisma', 'period', 14), sm = pi('rsisma', 'sma', 9);
      final r = calcRSI(closes, p);
      panes.add(
        PaneSpec(
          'RSI+SMA ($p,$sm)',
          [
            LineSeries(r, Color(0xFFA855F7)),
            LineSeries(calcSMA(r, sm), Color(0xFFF59E0B)),
          ],
          range: (0, 100),
          hlines: [
            ind['rsisma']!.p('hi', 70).toDouble(),
            ind['rsisma']!.p('lo', 40).toDouble(),
          ],
        ),
      );
    }
    if (ind['macd']!.on) {
      final f = pi('macd', 'fast', 12),
          sl2 = pi('macd', 'slow', 26),
          sg = pi('macd', 'sig', 9);
      final m = calcMACD(closes, f, sl2, sg);
      panes.add(
        PaneSpec(
          'MACD ($f,$sl2,$sg)',
          [
            LineSeries(m.ml, Color(0xFF2962FF)),
            LineSeries(m.sl, Color(0xFFFF6D00)),
          ],
          hist: m.hl,
          hlines: [0],
        ),
      );
    }
    if (ind['stoch']!.on) {
      final k = pi('stoch', 'k', 14),
          dd = pi('stoch', 'd', 3),
          sm = pi('stoch', 'smooth', 3);
      final st = calcStoch(d, k, dd, sm);
      panes.add(
        PaneSpec(
          'Stoch ($k,$dd,$sm)',
          [
            LineSeries(st.k, Color(0xFF2962FF)),
            LineSeries(st.d, Color(0xFFFF6D00)),
          ],
          range: (0, 100),
          hlines: [80, 20],
        ),
      );
    }
    if (ind['atr']!.on) {
      final p = pi('atr', 'period', 14);
      panes.add(
        PaneSpec('ATR ($p)', [LineSeries(calcATR(d, p), Color(0xFFF59E0B))]),
      );
    }
    if (ind['obv']!.on) {
      final sm = pi('obv', 'sma', 20);
      final obv = calcOBV(d);
      panes.add(
        PaneSpec('OBV+SMA ($sm)', [
          LineSeries(obv, Color(0xFF2962FF)),
          LineSeries(calcSMA(obv, sm), Color(0xFFF59E0B)),
        ]),
      );
    }
    if (ind['roc']!.on) {
      final p = pi('roc', 'period', 9);
      panes.add(
        PaneSpec(
          'ROC ($p)',
          [LineSeries(calcROC(closes, p), Color(0xFF14B8A6))],
          hlines: [0],
        ),
      );
    }
    if (ind['adx']!.on) {
      final p = pi('adx', 'period', 14);
      final a = calcADX(d, p);
      panes.add(
        PaneSpec(
          'ADX ($p)',
          [
            LineSeries(a.adx, Colors.white),
            LineSeries(a.pdi, cGreen),
            LineSeries(a.mdi, cRed),
          ],
          range: (0, 100),
        ),
      );
    }
    if (ind['cci']!.on) {
      final p = pi('cci', 'period', 20);
      panes.add(
        PaneSpec(
          'CCI ($p)',
          [LineSeries(calcCCI(d, p), Color(0xFF14B8A6))],
          hlines: [100, -100, 0],
        ),
      );
    }
    if (ind['wpr']!.on) {
      final p = pi('wpr', 'period', 14);
      panes.add(
        PaneSpec(
          'Williams %R ($p)',
          [LineSeries(calcWPR(d, p), Color(0xFFEC4899))],
          range: (-100, 0),
          hlines: [-20, -80],
        ),
      );
    }
    if (ind['mom']!.on) {
      final p = pi('mom', 'period', 10);
      panes.add(
        PaneSpec(
          'Momentum ($p)',
          [LineSeries(calcMOM(closes, p), Color(0xFF84CC16))],
          hlines: [0],
        ),
      );
    }
    if (ind['mfi']!.on) {
      final p = pi('mfi', 'period', 14);
      panes.add(
        PaneSpec(
          'MFI ($p)',
          [LineSeries(calcMFI(d, p), Color(0xFFA855F7))],
          range: (0, 100),
          hlines: [80, 20],
        ),
      );
    }
    return (overlays: ov, panes: panes);
  }

  @override
  Widget build(BuildContext context) {
    final display = s.chartType == 'ha' ? toHeikinAshi(_candles) : _candles;
    final series = _buildSeries(display);
    final sel = (_selected != null && _selected! < display.length)
        ? display[_selected!]
        : (display.isNotEmpty ? display.last : null);
    final saved = s.savedSymbols.contains(
      _symbolCtrl.text.trim().toUpperCase(),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cBg,
      drawer: WatchlistDrawer(
        settings: s,
        onPick: _pickSymbol,
        onChanged: _saveAndRefresh,
      ),
      appBar: AppBar(
        backgroundColor: cSurface,
        leading: IconButton(
          icon: Icon(Icons.list, color: cText),
          tooltip: 'لیست ارزها',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _symbolCtrl,
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'BTCUSDT',
                  isDense: true,
                  border: InputBorder.none,
                ),
                onSubmitted: (v) {
                  final sym = v.trim().toUpperCase();
                  if (symbolRe.hasMatch(sym)) _pickSymbol(sym);
                },
              ),
            ),
            IconButton(
              icon: Icon(
                saved ? Icons.star : Icons.star_border,
                color: saved ? Color(0xFFF59E0B) : cMuted,
              ),
              tooltip: saved ? 'برداشتن از ذخیره‌شده‌ها' : 'ذخیره‌ی این ارز',
              onPressed: _toggleSave,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.show_chart, color: cText),
            tooltip: 'اندیکاتورها و تنظیمات',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: cSurface,
              builder: (_) =>
                  IndicatorSheet(settings: s, onChanged: _saveAndRefresh),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: cText),
            tooltip: 'بروزرسانی',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final iv in intervals)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    child: ChoiceChip(
                      label: Text(iv.toUpperCase()),
                      selected: s.iv == iv,
                      onSelected: (_) {
                        s.iv = iv;
                        SettingsStore.save(s);
                        _load();
                      },
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  child: ChoiceChip(
                    label: Text('HA'),
                    selected: s.chartType == 'ha',
                    onSelected: (v) {
                      s.chartType = v ? 'ha' : 'candles';
                      SettingsStore.save(s);
                      setState(() => _version++);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (sel != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Wrap(
                  spacing: 10,
                  children: [
                    Text(
                      '${s.symbol} · ${s.iv.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'O ${fmtPrice(sel.open)}',
                      style: TextStyle(color: cText, fontSize: 12),
                    ),
                    Text(
                      'H ${fmtPrice(sel.high)}',
                      style: TextStyle(color: cText, fontSize: 12),
                    ),
                    Text(
                      'L ${fmtPrice(sel.low)}',
                      style: TextStyle(color: cText, fontSize: 12),
                    ),
                    Text(
                      'C ${fmtPrice(sel.close)}',
                      style: TextStyle(
                        color: sel.close >= sel.open ? cGreen : cRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading && _candles.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: ChartView(
                      candles: display,
                      overlays: series.overlays,
                      panes: series.panes,
                      volumeOn: s.overlays['volume']!.on,
                      iv: s.iv,
                      version: _version,
                      onSelect: (i) => setState(() => _selected = i),
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(6),
            child: Text(_status, style: TextStyle(color: cMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
