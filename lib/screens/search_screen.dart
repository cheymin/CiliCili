import 'package:flutter/material.dart';

import '../models/video.dart';
import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';
import 'video_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BilibiliApi _api = BilibiliApi();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _hotWords = [];
  List<String> _history = [];
  List<Video> _results = [];

  bool _loadingHot = true;
  bool _searching = false;
  bool _hasSearched = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadHotWords();
    _loadHistory();
  }

  Future<void> _loadHotWords() async {
    try {
      final words = await _api.getHotSearchTerms();
      if (!mounted) return;
      setState(() {
        _hotWords = words.take(10).toList();
        _loadingHot = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHot = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _history = []);
  }

  Future<void> _doSearch(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    _searchController.text = kw;
    setState(() {
      _searching = true;
      _hasSearched = true;
      _searchError = null;
    });
    try {
      final list = await _api.searchVideos(kw);
      if (!mounted) return;
      setState(() {
        _results = list;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = FunnyMessages.fromException(e);
        _searching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('搜索',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
        child: Column(
          children: [
            _buildSearchBar(cs),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(Icons.search, color: cs.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '搜索视频、UP主、番剧...',
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
              ),
              onSubmitted: _doSearch,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear,
                  color: cs.onSurfaceVariant, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _hasSearched = false;
                  _results = [];
                });
              },
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _doSearch(_searchController.text),
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: const Text('搜索'),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_searching) return const LoadingView();
    if (_searchError != null) {
      return ErrorView(message: _searchError!,
          onRetry: () => _doSearch(_searchController.text));
    }
    if (_hasSearched) return _buildResults();
    return _buildSuggestions();
  }

  Widget _buildSuggestions() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hotWords.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
              child: Row(
                children: [
                  Icon(Icons.whatshot, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '热门搜索',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _hotWords.asMap().entries.map((e) {
                final index = e.key;
                final word = e.value;
                return InkWell(
                  onTap: () => _doSearch(word),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index < 3)
                          Text('${index + 1} ',
                              style: TextStyle(
                                color: index == 0
                                    ? Colors.red
                                    : index == 1
                                        ? Colors.orange
                                        : Colors.amber,
                                fontWeight: FontWeight.bold,
                              )),
                        Text(word, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (_loadingHot) const LoadingView(text: '加载热搜中...'),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const EmptyView(
        text: '没找到相关视频，换个关键词试试？',
        icon: Icons.search_off,
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final video = _results[index];
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
