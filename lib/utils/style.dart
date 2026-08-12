import 'package:flutter/material.dart';

/// 移植自 PiliPlus 的视觉常量（lib/common/style.dart）
abstract final class Style {
  static const cardSpace = 8.0;
  static const safeSpace = 12.0;
  static const imgRadius = Radius.circular(10);
  static const mdRadius = BorderRadius.all(imgRadius);
  static const aspectRatio = 16 / 10; // 封面宽高比
  static const topBarHeight = 52.0;

  /// 推荐卡片目标宽度：手机约 2 列、平板 3~4 列、电视 5~6 列
  static const recommendCardWidth = 240.0;
}
