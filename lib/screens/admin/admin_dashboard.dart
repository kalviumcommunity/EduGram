import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_screen.dart';
import 'add_teacher_screen.dart';
import 'add_student_screen.dart';
import 'add_batch_screen.dart';
import 'teachers_list_screen.dart';
import 'students_list_screen.dart';
import 'batches_list_screen.dart';
import 'admin_profile_screen.dart';
import 'notifications_screen.dart';
import '../../app_colors.dart';

// ── Color aliases pointing to shared constants ──
const _blue = appBlue;
const _blueDark = appBlueDark;
const _blueSoft = appBlueSoft;
const _dark = appDark;
const _darkGrad = appDarkGrad;
const _bg = appBg;
const _darkText = appDarkText;
const _subText = appSubText;
const _cardBg = appCardBg;
const _divider = appDivider;

class AdminDashboard extends StatefulWidget {
  final String phoneNumber;
  const AdminDashboard({super.key, required this.phoneNumber});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _teacherCount = 0;
  int _studentCount = 0;
  int _batchCount = 0;
  bool _isLoading = true;
  int _selectedNav = 0;

  String? _recentTeacher;
  String? _recentStudent;
  List<Map<String, dynamic>> _todayBatches = [];

  // ── Notification badge ──
  int _notifCount = 0;
  final List<StreamSubscription> _notifSubs = [];

