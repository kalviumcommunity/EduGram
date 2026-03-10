import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _blue = Color(0xFF2196F3);
const _blueSoft = Color(0xFFE8F1FD);
const _bg = Color(0xFFF0F3FA);
const _darkText = Color(0xFF1C2233);
const _subText = Color(0xFF8C96A8);
const _divider = Color(0xFFECEFF5);
const _cardBg = Colors.white;

// SharedPreferences keys
const _kPush = 'notif_push';
const _kEmail = 'notif_email';
const _kNewReg = 'notif_new_reg';
const _kUpdates = 'notif_updates';
const _kPromo = 'notif_promo';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Settings toggles ──
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _newRegistrations = true;
  bool _appUpdates = true;
  bool _promotionalOffers = false;
  bool _prefsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrefs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool(_kPush) ?? true;
      _emailAlerts = prefs.getBool(_kEmail) ?? false;
      _newRegistrations = prefs.getBool(_kNewReg) ?? true;
      _appUpdates = prefs.getBool(_kUpdates) ?? true;
      _promotionalOffers = prefs.getBool(_kPromo) ?? false;
      _prefsLoading = false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _toggle(String key, bool val, void Function(bool) setter) {
    setState(() => setter(val));
    _savePref(key, val);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _darkText),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _darkText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _blue,
          indicatorWeight: 2.5,
          labelColor: _blue,
          unselectedLabelColor: _subText,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // ══════════════════════ ACTIVITY TAB ══════════════════════
  Widget _buildActivityTab() {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<List<_NotifItem>>(
      future: _fetchActivity(db),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _blue));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _subText, size: 40),
                const SizedBox(height: 12),
                Text('Failed to load notifications',
                    style: TextStyle(color: _subText)),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: _blue, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No activity yet',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _darkText),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New students, teachers & batches\nwill appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _subText),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: _blue,
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _NotifCard(item: items[i]),
          ),
        );
      },
    );
  }

  Future<List<_NotifItem>> _fetchActivity(FirebaseFirestore db) async {
    final items = <_NotifItem>[];

    // Teachers
    try {
      final snap = await db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        items.add(_NotifItem(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: const Color(0xFF7C4DBA),
          iconBg: const Color(0xFFF0EBF8),
          title: 'New Teacher Added',
          subtitle: d['name']?.toString() ?? 'Unknown',
          timestamp: d['createdAt'] as Timestamp?,
        ));
      }
    } catch (_) {}

    // Students
    try {
      final snap = await db
          .collection('students')
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        items.add(_NotifItem(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF43A047),
          iconBg: const Color(0xFFE8F5E9),
          title: 'New Student Registered',
          subtitle: d['name']?.toString() ?? 'Unknown',
          timestamp: d['createdAt'] as Timestamp?,
        ));
      }
    } catch (_) {}

    // Batches
    try {
      final snap = await db
          .collection('batches')
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        items.add(_NotifItem(
          icon: Icons.layers_rounded,
          iconColor: const Color(0xFFD97A1A),
          iconBg: const Color(0xFFFFF0E0),
          title: 'New Batch Created',
          subtitle: d['name']?.toString() ?? 'Unknown',
          timestamp: d['createdAt'] as Timestamp?,
        ));
      }
    } catch (_) {}

    // Sort by newest first
    items.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });

    return items;
  }


  // ══════════════════════ SETTINGS TAB ══════════════════════
  Widget _buildSettingsTab() {
    if (_prefsLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'General',
            children: [
              _buildToggleItem(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFF43A047),
                iconBg: const Color(0xFFE8F5E9),
                title: 'Push Notifications',
                subtitle: 'Receive alerts on your device',
                value: _pushNotifications,
                onChanged: (val) =>
                    _toggle(_kPush, val, (v) => _pushNotifications = v),
                isTop: true,
              ),
              _buildToggleItem(
                icon: Icons.email_rounded,
                iconColor: const Color(0xFFD97A1A),
                iconBg: const Color(0xFFFFF0E0),
                title: 'Email Alerts',
                subtitle: 'Receive updates via email',
                value: _emailAlerts,
                onChanged: (val) =>
                    _toggle(_kEmail, val, (v) => _emailAlerts = v),
                isBottom: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'App Activity',
            children: [
              _buildToggleItem(
                icon: Icons.person_add_alt_1_rounded,
                iconColor: const Color(0xFF7C4DBA),
                iconBg: const Color(0xFFF0EBF8),
                title: 'New Registrations',
                subtitle: 'When new students or teachers join',
                value: _newRegistrations,
                onChanged: (val) =>
                    _toggle(_kNewReg, val, (v) => _newRegistrations = v),
                isTop: true,
              ),
              _buildToggleItem(
                icon: Icons.system_update_rounded,
                iconColor: _blue,
                iconBg: _blueSoft,
                title: 'System Updates',
                subtitle: 'Important changes to the dashboard',
                value: _appUpdates,
                onChanged: (val) =>
                    _toggle(_kUpdates, val, (v) => _appUpdates = v),
              ),
              _buildToggleItem(
                icon: Icons.local_offer_rounded,
                iconColor: const Color(0xFFE53935),
                iconBg: const Color(0xFFFFEBEE),
                title: 'Promotional Offers',
                subtitle: 'News about upcoming features',
                value: _promotionalOffers,
                onChanged: (val) =>
                    _toggle(_kPromo, val, (v) => _promotionalOffers = v),
                isBottom: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _subText,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _divider, width: 1),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isTop ? 14 : 0),
              bottom: Radius.circular(isBottom ? 14 : 0),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return _blue;
                      return const Color(0xFFCBD5E1);
                    }),
                    trackOutlineColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isBottom)
          const Padding(
            padding: EdgeInsets.only(left: 68),
            child: Divider(height: 1, color: _divider),
          ),
      ],
    );
  }
}

// ── Data model ──
class _NotifItem {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final Timestamp? timestamp;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.timestamp,
  });
}

// ── Notification card widget ──
class _NotifCard extends StatelessWidget {
  final _NotifItem item;
  const _NotifCard({required this.item});

  String _timeAgo() {
    if (item.timestamp == null) return '';
    final diff = DateTime.now().difference(item.timestamp!.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final dt = item.timestamp!.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x07000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 13, color: _subText),
                ),
              ],
            ),
          ),
          if (item.timestamp != null)
            Text(
              _timeAgo(),
              style: const TextStyle(fontSize: 11, color: _subText),
            ),
        ],
      ),
    );
  }
}
