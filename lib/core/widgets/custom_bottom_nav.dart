import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Floating pill navigation, the counterpart of the web's pill nav bar: a deep-violet
/// capsule lifted off the page, white items, the active one in gold with a soft well.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isAuthenticated;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.isAuthenticated,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(LucideIcons.house, 'Home'),
      const _NavItem(LucideIcons.search, 'Explore'),
      const _NavItem(LucideIcons.messageCircle, 'Enquiry'),
      const _NavItem(LucideIcons.radio, 'Live'),
      if (isAuthenticated) const _NavItem(LucideIcons.heart, 'Saved'),
      if (isAuthenticated) const _NavItem(LucideIcons.user, 'Profile'),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.brandDeep,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandDeep.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavButton(
                  item: items[i],
                  active: i == currentIndex,
                  compact: items.length > 4,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.active, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.goldBright : Colors.white.withValues(alpha: 0.72);
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: compact ? 20 : 22, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
