import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// 播放器控制器，移植自 PiliPlus PlPlayerController 的核心逻辑
/// - DASH 音视频分离处理（通过 mpv audio-files 属性）
/// - 播放状态管理（play/pause/seek/speed/volume）
/// - 全屏/非全屏切换
/// - 弹幕支持预留接口
class PlayerProvider extends ChangeNotifier {
  Player? _player;
  VideoController? _controller;
  String? _videoUrl;
  String? _audioUrl;
  bool _autoPlay = false;
  bool _isFullscreen = false;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _error;

  // 事件监听
  final List<Function(Duration pos)> _positionListeners = [];
  final List<Function(bool playing)> _statusListeners = [];

  // Getters
  Player? get player => _player;
  VideoController? get controller => _controller;
  String? get videoUrl => _videoUrl;
  String? get audioUrl => _audioUrl;
  bool get isFullscreen => _isFullscreen;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  String? get error => _error;

  // 静态实例（单例模式，防止内存泄漏）
  static PlayerProvider? _instance;
  static PlayerProvider? get instance => _instance;

  static const _referer = 'https://www.bilibili.com';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  void init() {
    if (_instance == null) {
      _instance = this;
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
    _controller = null;
    _instance = null;
    super.dispose();
  }

  // 初始化播放器
  Future<void> initPlayer() async {
    if (_player != null) return;
    try {
      MediaKit.ensureInitialized();
      _player = Player(
        configuration: PlayerConfiguration(
          title: 'CiliCili',
          bufferSize: 64 * 1024 * 1024,
        ),
      );
      _controller = VideoController(_player!);
      _setupListeners();
      notifyListeners();
    } catch (e) {
      _error = '播放器初始化失败: $e';
      notifyListeners();
    }
  }

  void _setupListeners() {
    _player?.stream.playing.listen((playing) {
      _isPlaying = playing;
      for (var listener in _statusListeners) listener(playing);
      notifyListeners();
    });

    _player?.stream.position.listen((pos) {
      _position = pos;
      for (var listener in _positionListeners) listener(pos);
      notifyListeners();
    });

    _player?.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player?.stream.buffering.listen((buffering) {
      _isBuffering = buffering;
      notifyListeners();
    });

    _player?.stream.error.listen((event) {
      if (event.startsWith('Failed to open') ||
          event.startsWith('Can not open')) {
        _error = '视频加载失败，请检查网络';
      }
      notifyListeners();
    });
  }

  // 播放视频
  Future<void> play(String videoUrl, {String? audioUrl, bool autoPlay = false}) async {
    _videoUrl = videoUrl;
    _audioUrl = audioUrl;
    _autoPlay = autoPlay;
    _error = null;

    if (_player == null) {
      await initPlayer();
    }

    if (_player == null) return;

    try {
      final platform = _player!.platform;
      if (platform is NativePlayer) {
        // 设置请求头（Referer + UA）
        await platform.setProperty(
          'http-header-fields',
          'Referer: $_referer,User-Agent: $_ua',
        );

        // 处理 DASH 音视频分离（关键修复）
        if (audioUrl != null && audioUrl.isNotEmpty) {
          await platform.setProperty('audio-files', '');
          await platform.setProperty('audio-files', audioUrl);
        }
      }

      await _player!.open(
        Media(
          videoUrl,
          httpHeaders: const {
            'Referer': _referer,
            'User-Agent': _ua,
          },
        ),
        play: autoPlay,
      );

      await _player!.setRate(_playbackSpeed);
      notifyListeners();
    } catch (e) {
      _error = '播放失败: $e';
      notifyListeners();
    }
  }

  // 暂停
  Future<void> pause() async {
    await _player?.pause();
  }

  // 继续播放
  Future<void> resume() async {
    await _player?.play();
  }

  // 切换播放/暂停
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  // 跳转
  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  // 设置倍速
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player?.setRate(speed);
    notifyListeners();
  }

