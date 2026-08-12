import 'package:flutter/material.dart';

import '../models/video.dart';
import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../utils/grid.dart';
import '../utils/style.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';
import 'video_detail_screen.dart';
import 'video_detail_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final BilibiliApi _api = BilibiliApi();

  List<Video> _recommendVideos = [];
  List<Video> _popularVideos = [];
  List<Video> _rankVideos = [];

  bool _loadingRecommend = true;
  bool _loadingPopular = true;
  bool _loadingRank = true;

  String? _recommendError;
  String? _popularError;
  String? _rankError;

  final _tabs = const ['推荐', '热门', '排行榜'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadRecommend();
    _loadPopular();
    _loadRank();
  }

  Future<void> _loadRecommend() async {
    setState(() {
      _loadingRecommend = true;
      _recommendError = null;
    });
    try {
      final list = await _api.getRecommendVideos(pageSize: 24);
      if (!mounted) return;
      setState(() {
        _recommendVideos = list;
        _loadingRecommend = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recommendError = FunnyMessages.fromException(e);
        _loadingRecommend = false;
      });
    }
  }

  Future<void> _loadPopular() async {
    setState(() {
      _loadingPopular = true;
      _popularError = null;
    });
    try {
      final list = await _api.getPopularVideos(pageSize: 24);
      if (!mounted) return;
      setState(() {
        _popularVideos = list;
        _loadingPopular = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _popularError = FunnyMessages.fromException(e);
        _loadingPopular = false;
      });
    }
  }

  Future<void> _loadRank() async {
    setState(() {
      _loadingRank = true;
      _rankError = null;
    });
    try {
      final list = await _api.getRankVideos();
      if (!mounted) return;
      setState(() {
        _rankVideos = list;
        _loadingRank = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rankError = FunnyMessages.fromException(e);
        _loadingRank = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('CiliCili',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideoGrid(_recommendVideos, _loadingRecommend, _recommendError,
              _loadRecommend),
          _buildVideoGrid(
              _popularVideos, _loadingPopular, _popularError, _loadPopular),
          _buildVideoGrid(_rankVideos, _loadingRank, _rankError, _loadRank),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(List<Video> videos, bool loading, String? error,
      VoidCallback onRetry) {
    if (loading) return const LoadingView();
    if (error != null) return ErrorView(message: error, onRetry: onRetry);
    if (videos.isEmpty) return const EmptyView();

    // 网格布局移植自 PiliPlus：封面按 16:10 计算，文字区固定加 62px。
    // 列数随宽度自适应——手机 2 列 / 平板 3~4 列 / 电视 5~6 列。
    final textScale = MediaQuery.textScalerOf(context).scale(62);
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace, vertical: Style.cardSpace),
        gridDelegate: SliverGridDelegateWithExtentAndRatio(
          maxCrossAxisExtent: Style.recommendCardWidth,
          mainAxisSpacing: Style.cardSpace,
          crossAxisSpacing: Style.cardSpace,
          childAspectRatio: Style.aspectRatio,
          mainAxisExtent: textScale,
        ),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return VideoCard(
            video: video,
            onTap: () => _openVideo(video),
          );
        },
      ),
    );
  }

  void _openVideo(Video video) {
    if (video.bvid == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoDetailScreen(bvid: video.bvid!),
      ),
    );
  }
}
