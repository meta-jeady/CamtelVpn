import 'package:flutter/material.dart';
import 'views/home_screen.dart';

void main() {
  runApp(const DxsTunnelApp());
}

class DxsTunnelApp extends StatelessWidget {
  const DxsTunnelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DXS Tunnel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF66),
        scaffoldBackgroundColor: const Color(0xFF0D0E15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF66),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161925),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
