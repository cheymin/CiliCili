/// 视频分 P 信息
class VideoPage {
  final int cid;
  final int page;
  final String part;
  final int duration;

  VideoPage({
    required this.cid,
    required this.page,
    required this.part,
    required this.duration,
  });

  factory VideoPage.fromJson(Map<String, dynamic> json) {
    return VideoPage(
      cid: _parseInt(json['cid']) ?? 0,
      page: _parseInt(json['page']) ?? 1,
      part: json['part'] as String? ?? '',
      duration: _parseInt(json['duration']) ?? 0,
    );
  }
}

/// DASH 视频流信息
class DashVideo {
  final int id;
  final int codecid;
  final String baseUrl;
  final int bandwidth;
  final String codecs;
  final int width;
  final int height;

  DashVideo({
    required this.id,
    required this.codecid,
    required this.baseUrl,
    required this.bandwidth,
    required this.codecs,
    required this.width,
    required this.height,
  });

  factory DashVideo.fromJson(Map<String, dynamic> json) {
    return DashVideo(
      id: _parseInt(json['id']) ?? 0,
      codecid: _parseInt(json['codecid']) ?? 0,
      baseUrl: (json['baseUrl'] as String?) ?? (json['base_url'] as String?) ?? '',
      bandwidth: _parseInt(json['bandwidth']) ?? 0,
      codecs: json['codecs'] as String? ?? '',
      width: _parseInt(json['width']) ?? 0,
      height: _parseInt(json['height']) ?? 0,
    );
  }
}

/// DASH 音频流信息
class DashAudio {
  final int id;
  final String baseUrl;
  final int bandwidth;
  final String codecs;

  DashAudio({
    required this.id,
    required this.baseUrl,
    required this.bandwidth,
    required this.codecs,
  });

  factory DashAudio.fromJson(Map<String, dynamic> json) {
    return DashAudio(
      id: _parseInt(json['id']) ?? 0,
      baseUrl: (json['baseUrl'] as String?) ?? (json['base_url'] as String?) ?? '',
      bandwidth: _parseInt(json['bandwidth']) ?? 0,
      codecs: json['codecs'] as String? ?? '',
    );
  }
}

/// playurl 接口返回的播放地址信息
class VideoPlayUrl {
  final int quality;
  final List<int> acceptQuality;
  final List<String> acceptDescription;
  final List<DashVideo> dashVideo;
  final List<DashAudio> dashAudio;

  /// 视频时长（毫秒）
  final int duration;

  VideoPlayUrl({
    required this.quality,
    required this.acceptQuality,
    required this.acceptDescription,
    required this.dashVideo,
    required this.dashAudio,
    required this.duration,
  });

