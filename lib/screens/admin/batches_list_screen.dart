import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_batch_screen.dart';

// ── Same colors as dashboard ──
const _blue = Color(0xFF2196F3);
const _blueSoft = Color(0xFFE8F1FD);
const _bg = Color(0xFFF0F3FA);
const _darkText = Color(0xFF1C2233);
const _subText = Color(0xFF8C96A8);
const _divider = Color(0xFFECEFF5);
const _cardBg = Colors.white;
const _orange = Color(0xFFD97A1A);
const _orangeSoft = Color(0xFFFFF0E0);
const _green = Color(0xFF43A047);
const _greenSoft = Color(0xFFE8F5E9);

class BatchesListScreen extends StatefulWidget {
  const BatchesListScreen({super.key});

  @override
  State<BatchesListScreen> createState() => _BatchesListScreenState();
}

class _BatchesListScreenState extends State<BatchesListScreen> {
  final _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _allBatches = [];
  List<QueryDocumentSnapshot> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
    _searchController.addListener(_filterBatches);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('batches')
          .get();
      final docs = snap.docs;
      docs.sort((a, b) {
        final aT = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bT = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bT.compareTo(aT);
      });
      if (mounted) {
        setState(() {
          _allBatches = docs;
          _filterBatches();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterBatches() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_allBatches);
      } else {
        _filtered = _allBatches.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final subject = (data['subject'] ?? '').toString().toLowerCase();
          return name.contains(q) || subject.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _deleteBatch(QueryDocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Batch',
            style: TextStyle(fontWeight: FontWeight.bold, color: _darkText)),
        content: Text(
            'Are you sure you want to delete "${(doc.data() as Map)['name'] ?? 'this batch'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await doc.reference.delete();
      _showMsg('Batch deleted');
      _loadBatches();
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBatchScreen()),
    );
    if (result == true) _loadBatches();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _orange,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_chart_rounded, size: 20),
        label: const Text('Add Batch',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: _cardBg,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _orangeSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.layers_rounded,
                            color: _orange, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Batches',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _orangeSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_allBatches.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Search bar ──
                  Container(
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _divider, width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: _darkText),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: Icon(Icons.search_rounded,
                              color: _subText, size: 20),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        hintText: 'Search batches by name or subject...',
                        hintStyle: TextStyle(
                            color: _subText.withOpacity(0.6), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () => _searchController.clear(),
                                icon: const Icon(Icons.clear_rounded,
                                    color: _subText, size: 18),
                              )
                            : null,
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
                      child: CircularProgressIndicator(color: _orange))
                  : _allBatches.isEmpty
                      ? _buildEmptyState()
                      : _filtered.isEmpty
                          ? _buildNoResults()
                          : RefreshIndicator(
                              color: _orange,
                              onRefresh: _loadBatches,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 16, 16, 100),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildBatchCard(_filtered[i], i),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: _orangeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.layers_clear_rounded,
                  color: _orange, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Batches Yet',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to create your first batch.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _subText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                color: _subText.withOpacity(0.4), size: 56),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _darkText),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different search term.',
              style: TextStyle(fontSize: 13, color: _subText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString() ?? 'Unnamed Batch';
    final subject = data['subject']?.toString() ?? '';
    final schedule = data['schedule']?.toString() ?? '';
    final maxStudents = data['maxStudents'];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onLongPress: () => _deleteBatch(doc),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — name + status badge
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _orangeSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.layers_rounded,
                            color: _orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _darkText,
                              ),
                            ),
                            if (subject.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subject,
                                style: const TextStyle(
                                    fontSize: 12, color: _subText),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _greenSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      InkWell(
                        onTap: () => _deleteBatch(doc),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFE53935), size: 18),
                        ),
                      ),
                    ],
                  ),

                  // Details row
                  if (schedule.isNotEmpty ||
                      (maxStudents != null && maxStudents > 0)) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: _divider),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (schedule.isNotEmpty) ...[
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: _subText),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              schedule,
                              style: const TextStyle(
                                  fontSize: 12, color: _subText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (maxStudents != null && maxStudents > 0) ...[
                          const Icon(Icons.groups_outlined,
                              size: 14, color: _subText),
                          const SizedBox(width: 5),
                          Text(
                            'Max $maxStudents',
                            style: const TextStyle(
                                fontSize: 12, color: _subText),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
