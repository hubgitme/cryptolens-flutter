// صفحه اصلی: هدر، تایم‌فریم‌ها، چارت، لجند OHLC و وضعیت
import 'dart:async';

import 'package:flutter/material.dart';

import '../binance.dart';
import '../chart/chart_widget.dart';
import '../drawings.dart';
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
  // رسم‌ها
  Map<String, List<Drawing>> _allDrawings = {};
  String _tool = 'cursor';
  String? _selDrawId;
  int _draftCount = 0;
  int _finishSig = 0;
  int _undoSig = 0;

  List<Drawing> get _drawings => _allDrawings.putIfAbsent(s.symbol, () => []);
  Drawing? get _selDrawing {
    for (final d in _drawings) {
      if (d.id == _selDrawId) return d;
    }
    return null;
  }

  AppSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    _symbolCtrl.text = s.symbol;
    DrawingsStore.load().then((m) {
      if (mounted) setState(() => _allDrawings = m);
    });
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
    _tool = 'cursor';
    _selDrawId = null;
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
    Color col(IndCfg c, Color def) => c.color != null ? Color(c.color!) : def;
    if (o['sma']!.on)
      ov.add(
        LineSeries(
          calcSMA(closes, o['sma']!.p('period', 20).toInt()),
          col(o['sma']!, Color(0xFFF59E0B)),
          width: o['sma']!.width,
        ),
      );
    if (o['ema']!.on)
      ov.add(
        LineSeries(
          calcEMA(closes, o['ema']!.p('period', 20).toInt()),
          col(o['ema']!, Color(0xFF3B82F6)),
          width: o['ema']!.width,
        ),
      );
    if (o['bb']!.on) {
      final bb = calcBB(
        closes,
        o['bb']!.p('period', 20).toInt(),
        o['bb']!.p('mult', 2).toDouble(),
      );
      final bc = col(o['bb']!, Color(0xFFA855F7));
      ov.add(LineSeries(bb.mid, bc, width: o['bb']!.width));
      ov.add(LineSeries(bb.up, bc, width: o['bb']!.width * 0.7));
      ov.add(LineSeries(bb.lo, bc, width: o['bb']!.width * 0.7));
    }
    if (o['vwap']!.on)
      ov.add(
        LineSeries(
          calcVWAP(d, s.iv),
          col(o['vwap']!, Color(0xFF14B8A6)),
          width: o['vwap']!.width,
        ),
      );
    if (o['alligator']!.on) {
      final a = calcAlligator(
        d,
        o['alligator']!.p('jaw', 13).toInt(),
        o['alligator']!.p('teeth', 8).toInt(),
        o['alligator']!.p('lips', 5).toInt(),
      );
      final aw = o['alligator']!.width;
      ov.add(
        LineSeries(
          a.jaw,
          col(o['alligator']!, Color(0xFF3B82F6)),
          width: aw,
          shift: alligatorShift.jaw,
        ),
      );
      ov.add(LineSeries(a.teeth, cRed, width: aw, shift: alligatorShift.teeth));
      ov.add(LineSeries(a.lips, cGreen, width: aw, shift: alligatorShift.lips));
    }

    final panes = <PaneSpec>[];
    final paneKeys = <String>[];
    final ind = s.indicators;
    int pi(String k, String p, int def) => ind[k]!.p(p, def).toInt();
    if (ind['rsi']!.on) {
      paneKeys.add('rsi');
      final p = pi('rsi', 'period', 14);
      panes.add(
        PaneSpec(
          'RSI ($p)',
          [
            LineSeries(
              calcRSI(closes, p),
              col(ind['rsi']!, Color(0xFFA855F7)),
              width: ind['rsi']!.width,
            ),
          ],
          range: (0, 100),
          hlines: [
            ind['rsi']!.p('ob', 70).toDouble(),
            ind['rsi']!.p('os', 30).toDouble(),
          ],
        ),
      );
    }
    if (ind['rsisma']!.on) {
      paneKeys.add('rsisma');
      final p = pi('rsisma', 'period', 14), sm = pi('rsisma', 'sma', 9);
      final r = calcRSI(closes, p);
      panes.add(
        PaneSpec(
          'RSI+SMA ($p,$sm)',
          [
            LineSeries(
              r,
              col(ind['rsisma']!, Color(0xFFA855F7)),
              width: ind['rsisma']!.width,
            ),
            LineSeries(
              calcSMA(r, sm),
              Color(0xFFF59E0B),
              width: ind['rsisma']!.width,
            ),
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
      paneKeys.add('macd');
      final f = pi('macd', 'fast', 12),
          sl2 = pi('macd', 'slow', 26),
          sg = pi('macd', 'sig', 9);
      final m = calcMACD(closes, f, sl2, sg);
      panes.add(
        PaneSpec(
          'MACD ($f,$sl2,$sg)',
          [
            LineSeries(
              m.ml,
              col(ind['macd']!, Color(0xFF2962FF)),
              width: ind['macd']!.width,
            ),
            LineSeries(m.sl, Color(0xFFFF6D00), width: ind['macd']!.width),
          ],
          hist: m.hl,
          hlines: [0],
        ),
      );
    }
    if (ind['stoch']!.on) {
      paneKeys.add('stoch');
      final k = pi('stoch', 'k', 14),
          dd = pi('stoch', 'd', 3),
          sm = pi('stoch', 'smooth', 3);
      final st = calcStoch(d, k, dd, sm);
      panes.add(
        PaneSpec(
          'Stoch ($k,$dd,$sm)',
          [
            LineSeries(
              st.k,
              col(ind['stoch']!, Color(0xFF2962FF)),
              width: ind['stoch']!.width,
            ),
            LineSeries(st.d, Color(0xFFFF6D00), width: ind['stoch']!.width),
          ],
          range: (0, 100),
          hlines: [80, 20],
        ),
      );
    }
    if (ind['atr']!.on) {
      paneKeys.add('atr');
      final p = pi('atr', 'period', 14);
      panes.add(
        PaneSpec('ATR ($p)', [
          LineSeries(
            calcATR(d, p),
            col(ind['atr']!, Color(0xFFF59E0B)),
            width: ind['atr']!.width,
          ),
        ]),
      );
    }
    if (ind['obv']!.on) {
      paneKeys.add('obv');
      final sm = pi('obv', 'sma', 20);
      final obv = calcOBV(d);
      panes.add(
        PaneSpec('OBV+SMA ($sm)', [
          LineSeries(
            obv,
            col(ind['obv']!, Color(0xFF2962FF)),
            width: ind['obv']!.width,
          ),
          LineSeries(
            calcSMA(obv, sm),
            Color(0xFFF59E0B),
            width: ind['obv']!.width,
          ),
        ]),
      );
    }
    if (ind['roc']!.on) {
      paneKeys.add('roc');
      final p = pi('roc', 'period', 9);
      panes.add(
        PaneSpec(
          'ROC ($p)',
          [
            LineSeries(
              calcROC(closes, p),
              col(ind['roc']!, Color(0xFF14B8A6)),
              width: ind['roc']!.width,
            ),
          ],
          hlines: [0],
        ),
      );
    }
    if (ind['adx']!.on) {
      paneKeys.add('adx');
      final p = pi('adx', 'period', 14);
      final a = calcADX(d, p);
      panes.add(
        PaneSpec(
          'ADX ($p)',
          [
            LineSeries(
              a.adx,
              col(ind['adx']!, Colors.white),
              width: ind['adx']!.width,
            ),
            LineSeries(a.pdi, cGreen, width: ind['adx']!.width),
            LineSeries(a.mdi, cRed, width: ind['adx']!.width),
          ],
          range: (0, 100),
        ),
      );
    }
    if (ind['cci']!.on) {
      paneKeys.add('cci');
      final p = pi('cci', 'period', 20);
      panes.add(
        PaneSpec(
          'CCI ($p)',
          [
            LineSeries(
              calcCCI(d, p),
              col(ind['cci']!, Color(0xFF14B8A6)),
              width: ind['cci']!.width,
            ),
          ],
          hlines: [100, -100, 0],
        ),
      );
    }
    if (ind['wpr']!.on) {
      paneKeys.add('wpr');
      final p = pi('wpr', 'period', 14);
      panes.add(
        PaneSpec(
          'Williams %R ($p)',
          [
            LineSeries(
              calcWPR(d, p),
              col(ind['wpr']!, Color(0xFFEC4899)),
              width: ind['wpr']!.width,
            ),
          ],
          range: (-100, 0),
          hlines: [-20, -80],
        ),
      );
    }
    if (ind['mom']!.on) {
      paneKeys.add('mom');
      final p = pi('mom', 'period', 10);
      panes.add(
        PaneSpec(
          'Momentum ($p)',
          [
            LineSeries(
              calcMOM(closes, p),
              col(ind['mom']!, Color(0xFF84CC16)),
              width: ind['mom']!.width,
            ),
          ],
          hlines: [0],
        ),
      );
    }
    if (ind['mfi']!.on) {
      paneKeys.add('mfi');
      final p = pi('mfi', 'period', 14);
      panes.add(
        PaneSpec(
          'MFI ($p)',
          [
            LineSeries(
              calcMFI(d, p),
              col(ind['mfi']!, Color(0xFFA855F7)),
              width: ind['mfi']!.width,
            ),
          ],
          range: (0, 100),
          hlines: [80, 20],
        ),
      );
    }
    final byKey = {
      for (var i = 0; i < panes.length; i++) paneKeys[i]: panes[i],
    };
    final ordered = [
      for (final k in s.paneOrder)
        if (byKey[k] != null) byKey[k]!,
    ];
    return (overlays: ov, panes: ordered);
  }

  // ── نوار ابزار رسم ──
  Widget _toolBtn(String tool, IconData icon, String tip) {
    final active = _tool == tool;
    return IconButton(
      icon: Icon(icon, size: 20, color: active ? cAccent : cText),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: () => setState(() {
        _tool = tool;
        if (tool != 'cursor') _selDrawId = null;
      }),
    );
  }

  Widget _toolTextBtn(String tool, String label, String tip) {
    final active = _tool == tool;
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size(0, 36),
        foregroundColor: active ? cAccent : cText,
      ),
      onPressed: () => setState(() {
        _tool = tool;
        _selDrawId = null;
      }),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  String get _drawHint {
    if (_tool != 'cursor') {
      final h = drawHints[_tool] ?? '';
      final n = drawPointCount[_tool] ?? 2;
      return _draftCount > 0
          ? '$h: نقطه ${_draftCount + 1} از $n'
          : '$h: روی چارت بزنید';
    }
    final sd = _selDrawing;
    if (sd != null) {
      return (sd.locked || s.lockAll)
          ? 'قفل است — برای جابه‌جایی قفل را باز کنید'
          : 'بکشید تا جابه‌جا شود؛ نقطه‌ها را هم می‌توان کشید';
    }
    return s.lockAll ? 'همه‌ی رسم‌ها قفل‌اند' : '';
  }

  Future<void> _pickDrawColor() async {
    final picked = await showColorPalette(context, Color(s.drawColor));
    if (picked == null) return;
    s.drawColor = picked.toARGB32();
    SettingsStore.save(s);
    final sd = _selDrawing;
    if (sd != null) {
      sd.color = s.drawColor;
      DrawingsStore.save(_allDrawings);
    }
    setState(() {});
  }

  Future<void> _clearDrawings() async {
    if (_drawings.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cSurface,
        content: Text('همه‌ی رسم‌های ${s.symbol} پاک شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('نه'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('پاک کن'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _drawings.clear();
      _selDrawId = null;
      DrawingsStore.save(_allDrawings);
      setState(() {});
    }
  }

  Widget _drawToolbar() {
    final sd = _selDrawing;
    final showDone = _draftCount >= 2 && (_tool == 'ewi' || _tool == 'ewc');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _toolBtn('cursor', Icons.mouse, 'انتخاب'),
              _toolBtn('trend', Icons.trending_up, 'خط روند'),
              _toolBtn('hline', Icons.horizontal_rule, 'خط افقی'),
              _toolTextBtn('fib', 'Fib', 'فیبوناچی'),
              _toolTextBtn('ewi', '1-5', 'الیوت ۱-۵'),
              _toolTextBtn('ewc', 'ABC', 'الیوت ABC'),
              IconButton(
                icon: Icon(
                  Icons.gps_fixed,
                  size: 20,
                  color: s.magnet ? cAccent : cText,
                ),
                tooltip: 'مگنت (چسبیدن به OHLC)',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  s.magnet = !s.magnet;
                  SettingsStore.save(s);
                }),
              ),
              GestureDetector(
                onTap: _pickDrawColor,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Color(s.drawColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: cBorder),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  (sd?.locked ?? false) ? Icons.lock : Icons.lock_open,
                  size: 20,
                  color: sd == null ? cMuted : cText,
                ),
                tooltip: 'قفل رسم انتخاب‌شده',
                visualDensity: VisualDensity.compact,
                onPressed: sd == null
                    ? null
                    : () => setState(() {
                        sd.locked = !sd.locked;
                        DrawingsStore.save(_allDrawings);
                      }),
              ),
              IconButton(
                icon: Icon(
                  Icons.lock,
                  size: 20,
                  color: s.lockAll ? cAccent : cText,
                ),
                tooltip: 'قفل همه‌ی رسم‌ها',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  s.lockAll = !s.lockAll;
                  SettingsStore.save(s);
                }),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: sd == null ? cMuted : cText,
                ),
                tooltip: 'حذف رسم انتخاب‌شده',
                visualDensity: VisualDensity.compact,
                onPressed: sd == null
                    ? null
                    : () => setState(() {
                        _drawings.removeWhere((d) => d.id == sd.id);
                        _selDrawId = null;
                        DrawingsStore.save(_allDrawings);
                      }),
              ),
              IconButton(
                icon: Icon(Icons.undo, size: 20, color: cText),
                tooltip: 'برگرداندن',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _undoSig++),
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep, size: 20, color: cText),
                tooltip: 'پاک‌کردن همه‌ی رسم‌ها',
                visualDensity: VisualDensity.compact,
                onPressed: _clearDrawings,
              ),
              if (showDone)
                TextButton(
                  onPressed: () => setState(() => _finishSig++),
                  child: Text('تمام ✓'),
                ),
            ],
          ),
        ),
        if (_drawHint.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _drawHint,
              style: TextStyle(color: cMuted, fontSize: 11),
            ),
          ),
      ],
    );
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
          _drawToolbar(),
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
                      drawings: _drawings,
                      tool: _tool,
                      drawColor: s.drawColor,
                      magnet: s.magnet,
                      lockAll: s.lockAll,
                      fibLevels: s.fibLevels,
                      selectedDrawingId: _selDrawId,
                      finishSignal: _finishSig,
                      undoSignal: _undoSig,
                      onDrawingsChanged: () => DrawingsStore.save(_allDrawings),
                      onSelectDrawing: (id) {
                        if (_selDrawId != id) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selDrawId = id);
                          });
                        }
                      },
                      onToolDone: () => setState(() => _tool = 'cursor'),
                      onDraftCount: (n) {
                        if (_draftCount != n) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _draftCount = n);
                          });
                        }
                      },
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
