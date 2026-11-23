// قالب‌بندی عدد و زمان برای نمایش
import 'indicators.dart';

String fmtPrice(double? v) {
  if (v == null || !v.isFinite) return '—';
  final p = calcPricePrecision(v);
  final fixed = v.toStringAsFixed(p);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
}

String fmtCompact(double? v) {
  if (v == null || !v.isFinite) return '—';
  final a = v.abs();
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(2);
}

String fmtNum(double? v) => v == null || !v.isFinite
    ? '—'
    : (v.abs() < 1 ? v.toStringAsPrecision(4) : v.toStringAsFixed(2));

String fmtAxisTime(int timeSec, String iv) {
  final d = DateTime.fromMillisecondsSinceEpoch(timeSec * 1000);
  String p2(int n) => n.toString().padLeft(2, '0');
  if (iv == '1d' || iv == '1w') return '${p2(d.month)}/${p2(d.day)}';
  return '${p2(d.hour)}:${p2(d.minute)}';
}

String fmtClock(DateTime d) {
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${p2(d.hour)}:${p2(d.minute)}:${p2(d.second)}';
}
