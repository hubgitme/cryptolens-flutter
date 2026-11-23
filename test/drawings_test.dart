import 'package:flutter_test/flutter_test.dart';
import 'package:cryptolens_app/drawings.dart';

void main() {
  test('drawing json roundtrip', () {
    final d = Drawing(
      id: 'x1',
      type: 'ewi',
      color: 0xFF3B82F6,
      locked: true,
      pts: [DrawPt(1000, 10.5), DrawPt(2000, 12.25)],
    );
    final back = Drawing.fromJson(d.toJson())!;
    expect(back.id, 'x1');
    expect(back.type, 'ewi');
    expect(back.color, 0xFF3B82F6);
    expect(back.locked, true);
    expect(back.pts.length, 2);
    expect(back.pts[1].p, 12.25);
  });

  test('sanitize drops bad types and short point lists', () {
    final raw = {
      'BTCUSDT': [
        {
          'type': 'trend',
          'pts': [
            {'t': 1, 'p': 2},
            {'t': 3, 'p': 4},
          ],
        },
        {
          'type': 'nope',
          'pts': [
            {'t': 1, 'p': 2},
            {'t': 3, 'p': 4},
          ],
        },
        {
          'type': 'fib',
          'pts': [
            {'t': 1, 'p': 2},
          ],
        },
        {
          'type': 'hline',
          'pts': [
            {'t': 1, 'p': 2},
          ],
        },
      ],
      'bad symbol!': [
        {
          'type': 'trend',
          'pts': [
            {'t': 1, 'p': 2},
            {'t': 3, 'p': 4},
          ],
        },
      ],
    };
    final out = sanitizeDrawings(raw);
    expect(out.keys, ['BTCUSDT']);
    expect(out['BTCUSDT']!.length, 2);
    expect(out['BTCUSDT']![0].color, 0xFFF59E0B); // پیش‌فرض
  });

  test('points capped at type count', () {
    final d = Drawing.fromJson({
      'type': 'trend',
      'pts': [
        {'t': 1, 'p': 1},
        {'t': 2, 'p': 2},
        {'t': 3, 'p': 3},
      ],
    })!;
    expect(d.pts.length, 2);
  });
}
