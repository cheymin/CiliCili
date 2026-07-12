import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/danmaku.dart';
import '../models/video.dart';
import '../utils/storage.dart';

/// 哔哩哔哩 API 服务
class BilibiliApi {
  BilibiliApi();

  static const String baseUrl = 'https://api.bilibili.com';
  static const String passportBaseUrl = 'https://passport.bilibili.com';
  static const String searchBaseUrl = 'https://s.search.bilibili.com';

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String referer = 'https://www.bilibili.com/';

  /// B 站分区（tid -> 分区名）
  static const Map<int, String> regions = {
    0: '全站',
    1: '动画',
    3: '音乐',
    4: '游戏',
    5: '娱乐',
    36: '知识',
    188: '科技',
    160: '生活',
    211: '美食',
    181: '影视',
    168: '国创',
    13: '番剧',
  };

  /// 构造请求头（带 Cookie）
  Map<String, String> get _headers {
    final cookie = _buildCookie();
    return {
      'User-Agent': userAgent,
      'Referer': referer,
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  /// 拼接 Cookie 字符串（SESSDATA / buvid3 / bili_jct / DedeUserID）
  String _buildCookie() {
    final parts = <String>[];
    final sessdata = StorageService.sessdata;
    if (sessdata != null && sessdata.isNotEmpty) {
      parts.add('SESSDATA=$sessdata');
    }
    final buvid3 = StorageService.buvid3;
    if (buvid3 != null && buvid3.isNotEmpty) {
      parts.add('buvid3=$buvid3');
    }
    final jct = StorageService.biliJct;
    if (jct != null && jct.isNotEmpty) {
      parts.add('bili_jct=$jct');
    }
    final uid = StorageService.dedeUserId;
    if (uid != null && uid.isNotEmpty) {
      parts.add('DedeUserID=$uid');
    }
    return parts.join('; ');
  }

  /// 发送 GET 请求并解析 JSON
  Future<Map<String, dynamic>?> _getJson(
    String url, {
    Map<String, String>? params,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 将原始 JSON 包装成 ApiResponse（data 视为 Map）
  ApiResponse<Map<String, dynamic>> _wrap(Map<String, dynamic>? json) {
    if (json == null) {
      return ApiResponse<Map<String, dynamic>>(code: -1, message: '请求失败');
    }
    return ApiResponse.fromJson(
      json,
      (d) => d is Map ? Map<String, dynamic>.from(d) : null,
    );
  }

  // ============ 推荐 / 热门 / 排行 / 分区 ============

  /// 获取推荐视频流
  Future<List<Video>> getRecommendVideos({int page = 1, int pageSize = 20}) async {
    final json = await _getJson(
      '$baseUrl/x/web-interface/index/top/feed/rcmd',
      params: {
        'fresh': '4',
        'ps': pageSize.toString(),
        'fresh_idx': page.toString(),
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final items = data['item'] ?? data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => Video.fromRecommendJson(e))
        .where((v) => v.bvid?.isNotEmpty == true)
        .toList();
  }

  /// 获取热门视频
  Future<List<Video>> getPopularVideos({int page = 1, int pageSize = 20}) async {
    final json = await _getJson(
      '$baseUrl/x/web-interface/popular',
      params: {
        'pn': page.toString(),
        'ps': pageSize.toString(),
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final list = data['list'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Video.fromJson(e))
        .toList();
  }

  /// 获取分区排行榜
  Future<List<Video>> getRankVideos({int rid = 0}) async {
    final json = await _getJson(
      '$baseUrl/x/web-interface/ranking/v2',
      params: {
        'rid': rid.toString(),
        'type': 'all',
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final list = data['list'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Video.fromJson(e))
        .toList();
  }

  /// 获取分区最新视频
  Future<List<Video>> getRegionVideos(int rid, {int page = 1}) async {
    final json = await _getJson(
      '$baseUrl/x/web-interface/dynamic/region',
      params: {
        'rid': rid.toString(),
        'pn': page.toString(),
        'ps': '20',
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final archives = data['archives'];
    if (archives is! List) return const [];
    return archives
        .whereType<Map<String, dynamic>>()
        .map((e) => Video.fromJson(e))
        .toList();
  }

  // ============ 视频详情 / 播放 ============

  /// 获取视频详情
  Future<Video?> getVideoDetail(String bvid) async {
    final json = await _getJson(
      '$baseUrl/x/web-interface/view',
      params: {'bvid': bvid},
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return null;
    return Video.fromJson(data);
  }

  /// 获取播放地址（DASH）
  Future<VideoPlayUrl?> getPlayUrl(
    String bvid,
    int cid, {
    int qn = 80,
    int fnval = 16,
  }) async {
    final json = await _getJson(
      '$baseUrl/x/player/playurl',
      params: {
        'bvid': bvid,
        'cid': cid.toString(),
        'qn': qn.toString(),
        'fnval': fnval.toString(),
        'fourk': '1',
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return null;
    return VideoPlayUrl.fromJson(data);
  }

  /// 获取相关视频
  Future<List<Video>> getRelatedVideos(String bvid) async {
    // related 接口的 data 是数组而非对象，故不走 _wrap
    final json = await _getJson(
      '$baseUrl/x/web-interface/archive/related',
      params: {'bvid': bvid},
    );
    if (json == null || json['code'] != 0) return const [];
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => Video.fromJson(e))
        .toList();
  }

  // ============ 搜索 ============

  /// 搜索视频
  Future<List<Video>> searchVideos(String keyword, {int page = 1}) async {
    final json = await _getJson(
      '$baseUrl/x/web-interface/search/type',
      params: {
        'keyword': keyword,
        'search_type': 'video',
        'page': page.toString(),
        'order': 'totalrank',
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final result = data['result'];
    if (result is! List) return const [];
    return result
        .whereType<Map<String, dynamic>>()
        .map((e) => Video(
              bvid: e['bvid'] as String?,
              aid: _parseInt(e['aid']),
              title: _stripHtml(e['title'] as String? ?? ''),
              pic: e['pic'] as String?,
              name: e['author'] as String?,
              mid: _parseInt(e['mid']),
              view: _parseInt(e['play']),
              danmaku: _parseInt(e['video_review']),
              favorite: _parseInt(e['favorites']),
              duration: _parseInt(e['duration']),
              pubdate: _parseInt(e['pubdate']),
            ))
        .where((v) => v.bvid?.isNotEmpty == true)
        .toList();
  }

  /// 获取热搜词
  Future<List<String>> getHotSearchTerms() async {
    final json = await _getJson('$searchBaseUrl/main/hotword');
    if (json == null || json['code'] != 0) return const [];
    // 兼容 {list:[...]} 与 {data:{list:[...]}} 两种结构
    final list = json['list'] ?? (json['data'] is Map ? json['data']['list'] : null);
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) =>
            (e['keyword'] as String?) ??
            (e['show_name'] as String?) ??
            (e['name'] as String?) ??
            '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ============ 弹幕 ============

  /// 获取弹幕（XML 格式，list.so）
  Future<List<Danmaku>> getDanmaku(int cid) async {
    try {
      final uri = Uri.parse('$baseUrl/x/v1/dm/list.so').replace(
        queryParameters: {'oid': cid.toString()},
      );
      final response = await http.get(uri, headers: _headers);
      final body = utf8.decode(response.bodyBytes);
      final regex = RegExp(r'<d p="([^"]*)">([^<]*)</d>');
      final matches = regex.allMatches(body);
      return matches
          .map((m) => Danmaku.fromXml(m.group(1)!, _decodeXmlEntities(m.group(2)!)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ============ 登录 / 用户 ============

  /// 生成登录二维码
  Future<Map<String, dynamic>?> generateQrCode() async {
    final json = await _getJson(
      '$passportBaseUrl/x/passport-login/web/qrcode/generate',
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return null;
    return data;
  }

  /// 轮询二维码登录状态
  Future<Map<String, dynamic>?> pollQrCode(String qrcodeKey) async {
    final json = await _getJson(
      '$passportBaseUrl/x/passport-login/web/qrcode/poll',
      params: {'qrcode_key': qrcodeKey},
    );
    return json;
  }

  /// 获取用户信息（导航接口，需 SESSDATA）
  Future<Map<String, dynamic>?> getUserInfo() async {
    final json = await _getJson('$baseUrl/x/web-interface/nav');
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return null;
    return data;
  }

  // ============ 辅助方法 ============

  /// 去除 HTML 标签（如搜索结果中的 <em> 高亮）
  String _stripHtml(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 解码 XML 实体
  String _decodeXmlEntities(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');
  }

  /// 安全将 dynamic 转为 int（兼容 int / double / String）
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
