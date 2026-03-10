import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_colors.dart';
import '../../services/notification_service.dart';

// ── Color aliases pointing to shared constants ──
const _blue = appBlue;
const _blueDark = appBlueDark;
const _blueSoft = appBlueSoft;
const _bg = appBg;
const _darkText = appDarkText;
const _subText = appSubText;
const _divider = appDivider;
const _inputBg = appInputBg;

const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Capitalizes the first letter of the input
class _CapitalizeFirstFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text[0].toUpperCase() + newValue.text.substring(1);
    return TextEditingValue(
      text: text,
      selection: newValue.selection,
    );
  }
}

class AddBatchScreen extends StatefulWidget {
  final String? batchId;
  final Map<String, dynamic>? batchData;

  const AddBatchScreen({super.key, this.batchId, this.batchData});

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _batchNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  bool _saving = false;

  // Day selection
  final Set<String> _selectedDays = {};

  // Time selection (24h)
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String _formatTime24(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void initState() {
    super.initState();
    if (widget.batchData != null) {
      _batchNameController.text = widget.batchData!['name']?.toString() ?? '';
      _subjectController.text = widget.batchData!['subject']?.toString() ?? '';
      _maxStudentsController.text = widget.batchData!['maxStudents']?.toString() ?? '';
      
      if (widget.batchData!['selectedDays'] is List) {
        for (final day in widget.batchData!['selectedDays']) {
          _selectedDays.add(day.toString());
        }
      }
      
      if (widget.batchData!['startTime'] != null) {
        final parts = widget.batchData!['startTime'].toString().split(':');
        if (parts.length == 2) {
          _startTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      if (widget.batchData!['endTime'] != null) {
        final parts = widget.batchData!['endTime'].toString().split(':');
        if (parts.length == 2) {
          _endTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 17, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      
      if (_maxStudentsController.text == '0') {
        _maxStudentsController.text = ''; // Leave empty for 0
      }
    }
  }

  String get _scheduleString {
    final parts = <String>[];
    if (_selectedDays.isNotEmpty) {
      // Sort days in order
      final sorted = _allDays.where((d) => _selectedDays.contains(d)).toList();
      parts.add(sorted.join(', '));
    }
    if (_startTime != null && _endTime != null) {
      parts.add('${_formatTime24(_startTime!)} – ${_formatTime24(_endTime!)}');
    } else if (_startTime != null) {
      parts.add(_formatTime24(_startTime!));
    }
    return parts.join(' — ');
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveBatch() async {
    final name = _batchNameController.text.trim();
    final subject = _subjectController.text.trim();
    final maxStudents = _maxStudentsController.text.trim();

    if (name.isEmpty) {
      _showMsg('Please enter batch name');
      return;
    }
    if (subject.isEmpty) {
      _showMsg('Please enter subject');
      return;
    }

    setState(() => _saving = true);
    try {
      // Sort selectedDays in Mon→Sun order so the list is consistent
      final sortedDays =
          _allDays.where((d) => _selectedDays.contains(d)).toList();

      final data = <String, dynamic>{
        'name': name,
        'subject': subject,
        'schedule': _scheduleString,
        'selectedDays': sortedDays,
        'startTime': _startTime != null ? _formatTime24(_startTime!) : null,
        'endTime': _endTime != null ? _formatTime24(_endTime!) : null,
        'maxStudents': int.tryParse(maxStudents) ?? 0,
      };

      if (widget.batchId != null) {
        // Update
        await FirebaseFirestore.instance
            .collection('batches')
            .doc(widget.batchId)
            .update(data);
        if (mounted) {
          _showMsg('Batch updated successfully!');
          Navigator.pop(context, true);
        }
      } else {
        // Add
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('batches').add(data);
        // Fire notification
        NotificationService.instance.notifyNewBatch(name);
        if (mounted) {
          _showMsg('Batch created successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('AddBatchScreen: Failed to save batch: $e');
      _showMsg('An error occurred while saving the batch. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _subjectController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: _blue, size: 30),
                  ),
                  Expanded(
                    child: Text(
                      widget.batchId != null ? 'Edit Batch' : 'Add New Batch',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
            Container(height: 1, color: _divider),

            // ── Form body ──
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch icon
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: _blueSoft,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _blue.withOpacity(0.25), width: 2),
                            ),
                            child: const Icon(Icons.layers_rounded,
                                color: _blue, size: 44),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.batchId != null ? 'Edit Batch Details' : 'New Batch Details',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _subText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Batch Name
                    _buildLabel('Batch Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _batchNameController,
                      hint: 'e.g. Morning Batch A',
                      icon: Icons.bookmark_outline_rounded,
                    ),
                    const SizedBox(height: 20),

                    // Subject — auto-capitalize first letter
                    _buildLabel('Subject'),
                    const SizedBox(height: 8),
                    _buildSubjectField(),
                    const SizedBox(height: 20),

                    // Schedule — Day Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Schedule Days'),
                        const Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _subText,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDayPicker(),
                    const SizedBox(height: 20),

                    // Time picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Timing (24h)'),
                        const Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _subText,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTimePickers(),
                    const SizedBox(height: 20),

                    // Max Students
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Max Students'),
                        const Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _subText,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _maxStudentsController,
                      hint: 'e.g. 30',
                      icon: Icons.groups_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Leave empty for unlimited students.',
                      style: TextStyle(fontSize: 11, color: _blue),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Save button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveBatch,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_box_rounded, size: 22),
                  label: Text(
                    _saving ? 'Saving...' : (widget.batchId != null ? 'Save Changes' : 'Save Batch'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: _darkText),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, color: _subText, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          hintText: hint,
          hintStyle: TextStyle(color: _subText.withOpacity(0.6), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Subject field — auto-capitalize first letter
  Widget _buildSubjectField() {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: TextField(
        controller: _subjectController,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [_CapitalizeFirstFormatter()],
        style: const TextStyle(fontSize: 14, color: _darkText),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.menu_book_rounded, color: _subText, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          hintText: 'e.g. Mathematics',
          hintStyle: TextStyle(color: _subText.withOpacity(0.6), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Day picker — toggle chips for Mon–Sun
  Widget _buildDayPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allDays.map((day) {
        final selected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _blue : _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _blue : _divider,
                width: 1,
              ),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _subText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Start and End time pickers (24h format)
  Widget _buildTimePickers() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickTime(isStart: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: _subText, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _startTime != null
                        ? _formatTime24(_startTime!)
                        : 'Start Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: _startTime != null ? _darkText : _subText.withOpacity(0.6),
                      fontWeight:
                          _startTime != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('–',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _subText)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickTime(isStart: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: _subText, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _endTime != null
                        ? _formatTime24(_endTime!)
                        : 'End Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: _endTime != null ? _darkText : _subText.withOpacity(0.6),
                      fontWeight:
                          _endTime != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
