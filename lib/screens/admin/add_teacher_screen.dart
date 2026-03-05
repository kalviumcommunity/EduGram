import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_colors.dart';

// ── Color aliases pointing to shared constants ──
const _blue = appBlue;
const _blueDark = appBlueDark;
const _blueSoft = appBlueSoft;
const _bg = appBg;
const _darkText = appDarkText;
const _subText = appSubText;
const _divider = appDivider;
const _inputBg = appInputBg;

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

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedBatch;
  bool _saving = false;

  final List<String> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('batches').get();
      if (mounted) {
        setState(() {
          _batches.clear();
          for (final doc in snap.docs) {
            _batches.add(doc.data()['name']?.toString() ?? doc.id);
          }
        });
      }
    } catch (e) {
      debugPrint('AddTeacherScreen: Failed to load batches: $e');
      if (mounted) {
        _showMsg('Could not load batches. Please try again later.');
      }
    }
  }

  Future<void> _saveTeacher() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMsg('Please enter teacher name');
      return;
    }
    if (phone.length != 10) {
      _showMsg('Phone number must be exactly 10 digits');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'phone': phone,
        'role': 'teacher',
        'batch': _selectedBatch,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMsg('Teacher added successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('AddTeacherScreen: Failed to save teacher: $e');
      _showMsg('An error occurred while saving the teacher. Please try again.');
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
                      'Add New Teacher',
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
                                child: const Icon(Icons.person_outline_rounded,
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

                    // Teacher Name
                    _buildLabel('Teacher Name'),
                    const SizedBox(height: 8),
                    _buildNameField(
                      controller: _nameController,
                      hint: 'e.g. Robert Fox',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _buildPhoneField(),
                    const SizedBox(height: 20),

                    // Assign Batch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Assign Batch'),
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
                    _buildDropdown(),
                    const SizedBox(height: 8),
                    const Text(
                      'You can assign multiple batches later in settings.',
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
                  onPressed: _saving ? null : _saveTeacher,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.person_add_rounded, size: 22),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Teacher',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    shadowColor: _blue.withOpacity(0.4),
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

  /// Name field with auto-capitalize after every space
  Widget _buildNameField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        inputFormatters: [
          _CapitalizeWordsFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        ],
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

  /// Phone field — digits only, max 10, with counter
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBatch,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.search_rounded, color: _subText.withOpacity(0.6), size: 20),
              const SizedBox(width: 10),
              Text(
                'Search and select batch',
                style: TextStyle(
                    color: _subText.withOpacity(0.6), fontSize: 14),
              ),
            ],
          ),
          icon: Icon(Icons.unfold_more_rounded,
              color: _subText.withOpacity(0.6), size: 22),
          items: _batches
              .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b,
                        style: const TextStyle(
                            fontSize: 14, color: _darkText)),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedBatch = val),
        ),
      ),
    );
  }
}
