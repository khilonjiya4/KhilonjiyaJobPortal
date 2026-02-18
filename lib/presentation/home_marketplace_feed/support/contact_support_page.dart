import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Contact & Support"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            title: "Support",
            body: """
For help, contact:
Email: support@khilonjiya.in (set later)

You can also report issues from inside the app in future updates.
""",
          ),
          _card(
            title: "Business address",
            body: """
Khilonjiya India Private Limited
(You can add full registered address later)
""",
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14.8)),
          const SizedBox(height: 8),
          Text(body.trim(), style: KhilonjiyaUI.body),
        ],
      ),
    );
  }
}