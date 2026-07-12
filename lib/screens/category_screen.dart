import 'package:flutter/material.dart';

import '../models/video.dart';
import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';
import 'video_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final BilibiliApi _api = BilibiliApi();
  int _selectedRid = 0;
  List<Video> _videos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = _selectedRid == 0
          ? await _api.getRankVideos(rid: 0)
          : await _api.getRegionVideos(_selectedRid);
      if (!mounted) return;
      setState(() {
        _videos = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FunnyMessages.fromException(e);
        _loading = false;
      });
    }
  }

  void _selectCategory(int rid) {
    if (_selectedRid == rid) return;
    setState(() => _selectedRid = rid);
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = BilibiliApi.regions;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('分区',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Row(
        children: [
          _buildCategoryList(cs, regions),
          const VerticalDivider(width: 1),
          Expanded(child: _buildVideoGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryList(ColorScheme cs, Map<int, String> regions) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemCount: regions.length,
        itemBuilder: (context, index) {
          final rid = regions.keys.elementAt(index);
          final name = regions[rid]!;
          final selected = _selectedRid == rid;
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: InkWell(
              onTap: () => _selectCategory(rid),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoGrid() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadVideos);
    }
    if (_videos.isEmpty) return const EmptyView();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
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
