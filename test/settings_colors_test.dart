import 'package:flutter_test/flutter_test.dart';
import 'package:cryptolens_app/settings.dart';

void main() {
  test('lineColors json roundtrip', () {
    final cfg = IndCfg(
      true,
      {'period': 9, 'sma': 14},
      lineColors: [0xFFA855F7, 0xFFFF6D00],
    );
    final back = IndCfg.fromJson(cfg.toJson(), false, {'period': 9, 'sma': 14});
    expect(back.lineColors, [0xFFA855F7, 0xFFFF6D00]);
    expect(back.p('sma', 0), 14);
  });

  test('rocma defaults exist', () {
    final s = AppSettings();
    expect(s.indicators.containsKey('rocma'), true);
    expect(s.indicators['rocma']!.p('period', 0), 9);
    expect(s.indicators['rocma']!.p('sma', 0), 14);
    expect(s.paneOrder.contains('rocma'), true);
    // تنظیمات قدیمی بدون rocma باید آن را با پیش‌فرض اضافه کند
    final old = AppSettings.fromJson({
      'paneOrder': ['rsi', 'macd'],
    });
    expect(old.indicators.containsKey('rocma'), true);
    expect(old.paneOrder.contains('rocma'), true);
  });
}