  // Track doc IDs we've already seen so we only badge NEW ones
  final Set<String> _seenIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToNotifCount();
  }

  @override
  void dispose() {
    for (final s in _notifSubs) {
      s.cancel();
    }
    super.dispose();
  }

  void _listenToNotifCount() {
    final db = FirebaseFirestore.instance;
    // Listen to teachers
    _notifSubs.add(
      db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snap) => _updateBadge(snap.docs)),
    );
    // Listen to batches
    _notifSubs.add(
      db
          .collection('batches')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snap) => _updateBadge(snap.docs)),
    );
  }

  void _updateBadge(List<QueryDocumentSnapshot> docs) {
    int newCount = 0;
    for (final doc in docs) {
      if (!_seenIds.contains(doc.id)) {
        newCount++;
      }
    }
    if (mounted && newCount > 0) {
      setState(() => _notifCount += newCount);
      for (final doc in docs) {
        _seenIds.add(doc.id);
      }
    }
  }

  void _openNotifications() {
    setState(() => _notifCount = 0);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get(),
        FirebaseFirestore.instance.collection('students').get(),
        FirebaseFirestore.instance.collection('batches').get(),
      ]);
      String? rT, rS;
      if (results[0].docs.isNotEmpty) {
        final d = results[0].docs.last.data();
        rT = d['name']?.toString();
      }
      if (results[1].docs.isNotEmpty) {
        final d = results[1].docs.last.data();
        rS = d['name']?.toString();
      }

      final teachersMap = <String, String>{};
      final teacherByBatchMap = <String, String>{};

      for (final doc in results[0].docs) {
        final tData = doc.data();
        final tName = tData['name']?.toString() ?? 'Unknown Teacher';
        teachersMap[doc.id] = tName;
        
        // Teachers are assigned to batches via the 'batch' string field matching the batch name
        final assignedBatch = tData['batch']?.toString();
        if (assignedBatch != null && assignedBatch.isNotEmpty) {
          teacherByBatchMap[assignedBatch] = tName;
        }
      }

      // Filter today's batches list
      final now = DateTime.now();
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final todayStr = dayNames[now.weekday - 1]; // 1=Mon, 7=Sun
      
      final currentDayBatches = <Map<String, dynamic>>[];
      for (final doc in results[2].docs) {
        final d = doc.data();
        
        // Find if this batch runs today
        bool runsToday = false;
        if (d['selectedDays'] is List) {
          runsToday = (d['selectedDays'] as List).contains(todayStr);
        } else if (d['schedule'] is String) {
          runsToday = (d['schedule'] as String).contains(todayStr);
        }
        
        // If it runs today, add it to the list
        if (runsToday) {
          final batchName = d['name']?.toString() ?? 'Batch';
          final tId = d['teacherId']?.toString() ?? '';
          
          String mappedTeacherName = 'Not Assigned';

          // 1. the primary way teachers are mapped in EduGram is the `batch` field on the Teacher doc matching `batchName`
          if (teacherByBatchMap.containsKey(batchName)) {
            mappedTeacherName = teacherByBatchMap[batchName]!;
          } 
          // 2. Fallback to `teacherId` on the batch document if it exists
          else if (tId.isNotEmpty && teachersMap.containsKey(tId)) {
            mappedTeacherName = teachersMap[tId]!;
          } 
          // 3. Fallback to `teacherName` string directly on the batch document
          else if (d['teacherName'] != null && d['teacherName'].toString().isNotEmpty) {
            mappedTeacherName = d['teacherName'].toString();
          }

          String timeDisplay = 'TBD';
          if (d['startTime'] != null && d['endTime'] != null) {
            timeDisplay = '${d['startTime']} - ${d['endTime']}';
          } else if (d['schedule'] != null) {
            // Extract just the time part if the schedule is like "Mon, Wed — 09:00 - 10:00"
            final s = d['schedule'].toString();
            if (s.contains('—')) {
              timeDisplay = s.split('—').last.trim();
            } else {
              timeDisplay = s;
            }
          }

          currentDayBatches.add({
            'name': batchName,
            'subject': d['subject'] ?? 'Subject',
            'time': timeDisplay,
            'teacherId': tId,
            'teacherName': mappedTeacherName,
          });
        }
      }

      // Sort today's batches by time (simple sort based on string format HH:mm)
      currentDayBatches.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));

      if (mounted) {
        setState(() {
          _teacherCount = results[0].docs.length;
          _studentCount = results[1].docs.length;
          _batchCount = results[2].docs.length;
          _recentTeacher = rT;
          _recentStudent = rS;
          _todayBatches = currentDayBatches;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminDashboard: Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load dashboard data. Pull down to retry.'),
          ),
        );
      }
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _logout() => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );

  Future<void> _navigateTo(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    // refresh dashboard if data was saved
    if (result == true) _loadData();
  }

  Widget _buildHomeBody() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: _blue))
        : SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: _blue,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    Container(height: 1, color: _divider),
                    const SizedBox(height: 24),
                    _sectionLabel('OVERVIEW'),
                    const SizedBox(height: 14),
                    _buildOverviewCards(),
                    const SizedBox(height: 32),
                    _sectionLabel('MAIN ACTIONS'),
                    const SizedBox(height: 16),
                    _buildMainActions(),
                    const SizedBox(height: 32),
                    _sectionLabel("TODAY's BATCHES"),
                    const SizedBox(height: 16),
                    _buildTodaysBatches(),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _currentBody() {
    switch (_selectedNav) {
      case 1:
        return const TeachersListScreen();
      case 2:
        return const StudentsListScreen();
      case 3:
        return const BatchesListScreen();
      case 4:
        return AdminProfileScreen(phoneNumber: widget.phoneNumber);
      default:
        return _buildHomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _currentBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ══════════════════════ TOP BAR ══════════════════════
  Widget _buildTopBar() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: _blue, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'EduTrack Institute',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _darkText,
                letterSpacing: -0.2,
              ),
            ),
          ),
          // ── Bell with badge ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: const Color(0xFFF0F3FA),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _openNotifications,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(Icons.notifications_outlined,
                        color: Color(0xFF5C6780), size: 20),
                  ),
                ),
              ),
              if (_notifCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _notifCount > 99 ? '99+' : '$_notifCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════ SECTION LABEL ══════════════════════
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _subText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ══════════════════════ OVERVIEW CARDS ══════════════════════
  Widget _buildOverviewCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _OverviewCard(
              icon: Icons.person_outline_rounded,
              iconBg: _blueSoft,
              iconColor: _blue,
              count: _teacherCount,
              label: 'TEACHERS',
              trend: '+2 this month',
              trendPositive: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OverviewCard(
              icon: Icons.people_outline_rounded,
              iconBg: const Color(0xFFF0EBF8),
              iconColor: const Color(0xFF7C4DBA),
              count: _studentCount,
              label: 'STUDENTS',
              trend: '+12 new',
              trendPositive: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OverviewCard(
              icon: Icons.layers_outlined,
              iconBg: const Color(0xFFFFF0E0),
              iconColor: const Color(0xFFD97A1A),
              count: _batchCount,
              label: 'BATCHES',
              trend: '6 active',
              trendPositive: false,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ MAIN ACTIONS ══════════════════════
  Widget _buildMainActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Hero Card (Add Student)
          SizedBox(
            height: 110,
            width: double.infinity,
            child: _LargeActionTile(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Add Student',
              gradColors: [_blue, _blueDark],
              onTap: () => _navigateTo(const AddStudentScreen()),
            ),
          ),
          const SizedBox(height: 12),
          // Row 2: Smaller Cards (Add Teacher & Add Batch)
          SizedBox(
            height: 115,
            child: Row(
              children: [
                Expanded(
                  child: _LargeActionTile(
                    icon: Icons.person_add_rounded,
                    label: 'Add Teacher',
                    gradColors: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                    onTap: () => _navigateTo(const AddTeacherScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LargeActionTile(
                    icon: Icons.add_chart_rounded,
                    label: 'Add Batch',
                    gradColors: [_dark, _darkGrad],
                    onTap: () => _navigateTo(const AddBatchScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ TODAY'S BATCHES ══════════════════════
  Widget _buildTodaysBatches() {
    if (_todayBatches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider, width: 1),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.event_available_rounded, size: 40, color: _blueSoft),
                SizedBox(height: 12),
                Text(
                  'No classes scheduled for today',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _subText),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _todayBatches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final batch = _todayBatches[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.layers_rounded, color: Color(0xFFD97A1A)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch['name'],
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _darkText),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              size: 14, color: _subText),
                          const SizedBox(width: 4),
                          Text(
                            batch['subject'],
                            style: const TextStyle(fontSize: 13, color: _subText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 14, color: _subText),
                          const SizedBox(width: 4),
                          Text(
                            batch['teacherName'] ?? 'Not Assigned',
                            style: const TextStyle(fontSize: 13, color: _subText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: _darkText),
                      const SizedBox(width: 6),
                      Text(
                        batch['time'],
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _darkText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════ BOTTOM NAV ══════════════════════
  Widget _buildBottomNav() {
    final tabs = [
      _Tab(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _Tab(Icons.person_rounded, Icons.person_outlined, 'Teachers'),
      _Tab(Icons.people_rounded, Icons.people_outlined, 'Students'),
      _Tab(Icons.calendar_month_rounded, Icons.calendar_month_outlined,
          'Batches'),
      _Tab(Icons.account_circle_rounded, Icons.account_circle_outlined,
          'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final active = i == _selectedNav;
              return InkWell(
                onTap: () {
                  setState(() => _selectedNav = i);
                  if (i == 0) _loadData();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? tabs[i].filled : tabs[i].outline,
                        size: 22,
                        color: active ? _blue : const Color(0xFF6B7A93),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? _blue : const Color(0xFF6B7A93),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
class _Tab {
  final IconData filled, outline;
  final String label;
  _Tab(this.filled, this.outline, this.label);
}

// ─── Overview card (with trend text) ───
class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final int count;
  final String label;
  final String trend;
  final bool trendPositive;

  const _OverviewCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.count,
    required this.label,
    required this.trend,
    required this.trendPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: iconColor, size: 22)),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: _darkText, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w600, color: _subText, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          // Trend text
          Text(
            trend,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: trendPositive ? const Color(0xFF43A047) : _subText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Large gradient action tile ───
class _LargeActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradColors;
  final VoidCallback onTap;
  const _LargeActionTile(
      {required this.icon,
      required this.label,
      required this.gradColors,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradColors[0].withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Icon(icon, color: Colors.white, size: 24)),
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

