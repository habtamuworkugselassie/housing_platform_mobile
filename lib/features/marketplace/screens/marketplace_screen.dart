import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import 'organization_list_screen.dart';

/// Marketplace categories matching the frontend: organizations grouped by type.
/// Tapping a category opens the organization list for that type.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  static const List<Map<String, String>> _categories = [
    {'type': 'REAL_ESTATE_COMPANY', 'label': 'Real Estate', 'icon': 'building'},
    {'type': 'BANK', 'label': 'Banks', 'icon': 'landmark'},
    {'type': 'INSURANCE', 'label': 'Insurance', 'icon': 'shield'},
    {'type': 'CONTRACTOR', 'label': 'Contractors', 'icon': 'hammer'},
    {'type': 'CONSULTANT_ARCHITECT', 'label': 'Consultants & Architects', 'icon': 'pencil'},
    {'type': 'SUPPLIER', 'label': 'Suppliers', 'icon': 'package'},
    {'type': 'FINISHING_CONTRACTOR', 'label': 'Finishing Work', 'icon': 'paintbrush'},
  ];

  static IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'landmark':
        return LucideIcons.landmark;
      case 'shield':
        return LucideIcons.shield;
      case 'hammer':
        return LucideIcons.hammer;
      case 'pencil':
        return LucideIcons.pencil;
      case 'package':
        return LucideIcons.package;
      case 'paintbrush':
        return LucideIcons.paintbrush;
      default:
        return LucideIcons.building2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text('Marketplace'),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Browse organizations by type',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          ..._categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrganizationListScreen(
                          organizationType: cat['type']!,
                          title: cat['label']!,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconFor(cat['icon']!),
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            cat['label']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
