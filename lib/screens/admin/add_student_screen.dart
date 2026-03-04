import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Same colors as dashboard ──
const _blue = Color(0xFF2196F3);
const _blueDark = Color(0xFF1565C0);
const _blueSoft = Color(0xFFE8F1FD);
const _bg = Color(0xFFF0F3FA);
const _darkText = Color(0xFF1C2233);
const _subText = Color(0xFF8C96A8);
const _divider = Color(0xFFECEFF5);
const _inputBg = Color(0xFFF6F7FB);

/// Capitalizes the first letter after every space
class _CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final buffer = StringBuffer();
    bool capitalizeNext = true;
    for (int i = 0; i < newValue.text.length; i++) {
      final ch = newValue.text[i];
      if (ch == ' ') {
        buffer.write(ch);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(ch.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(ch);
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

const _gradeOptions = [
  '1st', '2nd', '3rd', '4th', '5th', '6th',
  '7th', '8th', '9th', '10th', '11th', '12th',
];

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGrade;
  bool _saving = false;

  Future<void> _saveStudent() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMsg('Please enter student name');
      return;
    }
    if (phone.length != 10) {
      _showMsg('Phone number must be exactly 10 digits');
      return;
    }
    if (_selectedGrade == null) {
      _showMsg('Please select a grade');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('students').add({
        'name': name,
        'phone': phone,
        'grade': _selectedGrade,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showMsg('Student added successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMsg('Error: ${e.toString()}');
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
    _nameController.dispose();
    _phoneController.dispose();
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
                  const Expanded(
                    child: Text(
                      'Add New Student',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                    // Avatar
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: _blueSoft,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _blue.withOpacity(0.25),
                                      width: 2),
                                ),
                                child: const Icon(Icons.school_outlined,
                                    color: _blue, size: 44),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Upload Profile Picture',
                            style: TextStyle(
                              fontSize: 12,
                              color: _subText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Student Name — auto capitalize each word
                    _buildLabel('Student Name'),
                    const SizedBox(height: 8),
                    _buildNameField(),
                    const SizedBox(height: 20),

                    // Phone Number — 10 digits only
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _buildPhoneField(),
                    const SizedBox(height: 20),

                    // Grade — dropdown 1st to 12th
                    _buildLabel('Grade'),
                    const SizedBox(height: 8),
                    _buildGradeDropdown(),
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
                  onPressed: _saving ? null : _saveStudent,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.person_add_alt_1_rounded, size: 22),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Student',
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

  /// Name field — auto-capitalize first letter of each word, only letters + spaces
  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        inputFormatters: [
          _CapitalizeWordsFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        ],
        style: const TextStyle(fontSize: 14, color: _darkText),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.person_outline_rounded, color: _subText, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          hintText: 'e.g. Robert Fox',
          hintStyle: TextStyle(color: _subText.withOpacity(0.6), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Phone — digits only, max 10, with digit counter
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: const TextStyle(fontSize: 14, color: _darkText),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.phone_android_rounded, color: _subText, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          hintText: 'Enter 10-digit number',
          hintStyle: TextStyle(color: _subText.withOpacity(0.6), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '',
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _phoneController,
              builder: (_, val, __) => Text(
                '${val.text.length}/10',
                style: TextStyle(
                  fontSize: 12,
                  color: val.text.length == 10 ? Colors.green : _subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  /// Grade dropdown — 1st to 12th
  Widget _buildGradeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGrade,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.class_outlined,
                  color: _subText.withOpacity(0.6), size: 20),
              const SizedBox(width: 10),
              Text(
                'Select grade (1st – 12th)',
                style: TextStyle(
                    color: _subText.withOpacity(0.6), fontSize: 14),
              ),
            ],
          ),
          icon: Icon(Icons.unfold_more_rounded,
              color: _subText.withOpacity(0.6), size: 22),
          items: _gradeOptions
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Row(
                      children: [
                        const Icon(Icons.school_outlined,
                            color: _blue, size: 18),
                        const SizedBox(width: 10),
                        Text('Grade $g',
                            style: const TextStyle(
                                fontSize: 14, color: _darkText)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedGrade = val),
        ),
      ),
    );
  }
}