  factory VideoPlayUrl.fromJson(Map<String, dynamic> json) {
    final dash = json['dash'] as Map<String, dynamic>?;
    final videoList = dash?['video'] as List?;
    final audioList = dash?['audio'] as List?;
    return VideoPlayUrl(
      quality: _parseInt(json['quality']) ?? 0,
      acceptQuality: (json['accept_quality'] as List? ?? const [])
          .map((e) => _parseInt(e) ?? 0)
          .toList(),
      acceptDescription: (json['accept_description'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      dashVideo: videoList != null
          ? videoList
              .whereType<Map<String, dynamic>>()
              .map((e) => DashVideo.fromJson(e))
              .toList()
          : const [],
      dashAudio: audioList != null
          ? audioList
              .whereType<Map<String, dynamic>>()
              .map((e) => DashAudio.fromJson(e))
              .toList()
          : const [],
      duration: _parseInt(json['timelength']) ?? 0,
    );
  }
}

/// 视频模型（owner / stat 已扁平化存储）
class Video {
  final String? bvid;
  final int? aid;
  final String? title;
  final String? pic;
  final String? desc;

  /// 时长（秒）
  final int? duration;

  /// 发布时间戳（秒）
  final int? pubdate;

  // ===== owner =====
  final int? mid;
  final String? name;
  final String? face;

  // ===== stat =====
  final int? view;
  final int? danmaku;
  final int? reply;
  final int? favorite;
  final int? coin;
  final int? like;
  final int? share;

  // ===== 其它 =====
  final int? cid;

  /// 分 P 数量
  final int? videos;

  /// 分区名
  final String? tname;

  final List<VideoPage> pages;

  Video({
    this.bvid,
    this.aid,
    this.title,
    this.pic,
    this.desc,
    this.duration,
    this.pubdate,
    this.mid,
    this.name,
    this.face,
    this.view,
    this.danmaku,
    this.reply,
    this.favorite,
    this.coin,
    this.like,
    this.share,
    this.cid,
    this.videos,
    this.tname,
    this.pages = const [],
  });

  /// 标准格式：popular / view / rank / region / related 接口返回
  factory Video.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final stat = json['stat'] as Map<String, dynamic>?;
    final pagesList = json['pages'] as List?;
    return Video(
      bvid: json['bvid'] as String?,
      aid: _parseInt(json['aid']),
      title: json['title'] as String?,
      pic: json['pic'] as String?,
      desc: json['desc'] as String?,
      duration: _parseInt(json['duration']),
      pubdate: _parseInt(json['pubdate']),
      mid: _parseInt(owner?['mid']),
      name: owner?['name'] as String?,
      face: owner?['face'] as String?,
      view: _parseInt(stat?['view']),
      danmaku: _parseInt(stat?['danmaku']),
      reply: _parseInt(stat?['reply']),
      favorite: _parseInt(stat?['favorite']),
      coin: _parseInt(stat?['coin']),
      like: _parseInt(stat?['like']),
      share: _parseInt(stat?['share']),
      cid: _parseInt(json['cid']),
      videos: _parseInt(json['videos']),
      tname: json['tname'] as String?,
      pages: pagesList != null
          ? pagesList
              .whereType<Map<String, dynamic>>()
              .map((e) => VideoPage.fromJson(e))
              .toList()
          : const [],
    );
  }

  /// 推荐流格式：cover（非 pic），aid 在 args 下，owner/stat 可能缺失
  factory Video.fromRecommendJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final stat = json['stat'] as Map<String, dynamic>?;
    final args = json['args'] as Map<String, dynamic>?;
    return Video(
      bvid: json['bvid'] as String?,
      aid: _parseInt(args?['aid']) ?? _parseInt(json['aid']),
      title: json['title'] as String?,
      pic: (json['pic'] as String?) ?? (json['cover'] as String?),
      desc: json['desc'] as String?,
      duration: _parseInt(json['duration']),
      pubdate: _parseInt(json['pubdate']),
      mid: _parseInt(owner?['mid']) ?? _parseInt(args?['up_id']),
      name: (owner?['name'] as String?) ?? (args?['up_name'] as String?),
      face: owner?['face'] as String?,
      view: _parseInt(stat?['view']),
      danmaku: _parseInt(stat?['danmaku']),
      reply: _parseInt(stat?['reply']),
      favorite: _parseInt(stat?['favorite']),
      coin: _parseInt(stat?['coin']),
      like: _parseInt(stat?['like']),
      share: _parseInt(stat?['share']),
      cid: _parseInt(json['cid']),
      videos: _parseInt(json['videos']),
      tname: json['tname'] as String? ?? (args?['rname'] as String?),
    );
  }

  String get coverUrl {
    final url = pic ?? '';
    if (url.isEmpty) return '';
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('http')) return url;
    return 'https://$url';
  }

  String get upName => name ?? '未知UP';

  String get description => desc ?? '';

  String get pubDateFormatted {
    if (pubdate == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(pubdate! * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 365) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}个月前';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    }
    return '刚刚';
  }
}

/// 安全将 dynamic 转为 int（兼容 int / double / String）
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
