import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Exhibition intro section (mirrors frontend landing planning section).
/// Shown on Home before the properties list.
class ExhibitionInfoSection extends StatelessWidget {
  const ExhibitionInfoSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLANNING THE EXHIBITION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Real Estate & Housing Exhibition',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'A professional platform connecting developers, real estate companies, banks, contractors, and suppliers with buyers and renters. Explore listings, financing options, and industry partners in one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Who showcases: Real estate companies, banks, contractors, suppliers, consultants & architects.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
        ],
      ),
    );
  }
}
