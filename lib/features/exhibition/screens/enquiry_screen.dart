import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../widgets/exhibition_interest_form.dart';
import '../../../core/widgets/brand.dart';

/// Enquiry tab: Exhibition stakeholder registration form.
class EnquiryScreen extends StatelessWidget {
  const EnquiryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(bottom: false, child: SizedBox.shrink()),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SectionHeader(
                eyebrow: 'Ethio Build Connect Expo · 2027',
                title: 'Register your interest',
                subtitle: 'Exhibit, sponsor or visit. Tell us who you are and we will follow up with the right package.',
              ),
            ),
            const SizedBox(height: 20),
            const ExhibitionInterestForm(),
          ],
        ),
      ),
    );
  }
}
