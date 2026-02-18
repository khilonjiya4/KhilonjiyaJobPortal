// lib/presentation/company/notifications/employer_notifications_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerNotificationsPage extends StatefulWidget {
  const EmployerNotificationsPage({Key? key}) : super(key: key);

  @override
  State<EmployerNotificationsPage> createState() =>
      _EmployerNotificationsPageState();
}

class _EmployerNotificationsPageState extends State<EmployerNotificationsPage> {
  final SupabaseClient _db = Supabase.instance.client;

  bool _loading = true;
  bool _busy = false;

  List<Map<String, dynamic>> _items = [];

  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ------------------------------------------------------------
  // LOAD (REAL)
  // ------------------------------------------------------------
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = _requireUser();

      final res = await _db
          .from('notifications')
          .select('id,type,title,body,data,is_read,created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      _items = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      _items = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // MARK ALL READ (REAL + SAFE)
  // ------------------------------------------------------------
  Future<void> _markAllRead() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final user = _requireUser();

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      // Update local instantly (no need reload)
      for (final n in _items) {
        n['is_read'] = true;
      }

      if (mounted) setState(() {});
    } catch (_) {}

    if (!mounted) return;
    setState(() => _busy = false);
  }

  // ------------------------------------------------------------
  // MARK SINGLE READ (REAL + SAFE)
  // ------------------------------------------------------------
  Future<void> _markRead(String id) async {
    final nid = id.trim();
    if (nid.isEmpty) return;

    try {
      final user = _requireUser();

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', nid)
          .eq('user_id', user.id);
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text("Notifications"),
        foregroundColor: _text,
        actions: [
          TextButton(
            onPressed: (_loading || _busy || _items.isEmpty) ? null : _markAllRead,
            child: Text(
              _busy ? "..." : "Mark all read",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: (_loading || _busy || _items.isEmpty)
                    ? const Color(0xFF94A3B8)
                    : _primary,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _tile(_items[i]),
                  ),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 40, color: _muted),
            SizedBox(height: 10),
            Text(
              "No notifications",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: _text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "When something happens, it will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _muted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> n) {
    final id = (n['id'] ?? '').toString();
    final title = (n['title'] ?? 'Notification').toString();
    final body = (n['body'] ?? '').toString();
    final isRead = (n['is_read'] ?? false) == true;
    final createdAt = n['created_at'];

    IconData icon = Icons.notifications_outlined;
    final type = (n['type'] ?? '').toString().toLowerCase();

    if (type.contains('application')) icon = Icons.people_outline;
    if (type.contains('interview')) icon = Icons.calendar_month_outlined;
    if (type.contains('job')) icon = Icons.work_outline;

    return InkWell(
      onTap: () async {
        if (!isRead) await _markRead(id);

        if (!mounted) return;
        setState(() {
          final idx =
              _items.indexWhere((e) => (e['id'] ?? '').toString() == id);
          if (idx != -1) _items[idx]['is_read'] = true;
        });

        // OPTIONAL:
        // Later we will route based on n['data'] (jobId, listingRowId etc.)
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Icon(icon, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                            fontSize: 13.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    _timeAgo(createdAt),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'recent';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recent';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }
}