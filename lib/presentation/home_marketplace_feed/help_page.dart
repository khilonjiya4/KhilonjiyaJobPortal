import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Help"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: KhilonjiyaUI.r16,
            border: Border.all(color: KhilonjiyaUI.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "World Class Job Portal",
                style: KhilonjiyaUI.hTitle.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "For help, support, or any issues, please contact us.\n\n"
                "Email: support@worldclassjobportal.com\n"
                "Phone: +91 00000 00000",
                style: KhilonjiyaUI.body.copyWith(
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}