import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../utils/theme.dart';
import '../utils/style.dart';
import '../models/video.dart';
import '../services/bilibili_api.dart';

/// 视频详情页 - 简化版
class VideoDetailScreen extends StatefulWidget {
  final String bvid;
  final int? cid;

  const VideoDetailScreen({
    super.key,
    required this.bvid,
    this.cid,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  Video? _video;
  bool _isLoading = true;
  String? _error;
  final _api = BilibiliApi();
  String? _videoUrl;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVideo();
    _loadPlayUrl();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getVideoDetail(widget.bvid);
      setState(() {
        _video = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlayUrl() async {
    if (_video == null || _video!.cid == null) return;
    try {
      final playUrl = await _api.getPlayUrl(widget.bvid, _video!.cid!);
      setState(() {
        _videoUrl = playUrl?.video?.baseUrl;
        _audioUrl = playUrl?.audio?.baseUrl;
      });
    } catch (e) {
      debugPrint('加载播放地址失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('播放视频',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVideo,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 播放器区域
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: _videoUrl != null
                              ? ChangeNotifierProvider(
                                  create: (_) => PlayerProvider()..init(),
                                  child: Builder(
                                    builder: (context) {
                                      final player =
                                          context.read<PlayerProvider>();
                                      player.play(
                                        _videoUrl!,
                                        audioUrl: _audioUrl,
                                        autoPlay: true,
                                      );
                                      return player.buildPlayer();
                                    },
                                  ),
                                )
                              : const CircularProgressIndicator(
                                  color: Colors.white),
                        ),
                      ),
                    ),
                    // 视频信息
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _video!.title ?? '无标题',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: _video!.face != null
                                      ? NetworkImage(_video!.face!)
                                      : null,
                                  child: _video!.face == null
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _video!.name ?? '未知UP',
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _statChip(Icons.play_arrow, _video!.view),
                                _statChip(Icons.favorite, _video!.like),
                                _statChip(Icons.chat, _video!.danmaku),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _video!.desc ?? '',
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_video!.pubdate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '发布于 ${_video!.pubdate != null ? DateTime.fromMillisecondsSinceEpoch(_video!.pubdate! * 1000).toString().split(' ')[0] : ""}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text('简介',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(_video!.desc ?? '暂无简介'),
                            const SizedBox(height: 24),
                            const Text('相关视频',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildRelatedVideos(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _statChip(IconData icon, int? count) {
    if (count == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            '${(count / 10000).toStringAsFixed(1)}万',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideos() {
    final relatedVideos = List.generate(
      3,
      (i) => Video(
        bvid: 'BV1xx4y1x${i.toString().padLeft(3, '0')}',
        title: '相关视频 $i',
        pic: 'https://i0.hdslb.com/bfs/archive/${i + 1}.jpg',
        duration: 60 * (i + 1),
        view: (i + 1) * 10000,
        like: (i + 1) * 500,
        danmaku: (i + 1) * 100,
        pubdate: DateTime.now().millisecondsSinceEpoch ~/ 1000 - i * 86400,
        name: '测试UP主$i',
        face: 'https://i0.hdslb.com/bfs/face/${i + 1}.jpg',
        cid: 123456 + i,
      ),
    );

    return Column(
      children: relatedVideos.map((v) {
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              v.pic ?? '',
              width: 80,
              height: 45,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.video_library, size: 45),
            ),
          ),
          title: Text(
            v.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            '${v.name} · ${AppTheme.formatCount(v.view ?? 0)}播放',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        );
      }).toList(),
    );
  }
}
