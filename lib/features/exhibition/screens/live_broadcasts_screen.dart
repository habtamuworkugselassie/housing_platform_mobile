import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/live_broadcast_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import 'go_live_screen.dart';
import 'live_viewer_screen.dart';

/// Public wall of currently-live streams, with a shortcut to start your own.
class LiveBroadcastsScreen extends ConsumerStatefulWidget {
  /// Hidden when the screen is used as a root bottom-nav tab.
  final bool showBackButton;

  const LiveBroadcastsScreen({Key? key, this.showBackButton = true}) : super(key: key);

  @override
  ConsumerState<LiveBroadcastsScreen> createState() => _LiveBroadcastsScreenState();
}

class _LiveBroadcastsScreenState extends ConsumerState<LiveBroadcastsScreen> {
  bool _loading = true;
  String? _error;
  List<LiveBroadcast> _live = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(liveServiceProvider).listLive();
      if (mounted) setState(() => _live = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goLive() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GoLiveScreen()))
        .then((_) => _load());
  }

  void _watch(LiveBroadcast b) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiveViewerScreen(broadcast: b)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.showBackButton ? const CustomBackButton() : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Live now'),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goLive,
        backgroundColor: AppTheme.error,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.radio),
        label: const Text('Go live'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _emptyState(
        icon: LucideIcons.wifiOff,
        title: 'Could not load live streams',
        subtitle: _error!,
      );
    }
    if (_live.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            _emptyState(
              icon: LucideIcons.video,
              title: 'No live streams right now',
              subtitle: 'Check back during the exhibition, or start your own broadcast.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _live.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _liveCard(_live[i]),
      ),
    );
  }

  Widget _liveCard(LiveBroadcast b) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _watch(b),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.playCircle, color: Colors.white70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      if (b.broadcasterRole != null) ...[
                        const SizedBox(width: 8),
                        Text(_roleLabel(b.broadcasterRole!),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    [b.broadcasterName, if (b.companyName != null) b.companyName].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'EXHIBITOR':
        return 'Exhibitor';
      case 'ORGANIZER':
        return 'Organizer';
      default:
        return 'Visitor';
    }
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
