import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/live_broadcast_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';

/// Watch a live broadcast (subscribe-only). Connects to LiveKit with a viewer
/// token and renders the broadcaster's video track.
class LiveViewerScreen extends ConsumerStatefulWidget {
  final LiveBroadcast broadcast;

  const LiveViewerScreen({Key? key, required this.broadcast}) : super(key: key);

  @override
  ConsumerState<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends ConsumerState<LiveViewerScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _remoteVideo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  @override
  void dispose() {
    _listener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      final token = await ref.read(liveServiceProvider).getViewerToken(widget.broadcast.id);
      final room = Room();
      final listener = room.createListener();

      listener
        ..on<TrackSubscribedEvent>((e) {
          if (e.track is VideoTrack) {
            setState(() => _remoteVideo = e.track as VideoTrack);
          }
        })
        ..on<TrackUnsubscribedEvent>((e) {
          if (identical(e.track, _remoteVideo)) {
            setState(() => _remoteVideo = null);
          }
        })
        ..on<RoomDisconnectedEvent>((_) {
          if (mounted) setState(() => _error = 'The broadcast has ended.');
        });

      await room.connect(token.url, token.token);

      // Pick up any track already published before we subscribed.
      _pickExistingVideo(room);

      if (!mounted) {
        await room.disconnect();
        return;
      }
      setState(() {
        _room = room;
        _listener = listener;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _pickExistingVideo(Room room) {
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        if (pub.track != null) {
          _remoteVideo = pub.track;
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.broadcast;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(b.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(child: _buildStage()),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF18181B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    [b.broadcasterName, if (b.companyName != null) b.companyName].join(' · '),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    if (_loading) {
      return const CircularProgressIndicator();
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.videoOff, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    if (_remoteVideo != null) {
      return VideoTrackRenderer(_remoteVideo!, fit: VideoViewFit.contain);
    }
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Waiting for the broadcaster’s video…', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}
