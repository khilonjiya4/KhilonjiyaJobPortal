import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/ui/khilonjiya_ui.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = "${info.version} (${info.buildNumber})";
    } catch (_) {
      _version = "";
    }

    if (!mounted) return;
    setState(() {});
  }

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
          _card(
            title: "Company",
            value: "Khilonjiya India Private Limited",
          ),
          _card(
            title: "App",
            value: "Khilonjiya Job Portal",
          ),
          _card(
            title: "Version",
            value: _version.isEmpty ? "—" : _version,
          ),
          const SizedBox(height: 12),
          Text(
            "This app connects job seekers with employers and service providers in Assam and across India.",
            style: KhilonjiyaUI.sub,
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            value,
            style: KhilonjiyaUI.sub.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}