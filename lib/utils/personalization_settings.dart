import 'package:flutter/material.dart';

/// 个性化主题设置
class PersonalizationSettings {
  // 主题类型
  static const List<String> themeTypes = [
    '浅色',
    '深色',
    '跟随系统',
  ];
  
  // 动态取色模式
  static const List<String> dynamicColorModes = [
    '关闭',
    '仅深色模式',
    '始终启用',
  ];
  
  // 字体大小
  static const List<double> fontSizes = [0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2];
  
  // 卡片间距
  static const List<double> cardSpacings = [0.0, 4.0, 8.0, 12.0, 16.0];
  
  // 圆角大小
  static const List<double> cornerRadii = [0.0, 4.0, 8.0, 12.0, 16.0, 20.0];
  
  // 列表密度
  static const List<String> listDensities = [
    '紧凑',
    '舒适',
    '宽松',
  ];
  
  /// 获取列表密度对应的边距
  static EdgeInsets getListItemPadding(String density) {
    switch (density) {
      case '紧凑':
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case '宽松':
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
      default: // 舒适
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
    }
  }
}
