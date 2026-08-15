import 'package:flutter/material.dart';

/// 自定义主题颜色方案
class CiliciliThemeColors {
  // 默认主题颜色
  static const Color defaultGreen = Color(0xFF5CB67B);
  static const Color defaultPink = Color(0xFFFF7299);
  
  // 自定义主题颜色列表
  static const List<({Color color, String label, String hex})> customColors = [
    (color: Color(0xFF5CB67B), label: '默认绿', hex: '#5CB67B'),
    (color: Color(0xFFFF7299), label: '粉红色', hex: '#FF7299'),
    (color: Colors.red, label: '红色', hex: '#FF0000'),
    (color: Colors.orange, label: '橙色', hex: '#FF9800'),
    (color: Colors.amber, label: '琥珀色', hex: '#FFC107'),
    (color: Colors.yellow, label: '黄色', hex: '#FFEB3B'),
    (color: Colors.lime, label: '酸橙色', hex: '#CDDC39'),
    (color: Colors.lightGreen, label: '浅绿色', hex: '#8BC34A'),
    (color: Colors.green, label: '绿色', hex: '#4CAF50'),
    (color: Colors.teal, label: '青色', hex: '#009688'),
    (color: Colors.cyan, label: '蓝绿色', hex: '#00BCD4'),
    (color: Colors.lightBlue, label: '浅蓝色', hex: '#03A9F4'),
    (color: Colors.blue, label: '蓝色', hex: '#2196F3'),
    (color: Colors.indigo, label: '靛蓝色', hex: '#3F51B5'),
    (color: Colors.purple, label: '紫色', hex: '#9C27B0'),
    (color: Colors.deepPurple, label: '深紫色', hex: '#673AB7'),
    (color: Colors.blueGrey, label: '蓝灰色', hex: '#607D8B'),
    (color: Colors.brown, label: '棕色', hex: '#795548'),
    (color: Colors.grey, label: '灰色', hex: '#9E9E9E'),
    // 新增个性化颜色
    (color: Color(0xFFFF6B6B), label: '珊瑚红', hex: '#FF6B6B'),
    (color: Color(0xFF4ECDC4), label: '薄荷青', hex: '#4ECDC4'),
    (color: Color(0xFF45B7D1), label: '天蓝色', hex: '#45B7D1'),
    (color: Color(0xFF96CEB4), label: '薄荷绿', hex: '#96CEB4'),
    (color: Color(0xFFFFEAA7), label: '奶油黄', hex: '#FFEAA7'),
    (color: Color(0xFFDDA0DD), label: '梅子紫', hex: '#DDA0DD'),
    (color: Color(0xFF98D8C8), label: '淡青绿', hex: '#98D8C8'),
    (color: Color(0xFFF7DC6F), label: '阳光黄', hex: '#F7DC6F'),
    (color: Color(0xFFBB8FCE), label: '薰衣草紫', hex: '#BB8FCE'),
    (color: Color(0xFFF1948A), label: '桃粉色', hex: '#F1948A'),
    (color: Color(0xFF85C1E9), label: '天空蓝', hex: '#85C1E9'),
    (color: Color(0xFF82E0AA), label: '清新绿', hex: '#82E0AA'),
    (color: Color(0xFFFF8C00), label: '深橙色', hex: '#FF8C00'),
    (color: Color(0xFFE74C3C), label: '正红色', hex: '#E74C3C'),
    (color: Color(0xFF2ECC71), label: '翠绿', hex: '#2ECC71'),
    (color: Color(0xFF3498DB), label: '宝蓝', hex: '#3498DB'),
    (color: Color(0xFF9B59B6), label: '亮紫', hex: '#9B59B6'),
    (color: Color(0xFFF39C12), label: '金色', hex: '#F39C12'),
    (color: Color(0xFF1ABC9C), label: '绿松石', hex: '#1ABC9C'),
    (color: Color(0xFFE91E63), label: '品红', hex: '#E91E63'),
  ];
  
  /// 根据色值获取颜色
  static Color getColorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
  
  /// 获取颜色列表
  static List<({Color color, String label})> getThemeColors() {
    return customColors.map((c) => (color: c.color, label: c.label)).toList();
  }
}
