import 'package:flutter/material.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/providers/root_tab_provider.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import '../../exhibition/screens/enquiry_screen.dart';
import '../../exhibition/screens/live_broadcasts_screen.dart';
import '../../profile/screens/profile_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final currentIndex = ref.watch(rootTabIndexProvider);

    // Live is a public tab at a fixed index (3) so it stays put whether or not
    // the auth-only Saved/Profile tabs are present.
    final List<Widget> activeScreens = [
      const HomeScreen(),
      const ExploreScreen(),
      const EnquiryScreen(),
      const LiveBroadcastsScreen(showBackButton: false),
      if (isAuthenticated) const Scaffold(body: Center(child: Text('Saved Properties Placeholder'))),
      if (isAuthenticated) const ProfileScreen(),
    ];

    final safeIndex = currentIndex >= activeScreens.length ? 0 : currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: activeScreens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: safeIndex,
        isAuthenticated: isAuthenticated,
        onTap: (index) => ref.read(rootTabIndexProvider.notifier).state = index,
      ),
    );
  }
}
