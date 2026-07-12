import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/video.dart';
import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';

class VideoDetailScreen extends StatefulWidget {
  final String bvid;

  const VideoDetailScreen({super.key, required this.bvid});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final BilibiliApi _api = BilibiliApi();
  Video? _video;
  List<Video> _relatedVideos = [];
  VideoPlayUrl? _playUrl;

  bool _loading = true;
  bool _loadingPlayUrl = false;
  String? _error;

  int _currentQuality = 64;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final video = await _api.getVideoDetail(widget.bvid);
      final related = await _api.getRelatedVideos(widget.bvid);
      if (!mounted) return;
      setState(() {
        _video = video;
        _relatedVideos = related;
        _loading = false;
      });
      if (video != null && video.cid != null) {
        _loadPlayUrl();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FunnyMessages.fromException(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadPlayUrl() async {
    if (_video?.cid == null) return;
    setState(() => _loadingPlayUrl = true);
    try {
      final url = await _api.getPlayUrl(
        widget.bvid,
        _video!.cid!,
        qn: _currentQuality,
      );
      if (!mounted) return;
      setState(() {
        _playUrl = url;
        _loadingPlayUrl = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlayUrl = false);
    }
  }

  Future<void> _openInBrowser() async {
    final url = 'https://www.bilibili.com/video/${widget.bvid}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(_video?.title ?? '视频详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadVideo)
              : _video == null
                  ? const EmptyView()
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlayer(),
                  const SizedBox(height: 16),
                  Text(
                    _video!.title ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${AppTheme.formatCount(_video!.view ?? 0)}播放',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${AppTheme.formatCount(_video!.danmaku ?? 0)}弹幕',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _video!.pubDateFormatted,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUpInfo(),
                  const SizedBox(height: 16),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildDesc(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: _buildRelated(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _video!.coverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _video!.coverUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            if (_loadingPlayUrl)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if (!_loadingPlayUrl && _playUrl == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline,
                        size: 64, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 12),
                    const Text('视频播放需要在浏览器中打开',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('在浏览器中打开'),
                    ),
                  ],
                ),
              ),
          ].whereType<Widget>().toList(),
        ),
      ),
    );
  }

  Widget _buildUpInfo() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accountColor(_video!.upName ?? 'up'),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _video!.upName?.characters.first ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _video!.upName ?? '未知UP主',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${AppTheme.formatCount(_video!.coin ?? 0)} 硬币',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('关注'),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.thumb_up_outlined, '点赞', _video!.like ?? 0),
          _buildStatItem(Icons.star_border, '收藏', _video!.favorite ?? 0),
          _buildStatItem(Icons.currency_lira_outlined, '投币', _video!.coin ?? 0),
          _buildStatItem(Icons.share, '分享', _video!.share ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 22, color: cs.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          AppTheme.formatCount(count),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
      ],
    );
  }

  Widget _buildDesc() {
    final cs = Theme.of(context).colorScheme;
    final desc = _video!.description?.trim();
    if (desc == null || desc.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('视频简介',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRelated() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            '相关视频',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _relatedVideos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final video = _relatedVideos[index];
              return _buildRelatedItem(video);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedItem(Video video) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoDetailScreen(bvid: video.bvid!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 120,
                height: 72,
                child: CachedNetworkImage(
                  imageUrl: video.coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: cs.surfaceContainerHighest),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.upName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                  Text(
                    '${AppTheme.formatCount(video.view ?? 0)}播放',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
