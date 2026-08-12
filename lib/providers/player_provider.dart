import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// 播放器控制器 - 简化版
class PlayerProvider extends ChangeNotifier {
  Player? _player;
  VideoController? _controller;
  String? _videoUrl;
  String? _audioUrl;
  bool _autoPlay = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  Player? get player => _player;
  VideoController? get controller => _controller;
  String? get videoUrl => _videoUrl;
  String? get audioUrl => _audioUrl;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  String? get error => _error;
  Duration get position => _position;
  Duration get duration => _duration;

  static const _referer = 'https://www.bilibili.com';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  void init() {}

  void dispose() {
    _player?.dispose();
    _player = null;
    _controller = null;
    super.dispose();
  }

  // 播放视频
  Future<void> play(String videoUrl, {String? audioUrl, bool autoPlay = false}) async {
    _videoUrl = videoUrl;
    _audioUrl = audioUrl;
    _autoPlay = autoPlay;
    _error = null;

    if (_player == null) {
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
        return;
      }
    }

    if (_player == null) return;

    try {
      final platform = _player!.platform;
      if (platform is NativePlayer) {
        await platform.setProperty(
          'http-header-fields',
          'Referer: $_referer,User-Agent: $_ua',
        );
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
      notifyListeners();
    } catch (e) {
      _error = '播放失败: $e';
      notifyListeners();
    }
  }

  void _setupListeners() {
    _player?.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _player?.stream.position.listen((pos) {
      _position = pos;
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
  }

  // 创建播放器 widget
  Widget buildPlayer({
    double width = double.infinity,
    double height = 200,
    Color backgroundColor = Colors.black,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _error == null)
            Video(
              controller: _controller!,
              fit: BoxFit.contain,
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
