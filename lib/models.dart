// مدل‌های داده (بدون وابستگی به Flutter تا با Dart خالص قابل تست باشند)

class Candle {
  final int time; // ثانیه (UTC)
  final double open, high, low, close, volume;
  const Candle(
    this.time,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
  );

  Candle copyWith({double? open, double? high, double? low, double? close}) =>
      Candle(
        time,
        open ?? this.open,
        high ?? this.high,
        low ?? this.low,
        close ?? this.close,
        volume,
      );
}

class Ticker {
  final String symbol;
  final double price, change24h, volume; // volume = حجم دلاری (quoteVolume)
  const Ticker(this.symbol, this.price, this.change24h, this.volume);
}
