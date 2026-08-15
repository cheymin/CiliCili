import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/utils/gstorage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 初始化平台
void initPlatform() {
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // 设置默认字体大小
  SystemFontScale.setSystemFontScale(
    Pref.fontSize.toDouble(),
    Get.context!,
  );
}

/// 设置字体大小
class SystemFontScale {
  /// 获取字体缩放比例
  static double get scale => Pref.fontSize / 100;
  
  /// 设置字体缩放
  static void setSystemFontScale(int value, BuildContext context) {
    final scale = value / 100;
    // 这里可以设置全局字体缩放
  }
}