  // 设置音量
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player?.setVolume(volume * 100);
    notifyListeners();
  }

  // 切换全屏
  Future<void> toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  // 添加监听
  void addPositionListener(Function(Duration pos) listener) {
    _positionListeners.add(listener);
  }

  void removePositionListener(Function(Duration pos) listener) {
    _positionListeners.remove(listener);
  }

  void addStatusListener(Function(bool playing) listener) {
    _statusListeners.add(listener);
  }

  void removeStatusListener(Function(bool playing) listener) {
    _statusListeners.remove(listener);
  }

  // 创建播放器 widget
  Widget buildPlayer({
    double width = double.infinity,
    double height = 200,
    Color backgroundColor = Colors.black,
    Widget? placeholder,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 播放器主体
          if (_controller != null && _error == null)
            Video(
              controller: _controller!,
              color: Colors.black,
              // 使用默认控制条
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => play(_videoUrl ?? '', audioUrl: _audioUrl),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          else if (placeholder != null)
            placeholder,
          // 加载中
          if (_isBuffering && _error == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  // 自定义控制条（参考 PiliPlus 样式）
  Widget get _buildControls => VideoControls(
        onTogglePlay: togglePlay,
        onSeek: seek,
        position: _position,
        duration: _duration,
        volume: _volume,
        onVolumeChange: setVolume,
        playbackSpeed: _playbackSpeed,
        onSpeedChange: setPlaybackSpeed,
        onFullscreenToggle: toggleFullscreen,
        isFullscreen: _isFullscreen,
      );
}

/// 控制条组件（参考 PiliPlus player_bar.dart）
class VideoControls extends StatefulWidget {
  final VoidCallback onTogglePlay;
  final Function(Duration) onSeek;
  final Duration position;
  final Duration duration;
  final double volume;
  final Function(double) onVolumeChange;
  final double playbackSpeed;
  final Function(double) onSpeedChange;
  final VoidCallback onFullscreenToggle;
  final bool isFullscreen;

  const VideoControls({
    super.key,
    required this.onTogglePlay,
    required this.onSeek,
    required this.position,
    required this.duration,
    required this.volume,
    required this.onVolumeChange,
    required this.playbackSpeed,
    required this.onSpeedChange,
    required this.onFullscreenToggle,
    required this.isFullscreen,
  });

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _showControlsManually() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _showControlsManually,
      onPanStart: (_) => _hideTimer?.cancel(),
      onPanEnd: (_) => _startHideTimer(),
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 顶部工具栏
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    // 全屏按钮
                    IconButton(
                      icon: Icon(
                        widget.isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: widget.onFullscreenToggle,
                    ),
                  ],
                ),
              ),
              // 中间播放按钮
              IconButton(
                icon: Icon(
                  widget.onTogglePlay == widget.onTogglePlay && widget.position == widget.position // 检查是否要显示暂停
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: widget.onTogglePlay,
              ),
              // 底部控制条
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // 进度条
                    Slider(
                      value: widget.position.inSeconds.toDouble().clamp(
                          0.0, widget.duration.inSeconds.toDouble()),
                      max: widget.duration.inSeconds.toDouble(),
                      onChanged: (v) {
                        widget.onSeek(Duration(seconds: v.toInt()));
                      },
                    ),
                    // 时间和倍速
                    Row(
                      children: [
                        Text(
                          _formatDuration(widget.position),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        const Text('/',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        Text(
                          _formatDuration(widget.duration),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        const Spacer(),
                        // 倍速按钮
                        PopupMenuButton<double>(
                          icon: const Icon(Icons.speed,
                              color: Colors.white, size: 18),
                          itemBuilder: (context) => [
                            for (final speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                              PopupMenuItem(
                                value: speed,
                                child: Text(''$speed x'',
                                    style: TextStyle(
                                        color: speed ==
                                                widget.playbackSpeed
                                            ? cs.primary
                                            : Colors.white)),
                              ),
                          ],
                          onSelected: widget.onSpeedChange,
                        ),
                        const SizedBox(width: 8),
                        // 音量
                        IconButton(
                          icon: const Icon(Icons.volume_up,
                              color: Colors.white, size: 18),
                          onPressed: () {},
                        ),
                        SizedBox(
                          width: 80,
                          child: Slider(
                            value: widget.volume,
                            onChanged: widget.onVolumeChange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
