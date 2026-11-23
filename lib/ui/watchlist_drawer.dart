// کشوی لیست ارزها: قیمت لحظه‌ای، تغییر ۲۴ ساعته، حجم؛ جستجو، مرتب‌سازی و حذف با ✕
import 'dart:async';

import 'package:flutter/material.dart';

import '../binance.dart';
import '../format.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';

class WatchlistDrawer extends StatefulWidget {
  final AppSettings settings;
  final void Function(String symbol) onPick;
  final VoidCallback onChanged; // بعد از حذف/بازنشانی برای ذخیره تنظیمات
  const WatchlistDrawer({
    super.key,
    required this.settings,
    required this.onPick,
    required this.onChanged,
  });

  @override
  State<WatchlistDrawer> createState() => _WatchlistDrawerState();
}

class _WatchlistDrawerState extends State<WatchlistDrawer> {
  List<Ticker> _rows = [];
  String _query = '';
  String? _error;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    final r = widget.settings.refresh;
    if (r > 0) _timer = Timer.periodic(Duration(seconds: r), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_busy) return;
    _busy = true;
    try {
      final rows = await fetchTickers(
        widget.settings.watchlistSymbols,
        customBase: widget.settings.apiBase,
      );
      if (mounted)
        setState(() {
          _rows = rows;
          _error = null;
        });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _busy = false;
    }
  }

  List<Ticker> get _view {
    var rows = _rows
        .where((r) => r.symbol.contains(_query.trim().toUpperCase()))
        .toList();
    if (widget.settings.watchlistSort == 'change') {
      rows.sort((a, b) => b.change24h.compareTo(a.change24h));
    } else if (widget.settings.watchlistSort == 'volume') {
      rows.sort((a, b) => b.volume.compareTo(a.volume));
    }
    return rows;
  }

  void _remove(String sym) {
    final s = widget.settings;
    if (!s.watchlistHidden.contains(sym)) s.watchlistHidden.add(sym);
    s.savedSymbols.remove(sym);
    setState(() => _rows.removeWhere((r) => r.symbol == sym));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Drawer(
      backgroundColor: cSurface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Text(
                    'لیست ارزها',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.restart_alt, color: cMuted),
                    tooltip: 'بازنشانی لیست (برگرداندن حذف‌شده‌ها)',
                    onPressed: () {
                      s.watchlistHidden.clear();
                      widget.onChanged();
                      _fetch();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'جستجوی ارز…',
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: s.watchlistSort,
                    dropdownColor: cSurface,
                    items: [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('پیش‌فرض'),
                      ),
                      DropdownMenuItem(
                        value: 'change',
                        child: Text('بیشترین رشد'),
                      ),
                      DropdownMenuItem(
                        value: 'volume',
                        child: Text('بیشترین حجم'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        s.watchlistSort = v;
                        widget.onChanged();
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '❌ $_error',
                  style: TextStyle(color: cRed, fontSize: 12),
                ),
              ),
            Expanded(
              child: _rows.isEmpty && _error == null
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _view.length,
                      itemBuilder: (context, i) {
                        final r = _view[i];
                        final up = r.change24h >= 0;
                        final saved = s.savedSymbols.contains(r.symbol);
                        return ListTile(
                          dense: true,
                          selected: r.symbol == s.symbol,
                          selectedTileColor: cAccent.withValues(alpha: 0.15),
                          leading: IconButton(
                            icon: Icon(Icons.close, size: 16, color: cMuted),
                            tooltip: 'حذف از لیست',
                            onPressed: () => _remove(r.symbol),
                          ),
                          title: Text(
                            '${r.symbol}${saved ? ' ⭐' : ''}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          subtitle: Text(
                            'حجم ${fmtCompact(r.volume)}',
                            style: TextStyle(color: cMuted, fontSize: 11),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fmtPrice(r.price),
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: cText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${up ? '▲' : '▼'}${r.change24h.abs().toStringAsFixed(2)}%',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: up ? cGreen : cRed,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onPick(r.symbol);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
