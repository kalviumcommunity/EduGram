import 'package:flutter/material.dart';

const _bg = Color(0xFFF0F3FA);
const _darkText = Color(0xFF1C2233);
const _subText = Color(0xFF8C96A8);
const _divider = Color(0xFFECEFF5);
const _cardBg = Colors.white;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(
            color: _darkText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _divider, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Introduction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Welcome to EduGram. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you visit our application and tell you about your privacy rights.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _subText,
                ),
              ),
              SizedBox(height: 32),
              Text(
                '2. Data We Collect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:\n\n• Identity Data: includes first name, last name, username or similar identifier.\n• Contact Data: includes email address and telephone numbers.\n• Usage Data: includes information about how you use our application and services.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _subText,
                ),
              ),
              SizedBox(height: 32),
              Text(
                '3. How We Use Your Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n• Where we need to perform the contract we are about to enter into or have entered into with you.\n• Where it is necessary for our legitimate interests and your interests and fundamental rights do not override those interests.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _subText,
                ),
              ),
              SizedBox(height: 32),
              Text(
                '4. Data Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _subText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
