import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerWidget extends StatefulWidget {
  final String? videoUrl;
  final String? audioUrl;
  final String? coverUrl;
  final int durationMs;
  final bool autoPlay;
  final double speed;

  const PlayerWidget({
    super.key,
    this.videoUrl,
    this.audioUrl,
    this.coverUrl,
    this.durationMs = 0,
    this.autoPlay = true,
    this.speed = 1.0,
  });

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  Player? _player;
  VideoController? _controller;
  bool _initialized = false;
  bool _mediaKitReady = false;
  String? _error;

  static const _referer = 'https://www.bilibili.com';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  @override
  void initState() {
    super.initState();
    _initMediaKit();
  }

  Future<void> _initMediaKit() async {
    try {
      MediaKit.ensureInitialized();
      setState(() => _mediaKitReady = true);
      _createPlayer();
    } catch (e) {
      setState(() {
        _error = '播放器初始化失败: $e';
        _mediaKitReady = false;
      });
    }
  }

  void _createPlayer() {
    if (!_mediaKitReady ||
        widget.videoUrl == null ||
        widget.videoUrl!.isEmpty) {
      return;
    }
    try {
      _player = Player(
        configuration: PlayerConfiguration(
          title: 'CiliCili',
          bufferSize: 64 * 1024 * 1024,
        ),
      );
      _controller = VideoController(_player!);
      _open();
    } catch (e) {
      setState(() => _error = '播放器创建失败: $e');
    }
  }

  Future<void> _open() async {
    final player = _player;
    if (player == null ||
        widget.videoUrl == null ||
        widget.videoUrl!.isEmpty) {
      return;
    }
    try {
      final platform = player.platform;
      // B 站 DASH 视频/音频是分离的两条流：video.baseUrl 只有画面没有声音。
      // 必须通过 mpv 的 audio-files 属性把音频流挂上去，否则播放无声。
      if (platform is NativePlayer) {
        // 给所有 http 请求带上 Referer / UA，否则 B 站 CDN 会 403
        await platform.setProperty(
          'http-header-fields',
          'Referer: $_referer,User-Agent: $_ua',
        );
        if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
          // 先清空再设置，避免切集时叠加旧音轨
          await platform.setProperty('audio-files', '');
          await platform.setProperty('audio-files', widget.audioUrl!);
        }
      }

      await player.open(
        Media(
          widget.videoUrl!,
          httpHeaders: const {
            'Referer': _referer,
            'User-Agent': _ua,
          },
        ),
        play: widget.autoPlay,
      );
      await player.setRate(widget.speed);
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = '播放失败: $e');
    }
  }

  @override
  void didUpdateWidget(covariant PlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_player != null &&
        (oldWidget.videoUrl != widget.videoUrl ||
            oldWidget.audioUrl != widget.audioUrl)) {
      _open();
    }
    if (_player != null && oldWidget.speed != widget.speed) {
      _player!.setRate(widget.speed);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_initialized && widget.coverUrl != null)
            Image.network(
              widget.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_mediaKitReady && _controller != null && _error == null)
            Video(
              controller: _controller!,
              controls: AdaptiveVideoControls,
              fill: Colors.black,
            ),
          if (!_initialized && _error == null)
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
