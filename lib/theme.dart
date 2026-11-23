// رنگ‌های تم تیره (هم‌خانواده با نسخه وب)
import 'package:flutter/material.dart';

const cBg = Color(0xFF0B0E17);
const cSurface = Color(0xFF131722);
const cBorder = Color(0xFF2A2E39);
const cText = Color(0xFFD1D4DC);
const cMuted = Color(0xFF787B86);
const cAccent = Color(0xFF2962FF);
const cGreen = Color(0xFF26A69A);
const cRed = Color(0xFFEF5350);
const cGrid = Color(0xFF1E222D);

// پالت رنگ برای خطوط، اندیکاتورها و رسم‌ها
const kPalette = [
  Color(0xFFF59E0B),
  Color(0xFF3B82F6),
  Color(0xFFA855F7),
  Color(0xFF14B8A6),
  Color(0xFFEF5350),
  Color(0xFF26A69A),
  Color(0xFFFF6D00),
  Color(0xFF2962FF),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
  Color(0xFFFFFFFF),
  Color(0xFF9CA3AF),
  Color(0xFF06B6D4),
  Color(0xFFEAB308),
  Color(0xFF6366F1),
  Color(0xFFF97316),
];

// دیالوگ انتخاب رنگ از پالت
Future<Color?> showColorPalette(BuildContext context, Color current) {
  return showDialog<Color>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cSurface,
      title: Text(
        'انتخاب رنگ',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final c in kPalette)
            GestureDetector(
              onTap: () => Navigator.pop(ctx, c),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == current ? Colors.white : cBorder,
                    width: c == current ? 2.5 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
