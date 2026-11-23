# 📊 کریپتو لنز — نسخه نیتیو Flutter

اپ اندرویدی نیتیو (بدون WebView/مرورگر) با همان منطق نسخه وب: چارت کندلی، اندیکاتورها، سایدبار لیست ارزها و قیمت‌ها.

## ویژگی‌ها (مرحله ۱)
- چارت کندل با زوم (پینچ)، جابه‌جایی (درگ) و کراس‌هیر (لمس طولانی)؛ دوبار ضربه = ریست نما
- تایم‌فریم‌های 15M تا 1W و کندل هیکن آشی (HA)
- اندیکاتورهای روی قیمت: SMA، EMA، Bollinger، VWAP، Williams Alligator، Volume
- پنل‌ها: RSI، RSI+SMA، MACD، Stochastic، ATR، OBV+SMA، ROC، ADX، CCI، Williams %R، Momentum، MFI
- سایدبار لیست ارزها: قیمت لحظه‌ای، تغییر ۲۴ ساعته، حجم؛ جستجو، مرتب‌سازی و حذف با ✕
- داده مستقیم از Binance (چند هاست جایگزین)؛ یا آدرس پروکسی خودتان (مثل دیپلوی Vercel نسخه وب) در تنظیمات
- بروزرسانی خودکار و ذخیره‌ی تنظیمات روی گوشی

> مرحله‌های بعدی (هنوز نیست): ابزارهای رسم، بک‌تست و اسکریپت کاربر.

## ساخت APK با GitHub Actions
1. این پوشه را در یک ریپوی گیت‌هاب پوش کنید.
2. در تب **Actions** ورک‌فلوی «Build Flutter Android APK» را اجرا کنید (یا روی main پوش کنید).
3. از صفحه‌ی همان اجرا آرتیفکت `cryptolens-flutter-apk` را دانلود و روی گوشی نصب کنید (نصب از منابع ناشناس را فعال کنید).

پوشه‌ی `android/` در CI با `flutter create` ساخته می‌شود و در ریپو نیست. APK از نوع debug است (نصب مستقیم؛ برای Google Play نسخه‌ی release امضاشده لازم است).

## ساختار
```
lib/
├── main.dart               # ورود برنامه و تم
├── models.dart             # Candle / Ticker
├── indicators.dart         # ریاضی اندیکاتورها (پورت از نسخه وب، بدون Flutter)
├── binance.dart            # دریافت داده
├── settings.dart           # تنظیمات و ذخیره‌سازی
├── format.dart             # قالب‌بندی قیمت/زمان
├── chart/chart_widget.dart # چارت نیتیو (CustomPainter)
└── ui/                     # صفحه اصلی، سایدبار، پنل اندیکاتورها
test/indicators_test.dart   # تست مقادیر مرجع (flutter test)
tool/check_indicators.dart  # همان بررسی با Dart خالص: dart tool/check_indicators.dart
```
