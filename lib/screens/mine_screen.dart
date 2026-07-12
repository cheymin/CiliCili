import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/video.dart';
import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';
import 'login_screen.dart';
import 'video_detail_screen.dart';

class MineScreen extends StatefulWidget {
  const MineScreen({super.key});

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen>
    with SingleTickerProviderStateMixin {
  final BilibiliApi _api = BilibiliApi();

  Map<String, dynamic>? _userInfo;
  List<Video> _historyVideos = [];
  List<Video> _favVideos = [];
  List<Video> _dynamicVideos = [];

  bool _loadingUser = true;
  bool _loadingHistory = false;
  bool _loadingFav = false;
  bool _loadingDynamic = false;

  String? _userError;

  late final TabController _tabController;
  final _tabs = const ['历史记录', '收藏夹', '动态'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserInfo();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final index = _tabController.index;
      if (index == 0 && _historyVideos.isEmpty && !_loadingHistory) {
        _loadHistory();
      } else if (index == 1 && _favVideos.isEmpty && !_loadingFav) {
        _loadFav();
      } else if (index == 2 && _dynamicVideos.isEmpty && !_loadingDynamic) {
        _loadDynamic();
      }
    }
  }

  Future<void> _loadUserInfo() async {
    if (!_api.isLoggedIn) {
      setState(() => _loadingUser = false);
      return;
    }
    setState(() {
      _loadingUser = true;
      _userError = null;
    });
    try {
      final info = await _api.getUserInfo();
      if (!mounted) return;
      setState(() {
        _userInfo = info;
        _loadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userError = FunnyMessages.fromException(e);
        _loadingUser = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (!_api.isLoggedIn) return;
    setState(() => _loadingHistory = true);
    try {
      final list = await _api.getHistory(pageSize: 30);
      if (!mounted) return;
      setState(() {
        _historyVideos = list;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadFav() async {
    if (!_api.isLoggedIn) return;
    setState(() => _loadingFav = true);
    try {
      final mid = _userInfo?['mid'] as int?;
      if (mid == null) {
        setState(() => _loadingFav = false);
        return;
      }
      final favList = await _api.getFavList(mid);
      if (favList.isNotEmpty) {
        final mediaId = favList[0]['id'] as int?;
        if (mediaId != null) {
          final videos = await _api.getFavVideos(mediaId);
          if (mounted) {
            setState(() {
              _favVideos = videos;
              _loadingFav = false;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _loadingFav = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFav = false);
    }
  }

  Future<void> _loadDynamic() async {
    if (!_api.isLoggedIn) return;
    setState(() => _loadingDynamic = true);
    try {
      final list = await _api.getFollowDynamic();
      if (!mounted) return;
      setState(() {
        _dynamicVideos = list;
        _loadingDynamic = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDynamic = false);
    }
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(onLoginSuccess: () {}),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _loadUserInfo();
      _historyVideos = [];
      _favVideos = [];
      _dynamicVideos = [];
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _api.logout();
      if (!mounted) return;
      setState(() {
        _userInfo = null;
        _historyVideos = [];
        _favVideos = [];
        _dynamicVideos = [];
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('我的',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildUserCard(cs),
          if (_api.isLoggedIn && _userInfo != null)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          Expanded(
            child: _api.isLoggedIn
                ? _buildLoggedInBody()
                : _buildNotLoggedIn(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(ColorScheme cs) {
    final isLoggedIn = _api.isLoggedIn;
    final uname = _userInfo?['uname'] as String?;
    final face = _userInfo?['face'] as String?;
    final level = _userInfo?['level_info']?['current_level'] as int?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surface,
              border: Border.all(color: cs.surface, width: 3),
            ),
            child: isLoggedIn && face != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: face,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _buildDefaultAvatar(cs, uname),
                    ),
                  )
                : _buildDefaultAvatar(cs, uname),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _loadingUser
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )
                : isLoggedIn
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uname ?? '用户',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (level != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'LV$level',
                                    style: TextStyle(
                                      color: cs.onPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                'UID: ${_userInfo?['mid'] ?? '-'}',
                                style: TextStyle(
                                  color: cs.onPrimary.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStat(cs,
                                  '${AppTheme.formatCount((_userInfo?['following'] as int?) ?? 0)}',
                                  '关注'),
                              const SizedBox(width: 16),
                              _buildStat(cs,
                                  '${AppTheme.formatCount((_userInfo?['follower'] as int?) ?? 0)}',
                                  '粉丝'),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '未登录',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '登录后同步你的数据',
                            style: TextStyle(
                              color: cs.onPrimary.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: _handleLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: cs.primary,
                            ),
                            child: const Text('立即登录'),
                          ),
                        ],
                      ),
          ),
          if (isLoggedIn)
            TextButton(
              onPressed: _handleLogout,
              child: Text(
                '退出',
                style: TextStyle(color: cs.onPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(ColorScheme cs, String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: TextStyle(
            color: cs.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: cs.onPrimary.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ColorScheme cs, String? name) {
    return Center(
      child: Text(
        name?.characters.first ?? '?',
        style: TextStyle(
          color: cs.primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 72,
            color: cs.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '登录后查看你的数据',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _handleLogin,
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInBody() {
    if (_userError != null) {
      return ErrorView(message: _userError!, onRetry: _loadUserInfo);
    }
    if (_loadingUser && _userInfo == null) {
      return const LoadingView();
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildVideoGrid(_historyVideos, _loadingHistory, _loadHistory,
            '还没有观看历史哦'),
        _buildVideoGrid(_favVideos, _loadingFav, _loadFav, '还没有收藏的视频'),
        _buildVideoGrid(
            _dynamicVideos, _loadingDynamic, _loadDynamic, '还没有动态内容'),
      ],
    );
  }

  Widget _buildVideoGrid(
      List<Video> videos, bool loading, VoidCallback onRefresh, String emptyText) {
    if (loading) return const LoadingView();
    if (videos.isEmpty) {
      return EmptyView(text: emptyText, icon: Icons.inbox_outlined);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoCard(
          video: video,
          onTap: () => _openVideo(video),
        );
      },
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
