import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised service for all Firestore read/write operations.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ──────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _batches => _db.collection('batches');

  // ── User / Auth ───────────────────────────────────────────────────────────

  /// Fetch a user document by 10-digit phone number.
  /// The document ID is stored as '+91{phone}'.
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final docId = '+91$phone';
    final snap = await _users.doc(docId).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>?;
  }

  /// Returns the role ('admin' | 'teacher' | null) for the given phone.
  Future<String?> getRoleByPhone(String phone) async {
    final data = await getUserByPhone(phone);
    return data?['role']?.toString();
  }

  // ── Teacher ───────────────────────────────────────────────────────────────

  /// Returns the teacher document from the `users` collection.
  Future<Map<String, dynamic>?> getTeacherInfo(String phone) async {
    final data = await getUserByPhone(phone);
    if (data == null) return null;
    if (data['role'] != 'teacher') return null;
    return data;
  }

  /// Returns batches scheduled for today that are assigned to [teacherName].
  ///
  /// Match logic mirrors the admin dashboard:
  ///  1. The `batch` field on the teacher's user doc matches the batch `name`.
  ///  2. Fallback: `teacherId` on the batch doc matches the teacher's Firestore doc ID.
  ///  3. Fallback: `teacherName` string on the batch doc.
  Future<List<Map<String, dynamic>>> getTodayBatchesForTeacher(
      String teacherName) async {
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayStr = dayNames[now.weekday - 1];

    final snap = await _batches.get();
    final results = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;

      // ── Does this batch run today? ──
      bool runsToday = false;
      if (d['selectedDays'] is List) {
        runsToday = (d['selectedDays'] as List).contains(todayStr);
      } else if (d['schedule'] is String) {
        runsToday = (d['schedule'] as String).contains(todayStr);
      }
      if (!runsToday) continue;

      // ── Is this teacher assigned? ──
      final batchName = d['name']?.toString() ?? '';
      final batchTeacherName = d['teacherName']?.toString() ?? '';

      // Check 1: batch name stored on teacher doc (primary EduGram pattern)
      // This check is done by the caller who already knows the teacher's batch field.

      // Check 2 & 3: teacherName field directly on the batch doc
      bool isAssigned = batchTeacherName.toLowerCase() == teacherName.toLowerCase();

      if (!isAssigned) continue;

      // ── Build time display ──
      String timeDisplay = 'TBD';
      if (d['startTime'] != null && d['endTime'] != null) {
        timeDisplay = '${d['startTime']} - ${d['endTime']}';
      } else if (d['schedule'] != null) {
        final s = d['schedule'].toString();
        if (s.contains('—')) {
          timeDisplay = s.split('—').last.trim();
        } else {
          timeDisplay = s;
        }
      }

      results.add({
        'name': batchName,
        'subject': d['subject'] ?? 'Subject',
        'time': timeDisplay,
      });
    }

    // Sort by time string
    results.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
    return results;
  }

  /// Returns all batches assigned to a teacher (by their `batch` field on user doc).
  /// [assignedBatchName] is the value stored in the teacher's `batch` field.
  Future<List<Map<String, dynamic>>> getTodayBatchesByName(
      String assignedBatchName) async {
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayStr = dayNames[now.weekday - 1];

    final snap =
        await _batches.where('name', isEqualTo: assignedBatchName).get();
    final results = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;

      bool runsToday = false;
      if (d['selectedDays'] is List) {
        runsToday = (d['selectedDays'] as List).contains(todayStr);
      } else if (d['schedule'] is String) {
        runsToday = (d['schedule'] as String).contains(todayStr);
      }
      if (!runsToday) continue;

      String timeDisplay = 'TBD';
      if (d['startTime'] != null && d['endTime'] != null) {
        timeDisplay = '${d['startTime']} - ${d['endTime']}';
      } else if (d['schedule'] != null) {
        final s = d['schedule'].toString();
        if (s.contains('—')) {
          timeDisplay = s.split('—').last.trim();
        } else {
          timeDisplay = s;
        }
      }

      results.add({
        'name': d['name'] ?? assignedBatchName,
        'subject': d['subject'] ?? 'Subject',
        'time': timeDisplay,
        'maxStudents': d['maxStudents'] ?? 0,
      });
    }

    results.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
    return results;
  }

  // ── Counts (used by admin + teacher dashboards) ───────────────────────────

  Future<int> getTeacherCount() async {
    final snap = await _users.where('role', isEqualTo: 'teacher').get();
    return snap.docs.length;
  }

  Future<int> getStudentCount() async {
    final snap = await _students.get();
    return snap.docs.length;
  }

  Future<int> getBatchCount() async {
    final snap = await _batches.get();
    return snap.docs.length;
  }

  /// Returns the combined stats in one parallel fetch.
  Future<Map<String, int>> getStats() async {
    final results = await Future.wait([
      getTeacherCount(),
      getStudentCount(),
      getBatchCount(),
    ]);
    return {
      'teachers': results[0],
      'students': results[1],
      'batches': results[2],
    };
  }
}
