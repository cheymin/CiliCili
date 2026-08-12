import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../utils/theme.dart';
import '../utils/style.dart';
import '../models/video.dart';
import '../services/bilibili_api.dart';

/// 视频详情页，移植自 PiliPlus VideoDetailPageV
/// 布局：顶部播放器 + 下方 TabBar（简介/评论）
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVideo();
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

  Future<void> _playVideo() async {
    if (_video == null) return;

    try {
      final playUrl = await _api.getPlayUrl(
        aid: _video!.aid,
        cid: widget.cid ?? _video!.cid,
        fnval: 16 | 64, // DASH + 高码率
      );

      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.play(
        playUrl.video?.baseUrl ?? '',
        audioUrl: playUrl.audio?.baseUrl,
        autoPlay: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
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
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 播放器区域（16:9）
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ChangeNotifierProvider(
            create: (_) => PlayerProvider()..init(),
            child: _VideoPlayerWrapper(video: _video!),
          ),
        ),
        // 视频信息
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                _video!.title ?? '无标题',
                style: cs.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // UP 信息和统计数据
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: _video!.owner?.faceUrl != null
                        ? NetworkImage(_video!.owner!.faceUrl!)
                        : null,
                    child: _video!.owner?.faceUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _video!.upName,
                      style: cs.textTheme.bodyMedium,
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
              // 简介
              Text(
                _video!.description ?? '',
                style: cs.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_video!.pubDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  '发布于 ${AppTheme.formatDate(_video!.pubDate!)}',
                  style: cs.textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '简介'),
            Tab(text: '评论'),
          ],
        ),
        // Tab 内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIntroTab(),
              _buildCommentTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, int? count) {
    if (count == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            '${(count / 10000).toStringAsFixed(1)}万',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildIntroTab() {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 简介
          if (_video?.description != null && _video!.description!.isNotEmpty)
            Text(
              _video!.description!,
              style: cs.textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          // 标签
          if ((_video?.tagList?.isNotEmpty ?? false))
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _video!.tagList!
                  .map((t) => Chip(
                        label: Text(t),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 16),
          // 分区
          Text(
            '分区: ${_video?.typeName ?? '未知'}',
            style: cs.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // 相关视频
          const Text(
            '相关视频',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRelatedVideos(),
        ],
      ),
    );
  }

  Widget _buildRelatedVideos() {
    // 模拟相关视频数据（实际应从 API 获取）
    final relatedVideos = List.generate(
      5,
      (i) => Video(
        bvid: 'BV1xx4y1x${i.toString().padLeft(3, '0')}',
        title: '相关视频 $i - 这是一个测试视频标题',
        coverUrl: 'https://i0.hdslb.com/bfs/archive/${i + 1}.jpg',
        duration: 60 * (i + 1),
        view: (i + 1) * 10000,
        like: (i + 1) * 500,
        danmaku: (i + 1) * 100,
        pubDate: DateTime.now().subtract(Duration(days: i)),
        owner: User(
          mid: i + 1,
          name: '测试UP主$i',
          faceUrl: 'https://i0.hdslb.com/bfs/face/${i + 1}.jpg',
        ),
        tagList: ['测试', '相关视频'],
      ),
    );

    return Column(
      children: relatedVideos.map((v) {
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              v.coverUrl,
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
            '${v.upName} · ${AppTheme.formatCount(v.view ?? 0)}播放',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            // TODO: 跳转到新视频
          },
        );
      }).toList(),
    );
  }

  Widget _buildCommentTab() {
    return const Center(
      child: Text('评论功能开发中...', style: TextStyle(color: Colors.grey)),
    );
  }
}

/// 播放器包装组件（处理生命周期）
class _VideoPlayerWrapper extends StatefulWidget {
  final Video video;

  const _VideoPlayerWrapper({required this.video});

  @override
  State<_VideoPlayerWrapper> createState() => _VideoPlayerWrapperState();
}

class _VideoPlayerWrapperState extends State<_VideoPlayerWrapper> {
  bool _hasPlayed = false;
  String? _videoUrl;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _loadVideoUrl();
  }

  Future<void> _loadVideoUrl() async {
    try {
      final api = BilibiliApi();
      final playUrl = await api.getPlayUrl(
        aid: widget.video.aid,
        cid: widget.video.cid,
        fnval: 16 | 64,
      );
      setState(() {
        _videoUrl = playUrl.video?.baseUrl;
        _audioUrl = playUrl.audio?.baseUrl;
      });
    } catch (e) {
      debugPrint('加载播放地址失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 播放器
        ChangeNotifierBuilder<PlayerProvider>(
          builder: (context, player) {
            return player.buildPlayer(
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
        // 点击播放覆盖层
        if (!_hasPlayed && _videoUrl != null)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _hasPlayed = true);
                  final player = context.read<PlayerProvider>();
                  player.play(_videoUrl!, audioUrl: _audioUrl, autoPlay: true);
                },
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ChangeNotifierBuilder 辅助组件
class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext, T) builder;

  const ChangeNotifierBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(builder: (context, notifier, _) => builder(context, notifier));
  }
}
