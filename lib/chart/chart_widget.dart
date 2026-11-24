// چارت کندلی نیتیو با CustomPainter: پنل قیمت + پنل‌های اندیکاتور هم‌محور، زوم/پن با ژست، کراس‌هیر با لمس طولانی
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../drawings.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';

const _paneLineLabels = {
  'rsisma': ['RSI', 'SMA'],
  'macd': ['MACD', 'Signal'],
  'stoch': ['%K', '%D'],
  'atr': ['ATR'],
  'obv': ['OBV', 'SMA'],
  'rocma': ['ROC', 'MA'],
  'adx': ['ADX', '+DI', '-DI'],
  'cci': ['CCI'],
  'wpr': ['%R'],
  'mom': ['MOM'],
  'mfi': ['MFI'],
};

double? _lineValue(List<double?> vs, int? selected) {
  if (selected != null &&
      selected >= 0 &&
      selected < vs.length &&
      vs[selected] != null) {
    return vs[selected];
  }
  for (var i = vs.length - 1; i >= 0; i--) {
    if (vs[i] != null) return vs[i];
  }
  return null;
}

class LineSeries {
  final List<double?> values;
  final Color color;
  final double width;
  final int shift; // جابه‌جایی رو به جلو (Alligator)
  const LineSeries(this.values, this.color, {this.width = 1.2, this.shift = 0});
}

class PaneSpec {
  final String key;
  final String title;
  final List<LineSeries> lines;
  final List<double?>? hist;
  final (double, double)? range; // بازه ثابت (مثل RSI: 0..100)
  final List<double> hlines;
  const PaneSpec(
    this.key,
    this.title,
    this.lines, {
    this.hist,
    this.range,
    this.hlines = const [],
  });
}

class ChartView extends StatefulWidget {
  final List<Candle> candles;
  final List<LineSeries> overlays;
  final List<PaneSpec> panes;
  final bool volumeOn;
  final String iv;
  final int version; // با هر داده/تنظیم تازه عوض میشود
  final void Function(int? index)? onSelect;
  // رسم‌ها
  final List<Drawing> drawings;
  final String tool; // cursor | trend | hline | fib | ewi | ewc
  final int drawColor;
  final bool magnet;
  final bool lockAll;
  final List<double> fibLevels;
  final String? selectedDrawingId;
  final int finishSignal; // تغییرش = تمام‌کردن رسم نیمه‌کاره
  final int undoSignal; // تغییرش = برگرداندن آخرین نقطه/رسم
  final Map<String, double> paneHeights; // ارتفاع پنل‌ها (+ 'price')
  final void Function(Map<String, double>)? onPaneHeightsChanged;
  final void Function(String key, int dir)? onMovePane;
  final void Function(String key)? onClosePane;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onDrawingsChanged;
  final void Function(String? id)? onSelectDrawing;
  final VoidCallback? onToolDone;
  final void Function(int count)? onDraftCount;
  const ChartView({
    super.key,
    required this.candles,
    required this.overlays,
    required this.panes,
    required this.volumeOn,
    required this.iv,
    required this.version,
    this.onSelect,
    required this.drawings,
    this.tool = 'cursor',
    this.drawColor = 0xFFF59E0B,
    this.magnet = true,
    this.lockAll = false,
    this.fibLevels = const [
      0,
      0.236,
      0.382,
      0.5,
      0.618,
      0.786,
      1,
      1.272,
      1.618,
    ],
    this.selectedDrawingId,
    this.finishSignal = 0,
    this.undoSignal = 0,
    this.paneHeights = const {},
    this.onPaneHeightsChanged,
    this.onMovePane,
    this.onClosePane,
    this.onOpenSettings,
    this.onDrawingsChanged,
    this.onSelectDrawing,
    this.onToolDone,
    this.onDraftCount,
  });

  @override
  State<ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  int _visible = 110;
  int _offset = 0; // چند کندل از انتها عقب‌تر دیده میشود
  int? _selected;
  int _startVisible = 110;
  double _panAcc = 0;
  double _plotW = 300;
  double _vOffset = 0; // اسکرول عمودی پنل‌ها
  double _maxVOffset = 0;
  double _priceH = 300; // ارتفاع پنل قیمت (برای تبدیل مختصات رسم)
  double _vOffNow = 0;
  (double, double)? _range; // بازه قیمت فعلی پنل قیمت
  List<DrawPt> _draft = []; // نقطه‌های رسم در حال ساخت
  String? _dragId;
  int? _dragPt;
  List<Offset>? _dragOrig;
  Offset? _dragStart;
  // مقیاس قیمت آزاد (مثل تریدینگ‌ویو): جابه‌جایی و زوم عمودی
  double _pShiftFrac = 0;
  double _pScale = 1;
  // ارتفاع پنل‌ها و حالت ژست جاری
  Map<String, double> _heights = {};
  int _gMode = 0; // 0 اسکرول صفحه، 1 پن قیمت، 2 زوم محور قیمت، 3 تغییر ارتفاع
  String? _resizeKey;
  double _resizeStartH = 0;
  double _resizeStartY = 0;

