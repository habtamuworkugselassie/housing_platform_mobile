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
import '../../../core/update/app_update.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  bool _updatePrompted = false;

  @override
  void initState() {
    super.initState();
    // Sideload update check: once per launch, after the first frame so it never delays startup.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final update = await ref.read(appUpdateProvider.future);
      if (!mounted || _updatePrompted || update == null) return;
      _updatePrompted = true;
      await maybeShowUpdateSheet(context, update);
    });
  }

  @override
  Widget build(BuildContext context) {
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
