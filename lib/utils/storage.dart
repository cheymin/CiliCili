import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 基于 [SharedPreferences] 的本地持久化服务
///
/// 负责 UI 偏好、B 站登录凭据、搜索历史与收藏等数据的读写。
class StorageService {
  StorageService._();

  static SharedPreferences? _prefs;

  /// 初始化 SharedPreferences，需在 runApp 之前调用
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'StorageService 尚未初始化，请先调用 StorageService.init()',
      );
    }
    return prefs;
  }

  // ===================== UI 偏好 =====================

  /// UI 风格：'google' 或 'apple'
  static String? get uiStyle => _instance.getString('ui_style');
  static set uiStyle(String? value) {
    if (value == null) {
      _instance.remove('ui_style');
    } else {
      _instance.setString('ui_style', value);
    }
  }

  /// 主题模式：'light'、'dark' 或 'system'
  static String? get themeMode => _instance.getString('theme_mode');
  static set themeMode(String? value) {
    if (value == null) {
      _instance.remove('theme_mode');
    } else {
      _instance.setString('theme_mode', value);
    }
  }

  /// 自定义主色（保存为 ARGB int）
  static int? get customPrimaryColor =>
      _instance.getInt('custom_primary_color');
  static set customPrimaryColor(int? value) {
    if (value == null) {
      _instance.remove('custom_primary_color');
    } else {
      _instance.setInt('custom_primary_color', value);
    }
  }

  /// 自定义字体族
  static String? get customFontFamily =>
      _instance.getString('custom_font_family');
  static set customFontFamily(String? value) {
    if (value == null) {
      _instance.remove('custom_font_family');
    } else {
      _instance.setString('custom_font_family', value);
    }
  }

  // ===================== B 站登录凭据 =====================

  static String? get sessdata => _instance.getString('bili_sessdata');
  static set sessdata(String? value) {
    if (value == null) {
      _instance.remove('bili_sessdata');
    } else {
      _instance.setString('bili_sessdata', value);
    }
  }

  static String? get biliJct => _instance.getString('bili_jct');
  static set biliJct(String? value) {
    if (value == null) {
      _instance.remove('bili_jct');
    } else {
      _instance.setString('bili_jct', value);
    }
  }

  static String? get dedeUserId => _instance.getString('bili_dede_user_id');
  static set dedeUserId(String? value) {
    if (value == null) {
      _instance.remove('bili_dede_user_id');
    } else {
      _instance.setString('bili_dede_user_id', value);
    }
  }

  static String? get buvid3 => _instance.getString('bili_buvid3');
  static set buvid3(String? value) {
    if (value == null) {
      _instance.remove('bili_buvid3');
    } else {
      _instance.setString('bili_buvid3', value);
    }
  }

  // ===================== 搜索历史 & 收藏 =====================

  /// 搜索历史列表
  static List<String> get searchHistory =>
      _instance.getStringList('search_history') ?? const [];
  static set searchHistory(List<String> value) {
    _instance.setStringList('search_history', value);
  }

  /// 收藏视频列表（以 JSON 字符串形式保存到本地）
  static List<String> get favoriteVideos {
    final raw = _instance.getString('favorite_videos');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList(growable: false);
      }
    } catch (_) {
      // ignore: 损坏的缓存直接忽略
    }
    return const [];
  }

  static set favoriteVideos(List<String> value) {
    _instance.setString('favorite_videos', jsonEncode(value));
  }

  // ===================== 通用缓存 =====================

  /// 读取通用字符串缓存
  static String? getCache(String key) =>
      _instance.getString('cache_$key');

  /// 写入通用字符串缓存
  static void setCache(String key, String value) {
    _instance.setString('cache_$key', value);
  }
}
