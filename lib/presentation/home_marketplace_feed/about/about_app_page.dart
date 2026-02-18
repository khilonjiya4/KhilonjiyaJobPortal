import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("About"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: KhilonjiyaUI.cardDecoration(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLinks.companyName, style: KhilonjiyaUI.hTitle),
                const SizedBox(height: 8),
                Text(
                  "Khilonjiya is a job marketplace app focused on Assam and nearby regions.",
                  style: KhilonjiyaUI.body,
                ),
                const SizedBox(height: 12),
                Text(
                  "Version: 1.0.0",
                  style: KhilonjiyaUI.sub.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}