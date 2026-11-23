// چارت کندلی نیتیو با CustomPainter: پنل قیمت + پنل‌های اندیکاتور هم‌محور، زوم/پن با ژست، کراس‌هیر با لمس طولانی
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';

class LineSeries {
  final List<double?> values;
  final Color color;
  final double width;
  final int shift; // جابه‌جایی رو به جلو (Alligator)
  const LineSeries(this.values, this.color, {this.width = 1.2, this.shift = 0});
}

class PaneSpec {
  final String title;
  final List<LineSeries> lines;
  final List<double?>? hist;
  final (double, double)? range; // بازه ثابت (مثل RSI: 0..100)
  final List<double> hlines;
  const PaneSpec(
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
  const ChartView({
    super.key,
    required this.candles,
    required this.overlays,
    required this.panes,
    required this.volumeOn,
    required this.iv,
    required this.version,
    this.onSelect,
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
  static const double _axisW = 58;

  int get _start => widget.candles.length - _offset - _visible;

  int _indexForX(double x) {
    if (widget.candles.isEmpty) return 0;
    final cw = _plotW / _visible;
    return (_start + (x / cw).floor()).clamp(0, widget.candles.length - 1);
  }

  void _select(int? i) {
    setState(() => _selected = i);
    widget.onSelect?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        _plotW = math.max(50, cons.maxWidth - _axisW);
        return GestureDetector(
          onScaleStart: (_) {
            _startVisible = _visible;
            _panAcc = 0;
          },
          onScaleUpdate: (d) {
            setState(() {
              if (d.scale != 1) {
                _visible = (_startVisible / d.scale).round().clamp(
                  20,
                  math.max(20, widget.candles.length),
                );
              }
              _panAcc += d.focalPointDelta.dx;
              final cw = _plotW / _visible;
              final delta = (_panAcc / cw).round();
              if (delta != 0) {
                _offset = (_offset + delta).clamp(
                  0,
                  math.max(0, widget.candles.length - 20),
                );
                _panAcc -= delta * cw;
              }
            });
          },
          onLongPressStart: (d) => _select(_indexForX(d.localPosition.dx)),
          onLongPressMoveUpdate: (d) => _select(_indexForX(d.localPosition.dx)),
          onTapUp: (d) => _select(_indexForX(d.localPosition.dx)),
          onDoubleTap: () => setState(() {
            _visible = 110;
            _offset = 0;
            _selected = null;
          }),
          child: Column(
            children: [
              Expanded(
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
                  ),
                ),
              ),
              for (final pane in widget.panes)
                SizedBox(
                  height: 92,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PanePainter(
                      pane,
                      widget.candles.length,
                      _start,
                      _visible,
                      _selected,
                      _axisW,
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
  _PricePainter(
    this.candles,
    this.overlays,
    this.volumeOn,
    this.start,
    this.visible,
    this.selected,
    this.axisW,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - axisW;
    if (candles.isEmpty || plotW <= 0) return;
    final cw = plotW / visible;
    double x(int i) => (i - start + 0.5) * cw;

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
        if (v != null) {
          lo = math.min(lo, v);
          hi = math.max(hi, v);
        }
      }
    }
    if (!lo.isFinite) return;
    final pad = (hi - lo) * 0.06 + 1e-9;
    lo -= pad;
    hi += pad;
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
          if (v != null) {
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
    _text(
      canvas,
      fmtNum(hi),
      Offset(size.width - 4, 2),
      cMuted,
      9,
      align: TextAlign.right,
    );
    _text(
      canvas,
      fmtNum(lo),
      Offset(size.width - 4, size.height - 12),
      cMuted,
      9,
      align: TextAlign.right,
    );
    _text(canvas, pane.title, const Offset(6, 3), cMuted, 10);

    if (pane.hist != null) {
      final zeroY = y(0.clamp(lo, hi));
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
