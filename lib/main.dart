import 'package:flutter/material.dart';

import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyan,
      ),
      home: const HomeScreen(),
    );
  }
}
