import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const SaibBankApp());
}

class SaibBankApp extends StatelessWidget {
  const SaibBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAIB Bank',
      debugShowCheckedModeBanner: false, // Removes the debug banner in the corner
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Matches your web font
      ),
      home: const HomePage(),
    );
  }
}