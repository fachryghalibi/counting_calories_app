import 'package:flutter/material.dart';
import 'package:aplikasi_counting_calories/screens/pages/welcome_screen.dart';

void main() {
  runApp(CalorieScannerApp());
}

class CalorieScannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFitnessPal',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
        primaryColor: Color(0xFF1A1A2E),
        colorScheme: ColorScheme.dark(primary: Color(0xFF4A90E2)),
      ),
      home: OpeningScreen(), // Menggunakan OpeningScreen sebagai halaman awal
      debugShowCheckedModeBanner: false,
    );
  }
}