import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Language"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: KhilonjiyaUI.cardDecoration(radius: 18),
          child: Text(
            "Multi-language support will be added later.\n\nCurrent language: English",
            style: KhilonjiyaUI.body,
          ),
        ),
      ),
    );
  }
}