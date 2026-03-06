import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';

// ── Design tokens (matches admin palette) ──────────────────────────────────
const _tBlue = Color(0xFF2196F3);
const _tBlueDark = Color(0xFF1565C0);
const _tBlueSoft = Color(0xFFE8F1FD);
const _tGreen = Color(0xFF43A047);
const _tGreenSoft = Color(0xFFE8F5E9);
const _tOrange = Color(0xFFD97A1A);
const _tOrangeSoft = Color(0xFFFFF0E0);
const _tPurple = Color(0xFF7C4DBA);
const _tPurpleSoft = Color(0xFFF0EBF8);
const _tBg = Color(0xFFF0F3FA);
const _tDarkText = Color(0xFF1C2233);
const _tSubText = Color(0xFF8C96A8);
const _tDivider = Color(0xFFECEFF5);

class TeacherDashboard extends StatefulWidget {
  final String phoneNumber; // 10-digit (without country code)

  const TeacherDashboard({super.key, required this.phoneNumber});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _service = FirestoreService();

  bool _isLoading = true;
  String _teacherName = '';
  String _assignedBatch = '';
  int _studentCount = 0;
  int _batchCount = 0;
  List<Map<String, dynamic>> _todayBatches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // 1. Fetch teacher info
      final info = await _service.getTeacherInfo(widget.phoneNumber);
      final name = info?['name']?.toString() ?? 'Teacher';
      final batch = info?['batch']?.toString() ?? '';

      // 2. Fetch today's batches — by batch name assigned to teacher
      List<Map<String, dynamic>> todayBatches = [];
      if (batch.isNotEmpty) {
        todayBatches = await _service.getTodayBatchesByName(batch);
      }

      // 3. Aggregate counts
      final studentCount = await _service.getStudentCount();
      final batchCount = await _service.getBatchCount();

      if (mounted) {
        setState(() {
          _teacherName = name;
          _assignedBatch = batch;
          _todayBatches = todayBatches;
          _studentCount = studentCount;
          _batchCount = batchCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dayLabel() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _tBlue))
          : SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: _tBlue,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildStatsRow(),
                      const SizedBox(height: 28),
                      _buildTodaySection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Header card ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_tBlue, _tBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo + sign out
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'EduGram',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _signOut,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.logout_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Greeting
          Text(
            '${_greeting()},',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _teacherName.isNotEmpty ? _teacherName : 'Teacher',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Text(
                _dayLabel(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (_assignedBatch.isNotEmpty) ...[
                const SizedBox(width: 14),
                const Icon(Icons.layers_rounded,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text(
                  _assignedBatch,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats strip ──────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.people_outline_rounded,
              iconBg: _tPurpleSoft,
              iconColor: _tPurple,
              value: '$_studentCount',
              label: 'Students',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.layers_outlined,
              iconBg: _tOrangeSoft,
              iconColor: _tOrange,
              value: '$_batchCount',
              label: 'Batches',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.today_rounded,
              iconBg: _tGreenSoft,
              iconColor: _tGreen,
              value: '${_todayBatches.length}',
              label: 'Today',
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's schedule section ─────────────────────────────────────────────
  Widget _buildTodaySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S SCHEDULE",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _tSubText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          if (_todayBatches.isEmpty)
            _buildNoClassCard()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayBatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildBatchCard(_todayBatches[i], i),
            ),
        ],
      ),
    );
  }

  Widget _buildNoClassCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tDivider),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.event_available_rounded, size: 44, color: _tBlueSoft),
            SizedBox(height: 12),
            Text(
              'No classes scheduled for today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _tSubText,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Enjoy your free day!',
              style: TextStyle(fontSize: 12, color: _tSubText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _tDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _tBlueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child:
                      Icon(Icons.layers_rounded, color: _tBlue, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch['name']?.toString() ?? '—',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _tDarkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            size: 13, color: _tSubText),
                        const SizedBox(width: 4),
                        Text(
                          batch['subject']?.toString() ?? '—',
                          style: const TextStyle(
                              fontSize: 13, color: _tSubText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Time badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _tBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: _tDarkText),
                    const SizedBox(width: 5),
                    Text(
                      batch['time']?.toString() ?? 'TBD',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _tDarkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable stat card ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: iconColor, size: 21)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _tDarkText,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _tSubText,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
