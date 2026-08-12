import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../services/bilibili_api.dart';
import '../utils/theme.dart';
import '../models/video.dart';
import 'video_detail_screen.dart';

/// 简化版视频详情页（保留原有结构，适配新播放器）
class VideoDetailScreenLegacy extends StatefulWidget {
  final Video video;

  const VideoDetailScreenLegacy({super.key, required this.video});

  @override
  State<VideoDetailScreenLegacy> createState() =>
      _VideoDetailScreenLegacyState();
}

class _VideoDetailScreenLegacyState extends State<VideoDetailScreenLegacy> {
  final _api = BilibiliApi();
  VideoPlayUrl? _playUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayUrl();
  }

  Future<void> _loadPlayUrl() async {
    try {
      final url = await _api.getPlayUrl(
        aid: widget.video.aid,
        cid: widget.video.cid,
        fnval: 16 | 64,
      );
      setState(() {
        _playUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // 播放器
                Expanded(
                  flex: 3,
                  child: ChangeNotifierProvider(
                    create: (_) => PlayerProvider()..init(),
                    child: _PlayerWithControls(
                      playUrl: _playUrl,
                      video: widget.video,
                    ),
                  ),
                ),
                // 视频信息
                Expanded(
                  flex: 2,
                  child: Container(
                    color: cs.surface,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title ?? '无标题',
                          style: cs.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: widget.video.owner?.faceUrl !=
                                      null
                                  ? NetworkImage(widget.video.owner!.faceUrl!)
                                  : null,
                              child: widget.video.owner?.faceUrl == null
                                  ? const Icon(Icons.person, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.video.upName,
                                style: cs.textTheme.bodyMedium,
                              ),
                            ),
                            _StatChip(
                                icon: Icons.play_arrow,
                                count: widget.video.view),
                            _StatChip(
                                icon: Icons.favorite,
                                count: widget.video.like),
                            _StatChip(
                                icon: Icons.chat,
                                count: widget.video.danmaku),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          widget.video.description ?? '',
                          style: cs.textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PlayerWithControls extends StatefulWidget {
  final VideoPlayUrl? playUrl;
  final Video video;

  const _PlayerWithControls({this.playUrl, required this.video});

  @override
  State<_PlayerWithControls> createState() => _PlayerWithControlsState();
}

class _PlayerWithControlsState extends State<_PlayerWithControls> {
  bool _hasPlayed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.playUrl == null ||
        widget.playUrl!.video == null ||
        widget.playUrl!.video!.baseUrl.isEmpty) {
      return const Center(
        child: Text('无法获取播放地址',
            style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        // 播放器
        ChangeNotifierBuilder<PlayerProvider>(
          builder: (context, player) {
            if (!_hasPlayed) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 64),
                    onPressed: () {
                      setState(() => _hasPlayed = true);
                      player.play(
                        widget.playUrl!.video!.baseUrl,
                        audioUrl: widget.playUrl?.audio?.baseUrl,
                        autoPlay: true,
                      );
                    },
                  ),
                ),
              );
            }
            return player.buildPlayer(
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int? count;

  const _StatChip({required this.icon, this.count});

  @override
  Widget build(BuildContext context) {
    if (count == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            AppTheme.formatCount(count!),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// Helper extension
extension ChangeNotifierBuilderExt on Widget {
  Widget wrapProvider() => this;
}
