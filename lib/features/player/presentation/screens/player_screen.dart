import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/providers.dart';
import '../../../../data/repositories/favorites_repository_impl.dart';
import '../../../../data/repositories/history_repository_impl.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/channel.dart';
import '../../../../domain/entities/playback_session.dart';
import '../../../../domain/entities/watch_history_item.dart';
import '../../../../services/playback/playback_controller.dart';
import '../widgets/player_channel_drawer.dart';
import '../../../epg/presentation/widgets/epg_now_next_overlay.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({required this.channelId, super.key});
  final String channelId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _videoController;
  bool _showControls = true;
  bool _showEpg = false;
  bool _showDrawer = false;
  Timer? _hideTimer;
  Timer? _startupTimer;
  DateTime? _watchStart;
  String? _activeSourceUrl;
  bool _hasReportedError = false;
  bool _hasConfirmedPlaying = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _scheduleHide();
  }

  @override
  void dispose() {
    _saveHistory();
    _videoController?.removeListener(_onPlayerEvent);
    _videoController?.dispose();
    _hideTimer?.cancel();
    _startupTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // PLAYER LIFECYCLE — THE CRITICAL PATH
  // ═══════════════════════════════════════════════════════════

  void _initializePlayer(String url) {
    // Guard: don't re-init the same URL
    if (url == _activeSourceUrl && _videoController != null) return;

    // Cleanup previous controller
    _startupTimer?.cancel();
    _videoController?.removeListener(_onPlayerEvent);
    _videoController?.dispose();
    _videoController = null;

    _activeSourceUrl = url;
    _hasReportedError = false;
    _hasConfirmedPlaying = false;

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: const {'Connection': 'keep-alive'},
    );

    // Start a startup timeout — if the player doesn't initialize
    // within 15 seconds, treat it as a failure
    _startupTimer = Timer(const Duration(seconds: 15), () {
      if (!_hasConfirmedPlaying && mounted) {
        _reportError('Startup timeout: stream did not start within 15s');
      }
    });

    _videoController!.initialize().then((_) {
      if (!mounted) return;
      _startupTimer?.cancel();
      setState(() {});
      _videoController!.play();
      _watchStart = DateTime.now();

      // Wait a brief moment to confirm playback actually starts
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || _videoController == null) return;
        if (_videoController!.value.isPlaying &&
            !_videoController!.value.hasError) {
          _hasConfirmedPlaying = true;
          ref.read(playbackControllerProvider.notifier).confirmPlaybackStarted();
        }
      });
    }).catchError((Object e) {
      _startupTimer?.cancel();
      _reportError(e.toString());
    });

    _videoController!.addListener(_onPlayerEvent);
  }

  /// Player event listener — FIXED to prevent cascading errors.
  void _onPlayerEvent() {
    if (!mounted || _videoController == null) return;
    final value = _videoController!.value;

    // Confirm playing if we haven't yet
    if (!_hasConfirmedPlaying &&
        value.isPlaying &&
        !value.hasError &&
        value.isInitialized) {
      _hasConfirmedPlaying = true;
      _startupTimer?.cancel();
      ref.read(playbackControllerProvider.notifier).confirmPlaybackStarted();
    }

    // Report error ONCE per source attempt
    if (value.hasError && !_hasReportedError) {
      _reportError(value.errorDescription ?? 'Unknown playback error');
    }

    // Update UI for buffering
    if (value.isBuffering) setState(() {});
  }

  /// Report error exactly once, then stop listening.
  void _reportError(String error) {
    if (_hasReportedError) return;
    _hasReportedError = true;
    _activeSourceUrl = null;
    _startupTimer?.cancel();

    // Remove listener to prevent duplicate reports
    _videoController?.removeListener(_onPlayerEvent);

    ref.read(playbackControllerProvider.notifier).reportPlaybackError(error);
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORY
  // ═══════════════════════════════════════════════════════════

  void _saveHistory() {
    final ch = ref.read(playbackControllerProvider).currentChannel;
    if (ch == null || _watchStart == null) return;
    final dur = DateTime.now().difference(_watchStart!).inSeconds;
    if (dur < 5) return;
    ref.read(historyRepositoryProvider).addToHistory(WatchHistoryItem(
          channelId: ch.id,
          watchedAt: _watchStart!,
          durationSeconds: dur,
          sourceId: ref.read(playbackControllerProvider).currentSource?.id,
        ));
    ref.invalidate(historyProvider);
  }

  // ═══════════════════════════════════════════════════════════
  // CONTROLS
  // ═══════════════════════════════════════════════════════════

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showControls) setState(() => _showControls = false);
    });
  }

  void _tap() {
    setState(() {
      _showControls = !_showControls;
      _showDrawer = false;
      if (_showControls) _scheduleHide();
    });
  }

  void _togglePlay() {
    if (_videoController?.value.isPlaying ?? false) {
      _videoController!.pause();
      ref.read(playbackControllerProvider.notifier).pause();
    } else {
      _videoController?.play();
      ref.read(playbackControllerProvider.notifier).resume();
    }
    setState(() {});
  }

  void _toggleFav(String id) async {
    final repo = ref.read(favoritesRepositoryProvider);
    (await repo.isFavorite(id))
        ? await repo.removeFavorite(id)
        : await repo.addFavorite(id);
    ref.invalidate(isFavoriteProvider(id));
    ref.invalidate(favoritesProvider);
  }

  void _switchTo(Channel ch) {
    _saveHistory();
    _watchStart = null;
    _activeSourceUrl = null;
    _hasReportedError = false;
    _hasConfirmedPlaying = false;
    ref.read(playbackControllerProvider.notifier).playChannel(ch);
    setState(() => _showDrawer = false);
  }

  void _changeChannel(int delta) async {
    final channels = await ref.read(channelsProvider.future);
    if (delta > 0) {
      ref.read(playbackControllerProvider.notifier).playNextChannel(channels);
    } else {
      ref.read(playbackControllerProvider.notifier).playPreviousChannel(channels);
    }
  }

  void _exit() {
    ref.read(playbackControllerProvider.notifier).stop();
    context.pop();
  }

  void _onKey(KeyEvent e, PlaybackSessionState st) {
    if (e is! KeyDownEvent) return;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _togglePlay();
      case LogicalKeyboardKey.arrowUp:
        setState(() => _showControls = true);
        _scheduleHide();
      case LogicalKeyboardKey.arrowDown:
        setState(() { _showDrawer = true; _showControls = false; });
      case LogicalKeyboardKey.arrowLeft:
        _changeChannel(-1);
      case LogicalKeyboardKey.arrowRight:
        _changeChannel(1);
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        _showDrawer ? setState(() => _showDrawer = false) : _exit();
      case LogicalKeyboardKey.keyI:
        setState(() => _showEpg = !_showEpg);
      case LogicalKeyboardKey.keyF:
        _toggleFav(widget.channelId);
      default:
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final chAsync = ref.watch(channelByIdProvider(widget.channelId));
    final ps = ref.watch(playbackControllerProvider);

    // React to source changes from the controller
    _syncPlayer(ps);

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (e) => _onKey(e, ps),
        child: chAsync.when(
          data: (ch) {
            if (ch == null) return _notFound();
            _autoStart(ch, ps);
            return GestureDetector(
              onTap: _tap,
              onDoubleTap: _togglePlay,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -200) {
                  setState(() { _showDrawer = true; _showControls = false; });
                } else if ((d.primaryVelocity ?? 0) > 200) {
                  setState(() => _showDrawer = false);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _videoLayer(),
                  if (_videoController?.value.isBuffering ?? false)
                    const Center(child: CircularProgressIndicator(
                        color: AppColors.accentGold, strokeWidth: 2.5)),
                  AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: _controls(context, ch, ps),
                    ),
                  ),
                  if (_showEpg)
                    Positioned(bottom: 80, left: 0, right: 200,
                      child: EpgNowNextOverlay(channelId: ch.id)),
                  if (_showDrawer)
                    Positioned(bottom: 0, left: 0, right: 0,
                      child: PlayerChannelDrawer(
                        currentChannelId: ch.id,
                        onChannelSelected: _switchTo,
                        onClose: () => setState(() => _showDrawer = false),
                      )),
                  if (ps.isLoading || ps.isSwitching) _loadingOverlay(ps),
                  if (ps.hasError) _errorOverlay(ps),
                ],
              ),
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold)),
          error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  void _autoStart(Channel ch, PlaybackSessionState ps) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ps.currentChannel?.id != ch.id) {
        ref.read(playbackControllerProvider.notifier).playChannel(ch);
      }
    });
  }

  void _syncPlayer(PlaybackSessionState ps) {
    if (ps.currentSource != null &&
        ps.isLoading &&
        ps.currentSource!.url != _activeSourceUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializePlayer(ps.currentSource!.url);
      });
    }
  }

  Widget _notFound() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.tv_off_rounded, color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          const Text('Channel not found', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Go Back')),
        ]),
      );

  Widget _videoLayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Center(child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!)));
    }
    return const SizedBox.expand();
  }

  Widget _controls(BuildContext context, Channel ch, PlaybackSessionState ps) {
    final isFav = ref.watch(isFavoriteProvider(ch.id)).valueOrNull ?? false;
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xBB000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
        stops: [0, 0.25, 0.7, 1],
      )),
      child: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: _exit),
            const SizedBox(width: 4),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ch.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              if (ps.currentSource != null)
                Text(ps.currentSource!.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.liveRed, borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: AppColors.liveRedGlow, blurRadius: 10)]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: Colors.white, size: 6), SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.accentGold : Colors.white70),
              onPressed: () => _toggleFav(ch.id)),
          ])),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ctrlBtn(Icons.skip_previous_rounded, 40, () => _changeChannel(-1)),
          const SizedBox(width: 36),
          _ctrlBtn(_videoController?.value.isPlaying ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded,
              60, _togglePlay, primary: true),
          const SizedBox(width: 36),
          _ctrlBtn(Icons.skip_next_rounded, 40, () => _changeChannel(1)),
        ]),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          child: Row(children: [
            if (ps.fallbackCount > 0)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warningSubtle, borderRadius: BorderRadius.circular(4)),
                child: Text('Source ${ps.fallbackCount + 1}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))),
            const Spacer(),
            _bottomBtn(Icons.info_outline_rounded, 'EPG', _showEpg, () => setState(() => _showEpg = !_showEpg)),
            const SizedBox(width: 16),
            _bottomBtn(Icons.list_rounded, 'Channels', _showDrawer, () {
              setState(() { _showDrawer = !_showDrawer; _showControls = false; }); }),
            const SizedBox(width: 16),
            _bottomBtn(Icons.subtitles_outlined, 'Subs', false, () {}),
            const SizedBox(width: 16),
            _bottomBtn(Icons.settings_outlined, 'Quality', false, () {}),
          ])),
      ])),
    );
  }

  Widget _ctrlBtn(IconData icon, double sz, VoidCallback onTap, {bool primary = false}) => GestureDetector(
    onTap: onTap, child: Container(width: sz + 16, height: sz + 16,
      decoration: BoxDecoration(shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: primary ? 0.2 : 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: primary ? 0.3 : 0.15))),
      child: Icon(icon, color: Colors.white, size: sz * 0.55)));

  Widget _bottomBtn(IconData icon, String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: active ? AppColors.accentGold : Colors.white60),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: active
    ? AppColors.accentGold
    : Colors.white.withOpacity(0.5),
          fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
    ]));

  Widget _loadingOverlay(PlaybackSessionState s) => Container(color: Colors.black54,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 2.5)),
      const SizedBox(height: 16),
      Text(s.isSwitching ? 'Switching source...' : 'Connecting...',
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
      if (s.fallbackCount > 0)
        Padding(padding: const EdgeInsets.only(top: 8),
          child: Text('Trying backup source ${s.fallbackCount + 1}',
              style: const TextStyle(color: AppColors.warning, fontSize: 12))),
    ])));

  Widget _errorOverlay(PlaybackSessionState s) => Container(color: Colors.black87,
    child: Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.errorSubtle, shape: BoxShape.circle,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
          child: const Icon(Icons.signal_wifi_off_rounded, color: AppColors.error, size: 32)),
        const SizedBox(height: 20),
        const Text('Stream Unavailable', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(s.errorMessage ?? 'All sources failed', textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        if (s.fallbackCount > 0 || s.retryCount > 0) ...[
          const SizedBox(height: 8),
          Text('Tried ${s.fallbackCount + 1} sources · ${s.retryCount} retries',
              style: const TextStyle(color: Colors.white30, fontSize: 12)),
        ],
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: AppColors.textOnAccent),
            onPressed: () { _activeSourceUrl = null; _hasReportedError = false; _hasConfirmedPlaying = false;
              ref.read(playbackControllerProvider.notifier).retry(); }),
          const SizedBox(width: 12),
          OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24)), onPressed: _exit, child: const Text('Go Back')),
        ]),
      ]))));
}
