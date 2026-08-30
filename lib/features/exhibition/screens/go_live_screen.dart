import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/models/live_broadcast_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';

/// Broadcaster screen: fill a short form, preview the camera, request approval,
/// then publish a live stream to the self-hosted LiveKit server.
///
/// Role gating mirrors the web portal + backend:
///   - Visitor  → anonymous, allowed.
///   - Exhibitor → must be signed in.
///   - Organizer → reserved for admins / super-admins.
class GoLiveScreen extends ConsumerStatefulWidget {
  const GoLiveScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

enum _Phase { setup, awaitingApproval, live, ended }

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  String _role = 'VISITOR'; // VISITOR | EXHIBITOR | ORGANIZER

  _Phase _phase = _Phase.setup;
  bool _busy = false;
  String? _error;
  String _statusMessage = '';

  // Camera preview / capture
  LocalVideoTrack? _videoTrack;
  LocalAudioTrack? _audioTrack;
  CameraPosition _cameraPos = CameraPosition.front;
  bool _micEnabled = true;

  // LiveKit
  Room? _room;
  LiveBroadcast? _broadcast;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _titleController.dispose();
    _teardownMedia();
    super.dispose();
  }

  Future<void> _teardownMedia() async {
    try {
      await _videoTrack?.stop();
      await _videoTrack?.dispose();
    } catch (_) {}
    try {
      await _audioTrack?.stop();
      await _audioTrack?.dispose();
    } catch (_) {}
    try {
      await _room?.disconnect();
      await _room?.dispose();
    } catch (_) {}
    _videoTrack = null;
    _audioTrack = null;
    _room = null;
  }

  Future<bool> _ensurePermissions() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (cam.isGranted && mic.isGranted) return true;
    setState(() => _error = 'Camera and microphone access are required to go live.');
    return false;
  }

  // ---- Preview -------------------------------------------------------------

  Future<void> _startPreview() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    if (!await _ensurePermissions()) {
      setState(() => _busy = false);
      return;
    }
    try {
      final track = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(cameraPosition: _cameraPos),
      );
      if (!mounted) {
        await track.dispose();
        return;
      }
      setState(() {
        _videoTrack = track;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not start the camera: $e';
        _busy = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    final track = _videoTrack;
    if (track == null) return;
    final next = _cameraPos == CameraPosition.front ? CameraPosition.back : CameraPosition.front;
    try {
      await track.setCameraPosition(next);
      setState(() => _cameraPos = next);
    } catch (e) {
      setState(() => _error = 'Could not switch camera: $e');
    }
  }

  Future<void> _toggleMic() async {
    final track = _audioTrack;
    setState(() => _micEnabled = !_micEnabled);
    if (track != null) {
      try {
        _micEnabled ? await track.unmute() : await track.mute();
      } catch (_) {}
    }
  }

  // ---- Go live -------------------------------------------------------------

  bool _roleAllowed() {
    final auth = ref.read(authProvider);
    if (_role == 'EXHIBITOR' && !auth.isAuthenticated) {
      setState(() => _error = 'Please sign in to broadcast as an exhibitor.');
      return false;
    }
    if (_role == 'ORGANIZER' && !(auth.user?.isAdmin ?? false)) {
      setState(() => _error = 'Only an admin can broadcast as an organizer.');
      return false;
    }
    return true;
  }

  Future<void> _requestGoLive() async {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Your name is required.');
      return;
    }
    if (title.isEmpty) {
      setState(() => _error = 'A stream title is required.');
      return;
    }
    if (!_roleAllowed()) return;

    setState(() {
      _error = null;
      _busy = true;
    });

    if (!await _ensurePermissions()) {
      setState(() => _busy = false);
      return;
    }

    try {
      // Acquire the camera now (if not already previewing) so we're ready the
      // moment an organizer approves.
      _videoTrack ??= await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(cameraPosition: _cameraPos),
      );

      final live = ref.read(liveServiceProvider);
      final broadcast = await live.requestGoLive(
        name: name,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        role: _role,
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        title: title,
      );
      if (!mounted) return;
      setState(() {
        _broadcast = broadcast;
        _busy = false;
        _phase = _Phase.awaitingApproval;
        _statusMessage = 'Waiting for an organizer to approve your stream…';
      });
      if (broadcast.isApproved) {
        _connectAndPublish();
      } else {
        _startPolling();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    final b = _broadcast;
    if (b == null) return;
    try {
      final updated = await ref.read(liveServiceProvider).getBroadcast(b.id);
      if (!mounted) return;
      _broadcast = updated;
      if (updated.isApproved) {
        _pollTimer?.cancel();
        _connectAndPublish();
      } else if (updated.isRejected) {
        _pollTimer?.cancel();
        setState(() {
          _phase = _Phase.ended;
          _statusMessage = 'Your request was declined by the organizers.';
        });
      }
    } catch (_) {
      // Transient errors are ignored; polling continues.
    }
  }

  Future<void> _connectAndPublish() async {
    final b = _broadcast;
    if (b == null) return;
    setState(() {
      _busy = true;
      _statusMessage = 'Approved — connecting…';
    });
    try {
      final token = await ref.read(liveServiceProvider).getPublishToken(b.id);
      final room = Room();
      await room.connect(token.url, token.token);

      _videoTrack ??= await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(cameraPosition: _cameraPos),
      );
      _audioTrack ??= await LocalAudioTrack.create();

      await room.localParticipant?.publishVideoTrack(_videoTrack!);
      await room.localParticipant?.publishAudioTrack(_audioTrack!);
      if (!_micEnabled) {
        await _audioTrack?.mute();
      }

      if (!mounted) {
        await room.disconnect();
        return;
      }
      setState(() {
        _room = room;
        _busy = false;
        _phase = _Phase.live;
        _statusMessage = 'You are live';
      });
    } catch (e) {
      setState(() {
        _error = 'Could not start broadcasting: $e';
        _busy = false;
      });
    }
  }

  Future<void> _endBroadcast() async {
    await _teardownMedia();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.ended;
      _statusMessage = 'Your broadcast has ended.';
    });
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text('Go live'),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.setup => _buildSetup(context),
          _Phase.awaitingApproval => _buildWaiting(context),
          _Phase.live => _buildLive(context),
          _Phase.ended => _buildEnded(context),
        },
      ),
    );
  }

  Widget _cameraSurface({bool showControls = false}) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            if (_videoTrack != null)
              VideoTrackRenderer(_videoTrack!, fit: VideoViewFit.cover)
            else
              const Center(
                child: Icon(LucideIcons.video, color: Colors.white24, size: 48),
              ),
            if (showControls)
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    _roundButton(
                      icon: _micEnabled ? LucideIcons.mic : LucideIcons.micOff,
                      onTap: _toggleMic,
                    ),
                    const SizedBox(width: 8),
                    _roundButton(icon: LucideIcons.switchCamera, onTap: _switchCamera),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildSetup(BuildContext context) {
    final auth = ref.watch(authProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cameraSurface(showControls: _videoTrack != null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _startPreview,
                  icon: const Icon(LucideIcons.camera, size: 18),
                  label: Text(_videoTrack == null ? 'Preview camera' : 'Restart preview'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Your name *'),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Abebe Kebede',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _label('Stream title *'),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Live tour of our booth',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _label('I am broadcasting as'),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'VISITOR', child: Text('Visitor')),
              DropdownMenuItem(value: 'EXHIBITOR', child: Text('Exhibitor (booth)')),
              DropdownMenuItem(value: 'ORGANIZER', child: Text('Organizer (staff)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
          if (_role == 'EXHIBITOR' && !auth.isAuthenticated)
            _hint('Sign in to your exhibitor account to broadcast from your booth.'),
          if (_role == 'ORGANIZER' && !(auth.user?.isAdmin ?? false))
            _hint('Organizer broadcasting is reserved for event staff (admins).'),
          const SizedBox(height: 16),
          _label('Email (optional)'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _label('Company (optional)'),
          TextFormField(
            controller: _companyController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _requestGoLive,
              icon: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.radio, size: 18),
              label: const Text('Request to go live'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An organizer approves each stream before it appears on the live wall.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _cameraSurface(showControls: true),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _endBroadcast,
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLive(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _cameraSurface(showControls: true)),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.radio, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('LIVE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              onPressed: _endBroadcast,
              icon: const Icon(LucideIcons.square, size: 18),
              label: const Text('End broadcast'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnded(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 56),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFB45309))),
      );
}
