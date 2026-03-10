import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'notifications_screen.dart';

const _blue = Color(0xFF2196F3);
const _blueSoft = Color(0xFFE8F1FD);
const _bg = Color(0xFFF0F3FA);
const _darkText = Color(0xFF1C2233);
const _subText = Color(0xFF8C96A8);
const _divider = Color(0xFFECEFF5);
const _cardBg = Colors.white;

class AdminProfileScreen extends StatelessWidget {
  final String phoneNumber;
  const AdminProfileScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
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
                      child: const Icon(Icons.person_rounded,
                          color: _blue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _darkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: _divider),

              const SizedBox(height: 28),

              // ── Avatar + Name ──
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+91 $phoneNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF43A047), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Admin Access',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF43A047),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Settings sections ──
              _buildSection('Account', [
                _SettingItem(
                  icon: Icons.phone_android_rounded,
                  iconColor: _blue,
                  iconBg: _blueSoft,
                  title: 'Phone Number',
                  subtitle: '+91 $phoneNumber',
                ),
                _SettingItem(
                  icon: Icons.admin_panel_settings_rounded,
                  iconColor: const Color(0xFF7C4DBA),
                  iconBg: const Color(0xFFF0EBF8),
                  title: 'Role',
                  subtitle: 'Institute Administrator',
                ),
                _SettingItem(
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFFD97A1A),
                  iconBg: const Color(0xFFFFF0E0),
                  title: 'Institute',
                  subtitle: 'EduTrack Institute',
                ),
              ]),

              const SizedBox(height: 16),

              _buildSection('Preferences', [
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFF43A047),
                  iconBg: const Color(0xFFE8F5E9),
                  title: 'Notifications',
                  subtitle: 'Manage notification settings',
                  showArrow: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                _SettingItem(
                  icon: Icons.language_rounded,
                  iconColor: _blue,
                  iconBg: _blueSoft,
                  title: 'Language',
                  subtitle: 'English',
                  showArrow: true,
                ),
              ]),

              const SizedBox(height: 16),

              _buildSection('About', [
                _SettingItem(
                  icon: Icons.info_outline_rounded,
                  iconColor: _subText,
                  iconBg: _bg,
                  title: 'App Version',
                  subtitle: 'EduTrack Pro v1.0.0',
                ),
                _SettingItem(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: _subText,
                  iconBg: _bg,
                  title: 'Privacy Policy',
                  subtitle: 'View privacy policy',
                  showArrow: true,
                  onTap: () {
                    // TODO: Navigate to privacy policy
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (_) => const PrivacyPolicyScreen()));
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // ── Logout button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Log Out',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      foregroundColor: const Color(0xFFE53935),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold, color: _darkText)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _subText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            child: const Text('Log Out',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_SettingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _subText,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _divider, width: 1),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        borderRadius: BorderRadius.circular(item.onTap != null ? 14 : 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: item.iconBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:
                                    Icon(item.icon, color: item.iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(
                                          fontSize: 12, color: _subText),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.showArrow)
                                const Icon(Icons.chevron_right_rounded,
                                    color: _subText, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i < items.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 66),
                        child: Divider(height: 1, color: _divider),
                      ),
                  ],
                );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.showArrow = false,
    this.onTap,
  });
}
