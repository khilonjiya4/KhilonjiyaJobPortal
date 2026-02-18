// File: lib/core/ui/url_helper.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static Future<void> openUrl(BuildContext context, String url) async {
    final u = url.trim();

    if (u.isEmpty) {
      _toast(context, "Link not available yet");
      return;
    }

    final uri = Uri.tryParse(u);
    if (uri == null) {
      _toast(context, "Invalid link");
      return;
    }

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok) _toast(context, "Unable to open link");
    } catch (_) {
      _toast(context, "Unable to open link");
    }
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}