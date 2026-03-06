import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _blue = Color(0xFF2196F3);
const _blueSoft = Color(0xFFE8F1FD);
const _darkText = Color(0xFF1C2233);
const _subText = Color(0xFF8C96A8);
const _divider = Color(0xFFECEFF5);
const _cardBg = Colors.white;
const _bg = Color(0xFFF0F3FA);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // We merge three streams manually by combining their snapshots
  List<_NotificationItem> _notifications = [];
  bool _isLoading = true;

  // Store latest snapshots from each collection
  List<QueryDocumentSnapshot> _teacherDocs = [];
  List<QueryDocumentSnapshot> _studentDocs = [];
  List<QueryDocumentSnapshot> _batchDocs = [];

  late List<Stream<QuerySnapshot>> _streams;

  @override
  void initState() {
    super.initState();
    _listenToAll();
  }

  void _listenToAll() {
    // Teacher stream
    _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _teacherDocs = snap.docs;
      _rebuild();
    });

    // Student stream
    _db
        .collection('students')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _studentDocs = snap.docs;
      _rebuild();
    });

    // Batch stream
    _db
        .collection('batches')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _batchDocs = snap.docs;
      _rebuild();
    });
  }

  void _rebuild() {
    final items = <_NotificationItem>[];

    for (final doc in _teacherDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final name = d['name']?.toString() ?? 'Unknown';
      final ts = d['createdAt'] as Timestamp?;
      items.add(_NotificationItem(
        icon: Icons.person_add_rounded,
        iconColor: const Color(0xFF1565C0),
        iconBg: const Color(0xFFE3F2FD),
        title: 'New Teacher Added',
        message: '$name was added as a teacher.',
        time: ts?.toDate(),
        type: 'teacher',
      ));
    }

    for (final doc in _studentDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final name = d['name']?.toString() ?? 'Unknown';
      final grade = d['grade']?.toString();
      final ts = d['createdAt'] as Timestamp?;
      items.add(_NotificationItem(
        icon: Icons.school_rounded,
        iconColor: const Color(0xFF7C4DBA),
        iconBg: const Color(0xFFF0EBF8),
        title: 'New Student Enrolled',
        message: '$name${grade != null ? ' (Grade $grade)' : ''} was added.',
        time: ts?.toDate(),
        type: 'student',
      ));
    }

    for (final doc in _batchDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final name = d['name']?.toString() ?? 'Unknown';
      final subject = d['subject']?.toString() ?? '';
      final ts = d['createdAt'] as Timestamp?;
      items.add(_NotificationItem(
        icon: Icons.layers_rounded,
        iconColor: const Color(0xFFD97A1A),
        iconBg: const Color(0xFFFFF0E0),
        title: 'New Batch Created',
        message: '$name${subject.isNotEmpty ? ' — $subject' : ''} was created.',
        time: ts?.toDate(),
        type: 'batch',
      ));
    }

    // Sort by time, newest first
    items.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });

    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: _cardBg,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _blueSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: _blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _blueSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_notifications.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: _divider),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _blue))
                  : _notifications.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _notifications.length,
                          itemBuilder: (_, i) =>
                              _buildNotificationCard(_notifications[i], i),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: _blueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_rounded,
                color: _blue, size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _darkText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Activity will appear here when\nteachers, students, or batches are added.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _subText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
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
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _darkText,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(item.time),
                        style:
                            const TextStyle(fontSize: 11, color: _subText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                        fontSize: 13, color: _subText, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final DateTime? time;
  final String type;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.type,
    this.time,
  });
}
