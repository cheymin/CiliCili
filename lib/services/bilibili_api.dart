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
      params: {'qrcode_key': qrcodeKey, 'source': 'main-fe-header'},
    );
    return json;
  }

  /// 从登录成功的 URL 中解析并保存 Cookie
  bool parseAndSaveLoginCookies(String url) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;
    final sessdata = params['SESSDATA'];
    final biliJct = params['bili_jct'];
    final dedeUserId = params['DedeUserID'];
    if (sessdata == null || sessdata.isEmpty) return false;
    StorageService.sessdata = sessdata;
    if (biliJct != null) StorageService.biliJct = biliJct;
    if (dedeUserId != null) StorageService.dedeUserId = dedeUserId;
    return true;
  }

  /// 退出登录
  Future<void> logout() async {
    StorageService.sessdata = null;
    StorageService.biliJct = null;
    StorageService.dedeUserId = null;
  }

  /// 是否已登录
  bool get isLoggedIn {
    final s = StorageService.sessdata;
    return s != null && s.isNotEmpty;
  }

  /// 获取当前用户信息（导航接口，需 SESSDATA）
  Future<Map<String, dynamic>?> getUserInfo() async {
    final json = await _getJson('$baseUrl/x/web-interface/nav');
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return null;
    return data;
  }

  /// 获取用户空间信息
  Future<Map<String, dynamic>?> getSpaceInfo(int mid) async {
    final json = await _getJson(
      '$baseUrl/x/space/wbi/acc/info',
      params: {'mid': mid.toString()},
    );
    final res = _wrap(json);
    return res.data;
  }

  // ============ 历史记录 ============

  /// 获取观看历史
  Future<List<Video>> getHistory({int page = 1, int pageSize = 20}) async {
    final json = await _getJson(
      '$baseUrl/x/v2/history',
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
        .map((e) {
          final history = e['history'] as Map<String, dynamic>?;
          final title = e['title'] as String? ?? history?['title'] as String?;
          final cover = e['cover'] as String? ?? history?['cover'] as String?;
          final uri = e['uri'] as String? ?? history?['uri'] as String?;
          String? bvid;
          if (uri != null && uri.contains('video/')) {
            final match = RegExp(r'BV[0-9A-Za-z]+').firstMatch(uri);
            bvid = match?.group(0);
          }
          bvid ??= e['bvid'] as String?;
          return Video(
            bvid: bvid,
            aid: _parseInt(e['aid'] ?? history?['aid']),
            title: title,
            pic: cover,
            view: _parseInt(e['progress']),
            duration: _parseInt(e['duration'] ?? history?['duration']),
            name: (e['author_name'] as String?) ?? (history?['owner_name'] as String?),
          );
        })
        .where((v) => v.bvid?.isNotEmpty == true)
        .toList();
  }

  // ============ 收藏夹 ============

  /// 获取用户收藏夹列表
  Future<List<Map<String, dynamic>>> getFavList(int mid) async {
    final json = await _getJson(
      '$baseUrl/x/v3/fav/folder/created/list-all',
      params: {'up_mid': mid.toString()},
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final list = data['list'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// 获取收藏夹内容
  Future<List<Video>> getFavVideos(int mediaId, {int page = 1}) async {
    final json = await _getJson(
      '$baseUrl/x/v3/fav/resource/list',
      params: {
        'media_id': mediaId.toString(),
        'pn': page.toString(),
        'ps': '20',
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final medias = data['medias'];
    if (medias is! List) return const [];
    return medias
        .whereType<Map<String, dynamic>>()
        .map((e) => Video(
              bvid: e['bvid'] as String?,
              aid: _parseInt(e['id']),
              title: e['title'] as String?,
              pic: e['cover'] as String? ?? (e['upper']?['face'] as String?),
              duration: _parseInt(e['duration']),
              name: e['upper']?['name'] as String?,
              view: _parseInt(e['cnt_info']?['play']),
            ))
        .where((v) => v.bvid?.isNotEmpty == true)
        .toList();
  }

  // ============ 互动（点赞/投币/收藏） ============

  /// 点赞视频
  Future<bool> likeVideo(int aid, bool like) async {
    final json = await _postForm(
      '$baseUrl/x/web-interface/like/like',
      params: {
        'aid': aid.toString(),
        'like': like ? '1' : '2',
        'csrf': StorageService.biliJct ?? '',
      },
    );
    return json?['code'] == 0;
  }

  /// 投币
  Future<bool> coinVideo(int aid, {int num = 1, bool like = false}) async {
    final json = await _postForm(
      '$baseUrl/x/web-interface/coin/add',
      params: {
        'aid': aid.toString(),
        'multiply': num.toString(),
        'select_like': like ? '1' : '0',
        'csrf': StorageService.biliJct ?? '',
      },
    );
    return json?['code'] == 0;
  }

  /// 添加/取消收藏
  Future<bool> favVideo(int aid, int mediaId, bool add) async {
    final json = await _postForm(
      '$baseUrl/x/v3/fav/resource/deal',
      params: {
        'rid': aid.toString(),
        'type': '2',
        'add_ids': add ? mediaId.toString() : '',
        'del_ids': add ? '' : mediaId.toString(),
        'csrf': StorageService.biliJct ?? '',
      },
    );
    return json?['code'] == 0;
  }

  /// 关注用户
  Future<bool> followUser(int mid, bool follow) async {
    final json = await _postForm(
      '$baseUrl/x/relation/modify',
      params: {
        'fid': mid.toString(),
        'act': follow ? '1' : '2',
        'csrf': StorageService.biliJct ?? '',
      },
    );
    return json?['code'] == 0;
  }

  // ============ 动态 ============

  /// 获取关注动态
  Future<List<Video>> getFollowDynamic({int page = 1}) async {
    final json = await _getJson(
      '$baseUrl/x/polymer/web-dynamic/v1/feed/all',
      params: {
        'page': page.toString(),
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .where((e) => e['type'] == 'DYNAMIC_TYPE_AV' || e['type'] == 'DYNAMIC_TYPE_LIVE_RCMD')
        .map((e) {
          final module = e['modules'] as Map<String, dynamic>?;
          final author = module?['module_author'] as Map<String, dynamic>?;
          final dynamicData = module?['module_dynamic'] as Map<String, dynamic>?;
          final major = dynamicData?['major'] as Map<String, dynamic>?;
          final archive = major?['archive'] as Map<String, dynamic>?;
          return Video(
            bvid: archive?['bvid'] as String?,
            aid: _parseInt(archive?['aid']),
            title: archive?['title'] as String?,
            pic: archive?['cover'] as String?,
            name: author?['name'] as String?,
            duration: _parseInt(archive?['duration']),
            view: _parseInt(archive?['stat']?['play']),
          );
        })
        .where((v) => v.bvid?.isNotEmpty == true)
        .toList();
  }

  // ============ 评论 ============

  /// 获取评论列表
  Future<List<Map<String, dynamic>>> getComments(
    int oid, {
    int type = 1,
    int next = 0,
    int ps = 20,
  }) async {
    final json = await _getJson(
      '$baseUrl/x/v2/reply/main',
      params: {
        'oid': oid.toString(),
        'type': type.toString(),
        'next': next.toString(),
        'ps': ps.toString(),
      },
    );
    final res = _wrap(json);
    final data = res.data;
    if (!res.isSuccess || data == null) return const [];
    final replies = data['replies'];
    if (replies is! List) return const [];
    return replies.whereType<Map<String, dynamic>>().toList();
  }

  // ============ 发送 POST 请求（form-urlencoded） ============

  Future<Map<String, dynamic>?> _postForm(
    String url, {
    Map<String, String>? params,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.post(
        uri,
        headers: {
          ..._headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
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