  @override
  void initState() {
    super.initState();
    _heights = Map.of(widget.paneHeights);
  }

  double _paneHAt(int i) => _heights[widget.panes[i].key] ?? 110.0;

  List<double> _edges(double priceH, List<double> paneHs) {
    final out = <double>[priceH];
    var acc = priceH;
    for (final h in paneHs) {
      acc += _legendH + h;
      out.add(acc);
    }
    return out;
  }

  Widget _legendRow(PaneSpec pane) {
    final labels = _paneLineLabels[pane.key] ?? const <String>[];
    final spans = <TextSpan>[];
    for (var i = 0; i < pane.lines.length; i++) {
      final v = _lineValue(pane.lines[i].values, _selected);
      final label = i < labels.length ? labels[i] : '';
      spans.add(
        TextSpan(
          text:
              '${label.isEmpty ? '' : '$label '}${v == null ? '—' : fmtNum(v)}  ',
          style: TextStyle(color: pane.lines[i].color, fontSize: 11),
        ),
      );
    }
    Widget miniBtn(IconData icon, VoidCallback? onTap, String tip) {
      return IconButton(
        icon: Icon(icon, size: 14, color: cMuted),
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 22, minHeight: 22),
        onPressed: onTap,
      );
    }

    return SizedBox(
      height: _legendH,
      child: Row(
        children: [
          SizedBox(width: 6),
          Text(
            pane.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          miniBtn(
            Icons.arrow_drop_up,
            widget.lockAll ? null : () => widget.onMovePane?.call(pane.key, -1),
            'بالاتر',
          ),
          miniBtn(
            Icons.arrow_drop_down,
            widget.lockAll ? null : () => widget.onMovePane?.call(pane.key, 1),
            'پایین‌تر',
          ),
          miniBtn(Icons.settings, widget.onOpenSettings, 'تنظیمات'),
          miniBtn(
            Icons.close,
            widget.lockAll ? null : () => widget.onClosePane?.call(pane.key),
            'حذف از چارت',
          ),
          SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(children: spans),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (double, double)? _effRange((double, double)? base) {
    if (base == null) return null;
    final c = (base.$1 + base.$2) / 2;
    final h = (base.$2 - base.$1) / 2;
    final shift = _pShiftFrac * h * 2;
    return (c - h / _pScale + shift, c + h / _pScale + shift);
  }

  static const double _axisW = 58;
  static const double _legendH = 22; // ارتفاع ردیف لجند هر پنل
  static const int _rightPad = 8; // فضای خالی پیش‌فرض بعد از آخرین کندل

  int get _start => widget.candles.length + _rightPad - _offset - _visible;

  int _indexForX(double x) {
    if (widget.candles.isEmpty) return 0;
    final cw = _plotW / _visible;
    return (_start + (x / cw).floor()).clamp(0, widget.candles.length - 1);
  }

  void _select(int? i) {
    setState(() => _selected = i);
    widget.onSelect?.call(i);
  }

  int get _ivS => ivSeconds[widget.iv] ?? 3600;

  Drawing? get _selectedDrawing {
    for (final d in widget.drawings) {
      if (d.id == widget.selectedDrawingId) return d;
    }
    return null;
  }

  double _yForPrice(double v) {
    final r = _range;
    if (r == null) return 0;
    return _priceH - (v - r.$1) / (r.$2 - r.$1) * _priceH;
  }

  Offset _xyForPt(DrawPt pt) {
    final cw = _plotW / _visible;
    final lg = (pt.t - widget.candles[0].time) / _ivS;
    return Offset((lg - _start + 0.5) * cw, _yForPrice(pt.p));
  }

  DrawPt? _ptForXY(double x, double py) {
    if (widget.candles.isEmpty || _range == null) return null;
    final r = _range!;
    final price = r.$1 + (1 - py / _priceH) * (r.$2 - r.$1);
    final cw = _plotW / _visible;
    final idx = _start + (x / cw - 0.5).round();
    return DrawPt(widget.candles[0].time + idx * _ivS, price);
  }

  DrawPt? _snap(double x, double py) {
    final pt = _ptForXY(x, py);
    if (pt == null || !widget.magnet) return pt;
    final idx = ((pt.t - widget.candles[0].time) / _ivS).round();
    if (idx < 0 || idx >= widget.candles.length) return pt;
    final c = widget.candles[idx];
    var best = pt.p, bd = 18.0;
    for (final v in [c.open, c.high, c.low, c.close]) {
      final d = (_yForPrice(v) - py).abs();
      if (d < bd) {
        bd = d;
        best = v;
      }
    }
    return DrawPt(pt.t, best);
  }

  static double _distSeg(double px, double py, Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final l2 = dx * dx + dy * dy;
    var t = l2 == 0 ? 0.0 : ((px - a.dx) * dx + (py - a.dy) * dy) / l2;
    t = t.clamp(0.0, 1.0);
    final ex = px - (a.dx + t * dx), ey = py - (a.dy + t * dy);
    return math.sqrt(ex * ex + ey * ey);
  }

  String? _hitTest(double x, double py) {
    const r = 12.0;
    if (widget.candles.isEmpty) return null;
    for (var k = widget.drawings.length - 1; k >= 0; k--) {
      final d = widget.drawings[k];
      final p = d.pts.map(_xyForPt).toList();
      if (d.type == 'hline') {
        if ((p[0].dy - py).abs() < r) return d.id;
        continue;
      }
      for (var i = 0; i < p.length - 1; i++) {
        if (_distSeg(x, py, p[i], p[i + 1]) < r) return d.id;
      }
      if (d.type == 'fib') {
        final xl = math.min(p[0].dx, p[1].dx);
        if (x >= xl - r && x <= _plotW) {
          for (final l in widget.fibLevels) {
            final price = d.pts[1].p + (d.pts[0].p - d.pts[1].p) * l;
            if ((_yForPrice(price) - py).abs() < r) return d.id;
          }
        }
      }
    }
    return null;
  }

  void _commitDraft() {
    final d = Drawing(
      id: newDrawId(),
      type: widget.tool,
      color: widget.drawColor,
      pts: List.of(_draft),
    );
    widget.drawings.add(d);
    _draft = [];
    widget.onDraftCount?.call(0);
    widget.onDrawingsChanged?.call();
    widget.onSelectDrawing?.call(d.id);
    widget.onToolDone?.call();
    setState(() {});
  }

  void _finishDraft() {
    if (_draft.length >= (widget.tool == 'hline' ? 1 : 2)) {
      _commitDraft();
    } else {
      _draft = [];
      widget.onDraftCount?.call(0);
      setState(() {});
    }
  }

  void _undo() {
    if (_draft.isNotEmpty) {
      _draft.removeLast();
      widget.onDraftCount?.call(_draft.length);
    } else if (widget.drawings.isNotEmpty) {
      widget.drawings.removeLast();
      widget.onSelectDrawing?.call(null);
      widget.onDrawingsChanged?.call();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(ChartView old) {
    super.didUpdateWidget(old);
    if (old.tool != widget.tool) {
      _draft = [];
      widget.onDraftCount?.call(0);
    }
    if (old.finishSignal != widget.finishSignal) _finishDraft();
    if (old.undoSignal != widget.undoSignal) _undo();
    if (_gMode != 3) _heights = Map.of(widget.paneHeights);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        _plotW = math.max(50, cons.maxWidth - _axisW);
        final paneCount = widget.panes.length;
        // هر پنل ارتفاع خودش را دارد (قابل تغییر با کشیدن لبه پایین)؛ مجموع بلندتر از صفحه اسکرول میشود
        final scrollH = math.max(50.0, cons.maxHeight - 22);
        final priceH =
            _heights['price'] ??
            (paneCount == 0 ? scrollH : math.max(280.0, scrollH * 0.6));
        final paneHs = [for (var i = 0; i < paneCount; i++) _paneHAt(i)];
        final contentH = priceH + paneHs.fold(0.0, (a, b) => a + b + _legendH);
        _maxVOffset = math.max(0.0, contentH - scrollH);
        final vOff = _vOffset.clamp(0.0, _maxVOffset);
        _priceH = priceH;
        _vOffNow = vOff;
        _range = _effRange(
          _priceRange(widget.candles, widget.overlays, _start, _visible),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) {
            _startVisible = _visible;
            _panAcc = 0;
            _dragId = null;
            _dragPt = null;
            _dragOrig = null;
            _dragStart = null;
            _gMode = 0;
            _resizeKey = null;
            final x = d.localFocalPoint.dx;
            final cy = d.localFocalPoint.dy + _vOffNow; // مختصات محتوا
            // اول: کشیدن رسم انتخاب‌شده
            if (widget.tool == 'cursor' && !widget.lockAll) {
              final sel = _selectedDrawing;
              if (sel != null && !sel.locked && widget.candles.isNotEmpty) {
                if (cy >= 0 && cy <= _priceH && x <= _plotW) {
                  for (var i = 0; i < sel.pts.length; i++) {
                    if ((_xyForPt(sel.pts[i]) - Offset(x, cy)).distance <= 22) {
                      _dragId = sel.id;
                      _dragPt = i;
                      break;
                    }
                  }
                  if (_dragId == null && _hitTest(x, cy) == sel.id) {
                    _dragId = sel.id;
                    _dragOrig = sel.pts.map(_xyForPt).toList();
                    _dragStart = d.localFocalPoint;
                  }
                }
              }
            }
            if (_dragId != null) return;
            // تغییر ارتفاع پنل: نزدیک لبه پایین هر پنل (در حالت قفل غیرفعال)
            if (!widget.lockAll && widget.panes.isNotEmpty) {
              var edge = _priceH;
              if ((cy - edge).abs() <= 10) {
                _gMode = 3;
                _resizeKey = 'price';
                _resizeStartH = _priceH;
                _resizeStartY = d.localFocalPoint.dy;
                return;
              }
              for (var i = 0; i < widget.panes.length; i++) {
                edge += _legendH + _paneHAt(i);
                if ((cy - edge).abs() <= 10) {
                  _gMode = 3;
                  _resizeKey = widget.panes[i].key;
                  _resizeStartH = _paneHAt(i);
                  _resizeStartY = d.localFocalPoint.dy;
                  return;
                }
              }
            }
            // روی پنل قیمت: درگ عمودی = جابه‌جایی قیمت؛ روی محور = زوم مقیاس
            if (cy < _priceH) _gMode = x > _plotW ? 2 : 1;
          },
          onScaleEnd: (_) {
            if (_dragId != null) {
              _dragId = null;
              _dragPt = null;
              _dragOrig = null;
              _dragStart = null;
              widget.onDrawingsChanged?.call();
            }
            if (_gMode == 3) {
              widget.onPaneHeightsChanged?.call(Map.of(_heights));
            }
            _gMode = 0;
            _resizeKey = null;
          },
          onScaleUpdate: (d) {
            if (_dragId != null) {
              final sel = _selectedDrawing;
              if (sel != null) {
                if (_dragPt != null) {
                  final pt = _snap(
                    d.localFocalPoint.dx,
                    d.localFocalPoint.dy + _vOffNow,
                  );
                  if (pt != null) sel.pts[_dragPt!] = pt;
                } else if (_dragOrig != null && _dragStart != null) {
                  final dx = d.localFocalPoint.dx - _dragStart!.dx;
                  final dy = d.localFocalPoint.dy - _dragStart!.dy;
                  final np = <DrawPt>[];
                  var ok = true;
                  for (final q in _dragOrig!) {
                    final pt = _ptForXY(q.dx + dx, q.dy + dy);
                    if (pt == null) {
                      ok = false;
                      break;
                    }
                    np.add(pt);
                  }
                  if (ok) sel.pts = np;
                }
              }
              setState(() {});
              return;
            }
            if (_gMode == 3 && _resizeKey != null) {
              final dy = d.localFocalPoint.dy - _resizeStartY;
              final minH = _resizeKey == 'price' ? 180.0 : 60.0;
              setState(
                () => _heights[_resizeKey!] = (_resizeStartH + dy).clamp(
                  minH,
                  900.0,
                ),
              );
              return;
            }
            setState(() {
              if (d.scale != 1) {
                _visible = (_startVisible / d.scale).round().clamp(
                  20,
                  math.max(20, widget.candles.length + _rightPad),
                );
              }
              _panAcc += d.focalPointDelta.dx;
              final cw = _plotW / _visible;
              final delta = (_panAcc / cw).round();
              if (delta != 0) {
                // شیفت آزاد به چپ مثل تریدینگ‌ویو: تا وقتی حداقل ۱۰ کندل روی صفحه بماند
                _offset = (_offset + delta).clamp(
                  18 - _visible,
                  math.max(0, widget.candles.length - 20),
                );
                _panAcc -= delta * cw;
              }
              if (_gMode == 1) {
                // جابه‌جایی عمودی قیمت (چارت آزاد از بقیه)
                _pShiftFrac += d.focalPointDelta.dy / _priceH / _pScale;
              } else if (_gMode == 2) {
                // زوم مقیاس قیمت با کشیدن محور
                _pScale = (_pScale * math.exp(-d.focalPointDelta.dy / 150))
                    .clamp(0.2, 5.0);
              } else {
                _vOffset = (_vOffset - d.focalPointDelta.dy).clamp(
                  0.0,
                  _maxVOffset,
                );
              }
            });
          },
          onLongPressStart: (d) => _select(_indexForX(d.localPosition.dx)),
          onLongPressMoveUpdate: (d) => _select(_indexForX(d.localPosition.dx)),
          onTapUp: (d) {
            final x = d.localPosition.dx;
            final py = d.localPosition.dy + _vOffNow;
            if (widget.tool != 'cursor') {
              if (py < 0 || py > _priceH || x > _plotW) return;
              final pt = _snap(x, py);
              if (pt == null) return;
              setState(() => _draft.add(pt));
              widget.onDraftCount?.call(_draft.length);
              if (_draft.length >= (drawPointCount[widget.tool] ?? 2)) {
                _commitDraft();
              }
              return;
            }
            if (py >= 0 && py <= _priceH && x <= _plotW) {
              final hit = _hitTest(x, py);
              if (hit != null) {
                widget.onSelectDrawing?.call(hit);
                return;
              }
              widget.onSelectDrawing?.call(null);
            }
            _select(_indexForX(x));
          },
          onDoubleTap: () => setState(() {
            _visible = 110;
            _offset = 0;
            _vOffset = 0;
            _pShiftFrac = 0;
            _pScale = 1;
            _selected = null;
          }),
          child: Column(
            children: [
              SizedBox(
                height: scrollH,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -vOff,
                        height: contentH,
                        child: Column(
                          children: [
                            SizedBox(
                              height: priceH,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _PricePainter(
                                  widget.candles,
                                  widget.overlays,
                                  widget.volumeOn,
                                  _start,
                                  _visible,
                                  _selected,
                                  _axisW,
                                  drawings: widget.drawings,
                                  range: _range,
                                  draftPts: _draft,
                                  draftType: widget.tool,
                                  drawColor: widget.drawColor,
                                  selectedDrawingId: widget.selectedDrawingId,
                                  tool: widget.tool,
                                  lockAll: widget.lockAll,
                                  fibLevels: widget.fibLevels,
                                  ivSec: _ivS,
                                ),
                              ),
                            ),
                            for (var i = 0; i < widget.panes.length; i++) ...[
                              _legendRow(widget.panes[i]),
                              SizedBox(
                                height: paneHs[i],
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: _PanePainter(
                                    widget.panes[i],
                                    widget.candles.length,
                                    _start,
                                    _visible,
                                    _selected,
                                    _axisW,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // دستگیره‌های تغییر ارتفاع پنل‌ها (لبه پایین هر پنل؛ در حالت قفل پنهان)
                      if (paneCount > 0 && !widget.lockAll)
                        for (final edge in _edges(priceH, paneHs))
                          Positioned(
                            top: edge - vOff - 7,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: cMuted.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      if (_maxVOffset > 0)
                        Positioned(
                          right: 2,
                          top:
                              (scrollH -
                                  math.max(
                                    30.0,
                                    scrollH * scrollH / contentH,
                                  )) *
                              (vOff / _maxVOffset),
                          child: Container(
                            width: 4,
                            height: math.max(
                              30.0,
                              scrollH * scrollH / contentH,
                            ),
                            decoration: BoxDecoration(
                              color: cMuted.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 22,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TimePainter(
                    widget.candles,
                    widget.iv,
                    _start,
                    _visible,
                    _axisW,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

(double, double)? _priceRange(
  List<Candle> candles,
  List<LineSeries> overlays,
  int start,
  int visible,
) {
  var lo = double.infinity, hi = double.negativeInfinity;
  for (
    var i = math.max(0, start);
    i < math.min(candles.length, start + visible);
    i++
  ) {
    lo = math.min(lo, candles[i].low);
    hi = math.max(hi, candles[i].high);
  }
  for (final s in overlays) {
    for (
      var i = math.max(0, start);
      i < math.min(s.values.length, start + visible);
      i++
    ) {
      final v = s.values[i];
      if (v != null && v.isFinite) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
  }
  if (!lo.isFinite) return null;
  final pad = (hi - lo) * 0.06 + 1e-9;
  return (lo - pad, hi + pad);
}

String _fmtLevel(double l) =>
    l == l.roundToDouble() ? l.toInt().toString() : l.toString();

void _text(
  Canvas canvas,
  String s,
  Offset at,
  Color color,
  double size, {
  TextAlign align = TextAlign.left,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(color: color, fontSize: size),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout();
  final dx = align == TextAlign.right
      ? at.dx - tp.width
      : align == TextAlign.center
      ? at.dx - tp.width / 2
      : at.dx;
  tp.paint(canvas, Offset(dx, at.dy));
}

void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
  const dash = 5.0, gap = 4.0;
  final len = (b - a).distance;
  if (len == 0) return;
  final dir = (b - a) / len;
  var t = 0.0;
  while (t < len) {
    canvas.drawLine(a + dir * t, a + dir * math.min(t + dash, len), paint);
    t += dash + gap;
  }
}

class _PricePainter extends CustomPainter {
  final List<Candle> candles;
  final List<LineSeries> overlays;
  final bool volumeOn;
  final int start, visible;
  final int? selected;
  final double axisW;
  final List<Drawing> drawings;
  final List<DrawPt> draftPts;
  final String draftType;
  final int drawColor;
  final String? selectedDrawingId;
  final String tool;
  final bool lockAll;
  final List<double> fibLevels;
  final int ivSec;
  final (double, double)? range;
  _PricePainter(
    this.candles,
    this.overlays,
    this.volumeOn,
    this.start,
    this.visible,
    this.selected,
    this.axisW, {
    this.drawings = const [],
    this.draftPts = const [],
    this.draftType = 'cursor',
    this.drawColor = 0xFFF59E0B,
    this.selectedDrawingId,
    this.tool = 'cursor',
    this.lockAll = false,
    this.fibLevels = const [],
    this.ivSec = 3600,
    this.range,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - axisW;
    if (candles.isEmpty || plotW <= 0) return;
    canvas.clipRect(Offset.zero & size); // رسم‌ها از پنل قیمت بیرون نزنند
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = cBg,
    ); // پس‌زمینه دقیقاً مثل وب
    final cw = plotW / visible;
    double x(int i) => (i - start + 0.5) * cw;

    final r = range ?? _priceRange(candles, overlays, start, visible);
    if (r == null) return;
    final lo = r.$1, hi = r.$2;
    double y(double v) => size.height - (v - lo) / (hi - lo) * size.height;

    final gridPaint = Paint()
      ..color = cGrid
      ..strokeWidth = 1;
    for (var g = 0; g <= 4; g++) {
      final v = lo + (hi - lo) * g / 4;
      canvas.drawLine(Offset(0, y(v)), Offset(plotW, y(v)), gridPaint);
      _text(
        canvas,
        fmtPrice(v),
        Offset(size.width - 4, y(v) - 6),
        cMuted,
        10,
        align: TextAlign.right,
      );
    }

    if (volumeOn) {
      var vmax = 0.0;
      for (
        var i = math.max(0, start);
        i < math.min(candles.length, start + visible);
        i++
      ) {
        vmax = math.max(vmax, candles[i].volume);
      }
      if (vmax > 0) {
        final vh = size.height * 0.15;
        for (
          var i = math.max(0, start);
          i < math.min(candles.length, start + visible);
          i++
        ) {
          final c = candles[i];
          final p = Paint()
            ..color = (c.close >= c.open ? cGreen : cRed).withValues(
              alpha: 0.35,
            );
          final h = c.volume / vmax * vh;
          canvas.drawRect(
            Rect.fromLTWH(x(i) - cw * 0.32, size.height - h, cw * 0.64, h),
            p,
          );
        }
      }
    }

    final bodyW = math.max(1.0, cw * 0.64);
    for (
      var i = math.max(0, start);
      i < math.min(candles.length, start + visible);
      i++
    ) {
      final c = candles[i];
      final up = c.close >= c.open;
      final p = Paint()
        ..color = up ? cGreen : cRed
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x(i), y(c.high)), Offset(x(i), y(c.low)), p);
      final top = y(math.max(c.open, c.close)),
          bot = y(math.min(c.open, c.close));
      canvas.drawRect(
        Rect.fromLTWH(x(i) - bodyW / 2, top, bodyW, math.max(1, bot - top)),
        p,
      );
    }

    for (final s in overlays) {
      final p = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke;
      final path = Path();
      var started = false;
      for (var i = 0; i < s.values.length; i++) {
        final v = s.values[i];
        final xi = x(i + s.shift);
        if (v == null || xi < -cw || xi > plotW + cw) {
          started = false;
          continue;
        }
        if (!started) {
          path.moveTo(xi, y(v));
          started = true;
        } else {
          path.lineTo(xi, y(v));
        }
      }
      canvas.drawPath(path, p);
    }

    _drawDrawings(canvas, plotW, y, cw);

    final last = candles.last;
    final lp = Paint()
      ..color = (last.close >= last.open ? cGreen : cRed).withValues(alpha: 0.7)
      ..strokeWidth = 1;
    _dashedLine(
      canvas,
      Offset(0, y(last.close)),
      Offset(plotW, y(last.close)),
      lp,
    );
    final chip = Rect.fromLTWH(plotW + 1, y(last.close) - 9, axisW - 2, 18);
    canvas.drawRect(
      chip,
      Paint()..color = last.close >= last.open ? cGreen : cRed,
    );
    _text(
      canvas,
      fmtPrice(last.close),
      Offset(size.width - 4, y(last.close) - 6),
      Colors.white,
      10,
      align: TextAlign.right,
    );

    if (selected != null && selected! >= 0 && selected! < candles.length) {
      final p = Paint()
        ..color = cMuted.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x(selected!), 0),
        Offset(x(selected!), size.height),
        p,
      );
    }
    canvas.drawLine(
      Offset(plotW, 0),
      Offset(plotW, size.height),
      Paint()..color = cBorder,
    );
  }

  void _drawDrawings(
    Canvas canvas,
    double plotW,
    double Function(double) y,
    double cw,
  ) {
    if (candles.isEmpty) return;
    double xT(int t) => ((t - candles[0].time) / ivSec - start + 0.5) * cw;
    final list = <Drawing>[...drawings];
    if (draftPts.isNotEmpty && draftType != 'cursor') {
      list.add(
        Drawing(id: '_draft', type: draftType, color: drawColor, pts: draftPts),
      );
    }
    for (final d in list) {
      _drawOne(canvas, d, plotW, y, xT, d.id == selectedDrawingId);
    }
  }

  void _drawOne(
    Canvas canvas,
    Drawing d,
    double plotW,
    double Function(double) y,
    double Function(int) xT,
    bool sel,
  ) {
    final temp = d.id == '_draft';
    final alpha = temp ? 0.7 : 1.0;
    final c = Color(d.color).withValues(alpha: alpha);
    final sw = sel ? 2.6 : 1.6;
    final p = d.pts.map((pt) => Offset(xT(pt.t), y(pt.p))).toList();
    Paint line(Color col, double w) => Paint()
      ..color = col
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    if (d.type == 'hline') {
      _dashedLine(
        canvas,
        Offset(0, p[0].dy),
        Offset(plotW, p[0].dy),
        line(c, sw),
      );
      _text(
        canvas,
        fmtPrice(d.pts[0].p),
        Offset(plotW - 4, p[0].dy - 13),
        c,
        10,
        align: TextAlign.right,
      );
    } else if (p.length < 2) {
      canvas.drawCircle(p[0], 4, Paint()..color = c);
    } else if (d.type == 'trend') {
      canvas.drawLine(p[0], p[1], line(c, sw));
    } else if (d.type == 'fib') {
      final xl = math.min(p[0].dx, p[1].dx);
      _dashedLine(
        canvas,
        p[0],
        p[1],
        line(Color(0xFF6B7280).withValues(alpha: alpha), 1),
      );
      for (var i = 0; i < fibLevels.length; i++) {
        final l = fibLevels[i];
        final price = d.pts[1].p + (d.pts[0].p - d.pts[1].p) * l;
        final yy = y(price);
        final col = Color(fibColors[i % fibColors.length])
            .withValues(alpha: alpha);
        canvas.drawLine(
          Offset(xl, yy),
          Offset(plotW, yy),
          line(col, sel ? 1.6 : 1),
        );
        _text(
          canvas,
          '${_fmtLevel(l)} (${fmtPrice(price)})',
          Offset(plotW - 4, yy - 12),
          col,
          10,
          align: TextAlign.right,
        );
      }
    } else {
      final path = Path()..moveTo(p[0].dx, p[0].dy);
      for (var i = 1; i < p.length; i++) {
        path.lineTo(p[i].dx, p[i].dy);
      }
      canvas.drawPath(path, line(c, sw));
      final labels = drawLabels[d.type] ?? const <String>[];
      for (var i = 0; i < p.length; i++) {
        final pr = d.pts[i].p;
        final prev = i > 0 ? d.pts[i - 1].p : null;
        final next = i < d.pts.length - 1 ? d.pts[i + 1].p : null;
        final isHigh =
            (prev == null || pr >= prev) && (next == null || pr >= next);
        final cy = p[i].dy + (isHigh ? -16 : 16);
        canvas.drawCircle(Offset(p[i].dx, cy), 9, Paint()..color = cBg);
        canvas.drawCircle(
          Offset(p[i].dx, cy),
          9,
          line(c, 1.3)..style = PaintingStyle.stroke,
        );
        if (i < labels.length) {
          _text(
            canvas,
            labels[i],
            Offset(p[i].dx, cy - 5),
            c,
            11,
            align: TextAlign.center,
          );
        }
      }
    }

    if (sel && !temp) {
      final locked = d.locked || lockAll;
      if (locked) {
        _text(canvas, '🔒', Offset(p[0].dx + 8, p[0].dy - 16), c, 11);
      } else if (tool == 'cursor') {
        for (final q in p) {
          canvas.drawCircle(
            q,
            7,
            Paint()..color = Colors.white.withValues(alpha: 0.92),
          );
          canvas.drawCircle(q, 7, line(Color(d.color), 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PricePainter old) => true;
}

class _PanePainter extends CustomPainter {
  final PaneSpec pane;
  final int total, start, visible;
  final int? selected;
  final double axisW;
  _PanePainter(
    this.pane,
    this.total,
    this.start,
    this.visible,
    this.selected,
    this.axisW,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - axisW;
    if (plotW <= 0 || total == 0) return;
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = cBg);
    final cw = plotW / visible;
    double x(int i) => (i - start + 0.5) * cw;

    double lo, hi;
    if (pane.range != null) {
      lo = pane.range!.$1;
      hi = pane.range!.$2;
    } else {
      lo = double.infinity;
      hi = double.negativeInfinity;
      void scan(List<double?> vs) {
        for (
          var i = math.max(0, start);
          i < math.min(vs.length, start + visible);
          i++
        ) {
          final v = vs[i];
          if (v != null && v.isFinite) {
            lo = math.min(lo, v);
            hi = math.max(hi, v);
          }
        }
      }

      for (final s in pane.lines) scan(s.values);
      if (pane.hist != null) scan(pane.hist!);
      if (!lo.isFinite) {
        lo = 0;
        hi = 1;
      }
      if (hi == lo) {
        hi += 1;
        lo -= 1;
      }
      final pad = (hi - lo) * 0.08;
      lo -= pad;
      hi += pad;
    }
    double y(double v) => size.height - (v - lo) / (hi - lo) * size.height;

    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, 0),
      Paint()..color = cBorder,
    );
    final hlPaint = Paint()
      ..color = cMuted.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (final h in pane.hlines) {
      if (h >= lo && h <= hi)
        _dashedLine(canvas, Offset(0, y(h)), Offset(plotW, y(h)), hlPaint);
    }
    // گرید و برچسب‌های محور (مثل نسخه وب)
    final gridPaint = Paint()
      ..color = cGrid
      ..strokeWidth = 1;
    for (var g = 0; g <= 4; g++) {
      final v = lo + (hi - lo) * g / 4;
      canvas.drawLine(Offset(0, y(v)), Offset(plotW, y(v)), gridPaint);
      _text(
        canvas,
        fmtNum(v),
        Offset(size.width - 4, y(v) - 5),
        cMuted,
        9,
        align: TextAlign.right,
      );
    }

    if (pane.hist != null) {
      final zeroY = y(0.0.clamp(lo, hi));
      for (
        var i = math.max(0, start);
        i < math.min(pane.hist!.length, start + visible);
        i++
      ) {
        final v = pane.hist![i];
        if (v == null) continue;
        final p = Paint()
          ..color = (v >= 0 ? cGreen : cRed).withValues(alpha: 0.55);
        canvas.drawRect(
          Rect.fromLTRB(
            x(i) - cw * 0.32,
            math.min(zeroY, y(v)),
            x(i) + cw * 0.32,
            math.max(zeroY, y(v)),
          ),
          p,
        );
      }
    }
    for (final s in pane.lines) {
      final p = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke;
      final path = Path();
      var started = false;
      for (var i = 0; i < s.values.length; i++) {
        final v = s.values[i];
        final xi = x(i + s.shift);
        if (v == null || xi < -cw || xi > plotW + cw) {
          started = false;
          continue;
        }
        if (!started) {
          path.moveTo(xi, y(v));
          started = true;
        } else {
          path.lineTo(xi, y(v));
        }
      }
      canvas.drawPath(path, p);
    }
    // چیپ مقدار همه خط‌ها و خطوط افقی روی محور کناری (مثل نسخه وب)
    final chips = <(double, String, Color)>[];
    for (final s in pane.lines) {
      final v = _lineValue(s.values, selected);
      if (v != null && v.isFinite) chips.add((y(v), fmtNum(v), s.color));
    }
    for (final h in pane.hlines) {
      if (h >= lo && h <= hi) chips.add((y(h), fmtNum(h), cMuted));
    }
    chips.sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 1; i < chips.length; i++) {
      if (chips[i].$1 - chips[i - 1].$1 < 18) {
        chips[i] = (chips[i - 1].$1 + 18, chips[i].$2, chips[i].$3);
      }
    }
    for (final (cy, txt, col) in chips) {
      canvas.drawRect(
        Rect.fromLTWH(plotW + 1, cy - 9, axisW - 2, 18),
        Paint()..color = col,
      );
      _text(
        canvas,
        txt,
        Offset(size.width - 4, cy - 6),
        Colors.white,
        9,
        align: TextAlign.right,
      );
    }
    if (selected != null && selected! >= 0 && selected! < total) {
      final p = Paint()
        ..color = cMuted.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x(selected!), 0),
        Offset(x(selected!), size.height),
        p,
      );
    }
    canvas.drawLine(
      Offset(plotW, 0),
      Offset(plotW, size.height),
      Paint()..color = cBorder,
    );
  }

  @override
  bool shouldRepaint(covariant _PanePainter old) => true;
}

class _TimePainter extends CustomPainter {
  final List<Candle> candles;
  final String iv;
  final int start, visible;
  final double axisW;
  _TimePainter(this.candles, this.iv, this.start, this.visible, this.axisW);

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - axisW;
    if (candles.isEmpty || plotW <= 0) return;
    final cw = plotW / visible;
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, 0),
      Paint()..color = cBorder,
    );
    final step = math.max(1, visible ~/ 6);
    for (
      var i = math.max(0, start);
      i < math.min(candles.length, start + visible);
      i++
    ) {
      if (i % step != 0) continue;
      final xi = (i - start + 0.5) * cw;
      _text(
        canvas,
        fmtAxisTime(candles[i].time, iv),
        Offset(xi, 4),
        cMuted,
        9,
        align: TextAlign.center,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimePainter old) => true;
}
