import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const bg   = Color(0xFF0F1020);
  static const card = Color(0xFF17182C);
  static const text = Color(0xFFF8F8FC);
  static const sub  = Color(0xB3F8F8FC);
  static const line = Color(0x14FFFFFF);
  static const pink = Color(0xFFFF5C8A);

  static ThemeData material3() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: pink, brightness: Brightness.dark),
      cardColor: card,
    );
    return base.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme)
          .apply(bodyColor: text, displayColor: text),
    );
  }
}
