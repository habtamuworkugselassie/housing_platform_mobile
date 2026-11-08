import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/providers/root_tab_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/brand.dart';

/// The expo hero, mirroring the web landing hero: a deep-violet panel with the eyebrow
/// pill, the extrabold headline with the gold accent word, the date pill, a gold
/// "Register interest" call to action that opens the Enquiry tab, and the stat row.
class ExhibitionInfoSection extends ConsumerWidget {
  const ExhibitionInfoSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BrandPanel(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EyebrowPill('Ethio Build Connect Expo', onDark: true),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                children: const [
                  TextSpan(text: 'Ethiopia Real Estate Expo and Construction '),
                  TextSpan(
                    text: 'Exhibition',
                    style: TextStyle(
                      color: AppTheme.goldBright,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.goldBright,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendarDays, size: 14, color: AppTheme.goldBright),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '9–13 January 2027 · Addis Convention Center',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Meet developers, banks, contractors and suppliers under one roof. Explore listings, financing and industry partners in one place.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 18),
            GoldButton(
              label: 'Register your interest',
              onPressed: () => ref.read(rootTabIndexProvider.notifier).state = 2,
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: StatTile(value: '5 days', label: 'Launches, talks, deals')),
                Expanded(child: StatTile(value: 'Addis', label: 'Convention Center')),
                Expanded(child: StatTile(value: '300+', label: 'Exhibitors')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
