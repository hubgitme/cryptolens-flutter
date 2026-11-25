import 'package:flutter_test/flutter_test.dart';
import 'package:cryptolens_app/drawings.dart';

void main() {
  test('long/short need 3 points', () {
    expect(drawPointCount['long'], 3);
    expect(drawPointCount['short'], 3);
    expect(drawHints['long'], isNotNull);
    expect(drawHints['short'], isNotNull);
  });

  test('long position json roundtrip', () {
    final d = Drawing(
      id: 'p1',
      type: 'long',
      color: 0xFF2962FF,
      pts: [DrawPt(1000, 10.0), DrawPt(2000, 11.5), DrawPt(3000, 9.6)],
    );
    final back = Drawing.fromJson(d.toJson())!;
    expect(back.type, 'long');
    expect(back.pts.length, 3);
    expect(back.pts[1].p, 11.5);
    // پوزیشن ناقص (۲ نقطه) رد می‌شود
    final bad = Drawing.fromJson({
      'id': 'p2',
      'type': 'short',
      'color': 0xFF2962FF,
      'pts': [
        {'t': 1000, 'p': 10.0},
        {'t': 2000, 'p': 9.0},
      ],
    });
    expect(bad, isNull);
  });
}
