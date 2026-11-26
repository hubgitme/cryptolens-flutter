// تست‌های پشتیبان — کدک خالص (بدون Flutter)
import 'package:cryptolens_app/backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const settingsJson =
      '{"symbol":"BTCUSDT","iv":"4h","indicators":{"rsi":{"on":true}}}';
  const drawingsJson = '{"BTCUSDT":[]}';
  const alertsJson =
      '[{"id":"1","symbol":"BTCUSDT","kind":"priceAbove","level":58000}]';

  Map<String, String> sample() => {
    'ta_settings_v1': settingsJson,
    'ta_drawings_v1': drawingsJson,
    'ta_alerts_v1': alertsJson,
  };

  test('backup roundtrip keeps the stored values byte-identical', () {
    final out = parseBackupFile(buildBackupFile(sample()));
    expect(out, sample());
  });

  test('partial backup (only settings) parses fine', () {
    final out = parseBackupFile(
      buildBackupFile({'ta_settings_v1': settingsJson}),
    );
    expect(out.length, 1);
    expect(out['ta_settings_v1'], settingsJson);
  });

  test('unknown keys in the file are ignored', () {
    final text = buildBackupFile(sample());
    final withExtra = text.replaceFirst(
      '"data":{',
      '"data":{"ta_future_key":{},"extra":1,',
    );
    final out = parseBackupFile(withExtra);
    expect(out, sample());
  });

  test('rejects non-json and wrong-app files', () {
    expect(() => parseBackupFile('hello'), throwsFormatException);
    expect(
      () => parseBackupFile('{"app":"other","version":1,"data":{}}'),
      throwsFormatException,
    );
    expect(
      () => parseBackupFile('{"app":"cryptolens","version":2,"data":{}}'),
      throwsFormatException,
    );
    expect(
      () => parseBackupFile('{"app":"cryptolens","version":1}'),
      throwsFormatException,
    );
    expect(
      () => parseBackupFile('{"app":"cryptolens","version":1,"data":{}}'),
      throwsFormatException,
    );
  });

  test('rejects a broken alerts section', () {
    expect(
      () => parseBackupFile(
        '{"app":"cryptolens","version":1,"data":{"ta_alerts_v1":{}}}',
      ),
      throwsFormatException,
    );
    expect(
      () => parseBackupFile(
        '{"app":"cryptolens","version":1,"data":{"ta_settings_v1":[]}}',
      ),
      throwsFormatException,
    );
  });
}
