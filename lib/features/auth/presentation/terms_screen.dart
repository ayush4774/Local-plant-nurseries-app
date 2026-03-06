import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  final bool showPrivacyPolicy;

  const TermsScreen({super.key, this.showPrivacyPolicy = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: Text(showPrivacyPolicy ? 'Privacy Policy' : 'Terms of Service'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: showPrivacyPolicy
              ? _buildPrivacyPolicy(isDark)
              : _buildTerms(isDark),
        ),
      ),
    );
  }

  List<Widget> _buildTerms(bool isDark) {
    return [
      _sectionTitle('Terms of Service', isDark),
      _lastUpdated(isDark),
      const SizedBox(height: 20),
      _paragraph(
        'Welcome to Local Plant Nurseries. By using our app, you agree to the following terms and conditions. Please read them carefully before using our services.',
        isDark,
      ),
      _sectionTitle('1. Acceptance of Terms', isDark),
      _paragraph(
        'By downloading, installing, or using the Local Plant Nurseries app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.',
        isDark,
      ),
      _sectionTitle('2. Description of Service', isDark),
      _paragraph(
        'Local Plant Nurseries is a plant management application that allows users to:\n'
        '• Browse a catalog of plants native to India\n'
        '• Add plants to their personal collection\n'
        '• Track watering schedules and plant care\n'
        '• Set reminders for plant maintenance\n'
        '• View plant details including care instructions',
        isDark,
      ),
      _sectionTitle('3. User Accounts', isDark),
      _paragraph(
        'To use certain features, you may need to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account. You agree to provide accurate and complete information when creating your account.',
        isDark,
      ),
      _sectionTitle('4. User Content', isDark),
      _paragraph(
        'You retain ownership of any content you create within the app, including your plant collections and custom notes. We do not claim ownership over your personal data or plant collection information.',
        isDark,
      ),
      _sectionTitle('5. Acceptable Use', isDark),
      _paragraph(
        'You agree not to:\n'
        '• Use the app for any unlawful purpose\n'
        '• Attempt to gain unauthorized access to the app or its systems\n'
        '• Interfere with or disrupt the app\'s functionality\n'
        '• Copy, modify, or distribute the app\'s content without permission',
        isDark,
      ),
      _sectionTitle('6. Plant Care Disclaimer', isDark),
      _paragraph(
        'The plant care information provided in this app is for general guidance only. We do not guarantee the accuracy of care instructions, watering schedules, or other plant-related advice. Users should consult local nurseries or botanical experts for specific plant care needs. We are not liable for any damage to plants resulting from following the app\'s recommendations.',
        isDark,
      ),
      _sectionTitle('7. Intellectual Property', isDark),
      _paragraph(
        'The app, including its design, features, and content (excluding user content), is owned by Local Plant Nurseries and is protected by intellectual property laws. You may not reproduce, distribute, or create derivative works without our prior written consent.',
        isDark,
      ),
      _sectionTitle('8. Limitation of Liability', isDark),
      _paragraph(
        'The app is provided "as is" without warranties of any kind. We shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app.',
        isDark,
      ),
      _sectionTitle('9. Modifications', isDark),
      _paragraph(
        'We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the updated terms. We will notify users of significant changes through the app.',
        isDark,
      ),
      _sectionTitle('10. Contact', isDark),
      _paragraph(
        'If you have any questions about these Terms of Service, please contact us at support@localplantnurseries.com.',
        isDark,
      ),
      const SizedBox(height: 40),
    ];
  }

  List<Widget> _buildPrivacyPolicy(bool isDark) {
    return [
      _sectionTitle('Privacy Policy', isDark),
      _lastUpdated(isDark),
      const SizedBox(height: 20),
      _paragraph(
        'Your privacy is important to us. This Privacy Policy explains how Local Plant Nurseries collects, uses, and protects your information.',
        isDark,
      ),
      _sectionTitle('1. Information We Collect', isDark),
      _paragraph(
        '• Account Information: Name, email address when you create an account\n'
        '• Plant Collection Data: Plants you add, watering schedules, and care preferences\n'
        '• Usage Data: How you interact with the app, features you use\n'
        '• Device Information: Device type, operating system version',
        isDark,
      ),
      _sectionTitle('2. How We Use Your Information', isDark),
      _paragraph(
        '• To provide and maintain our service\n'
        '• To send watering reminders and plant care notifications\n'
        '• To improve the app experience\n'
        '• To provide customer support\n'
        '• To detect and prevent technical issues',
        isDark,
      ),
      _sectionTitle('3. Data Storage', isDark),
      _paragraph(
        'Your plant collection data is stored locally on your device using secure storage. Account information may be stored on Firebase servers with industry-standard encryption. We do not sell your personal data to third parties.',
        isDark,
      ),
      _sectionTitle('4. Data Sharing', isDark),
      _paragraph(
        'We do not share your personal information with third parties except:\n'
        '• When required by law\n'
        '• To protect our rights and safety\n'
        '• With service providers who assist in operating the app (e.g., Firebase for authentication)',
        isDark,
      ),
      _sectionTitle('5. Data Security', isDark),
      _paragraph(
        'We implement appropriate security measures to protect your information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
        isDark,
      ),
      _sectionTitle('6. Your Rights', isDark),
      _paragraph(
        'You have the right to:\n'
        '• Access your personal data\n'
        '• Correct inaccurate data\n'
        '• Delete your account and associated data\n'
        '• Export your plant collection data\n'
        '• Opt out of notifications',
        isDark,
      ),
      _sectionTitle('7. Children\'s Privacy', isDark),
      _paragraph(
        'Our app does not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal data, please contact us.',
        isDark,
      ),
      _sectionTitle('8. Changes to This Policy', isDark),
      _paragraph(
        'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app.',
        isDark,
      ),
      _sectionTitle('9. Contact Us', isDark),
      _paragraph(
        'If you have questions about this Privacy Policy, contact us at privacy@localplantnurseries.com.',
        isDark,
      ),
      const SizedBox(height: 40),
    ];
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _lastUpdated(bool isDark) {
    return Text(
      'Last updated: February 2026',
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _paragraph(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
