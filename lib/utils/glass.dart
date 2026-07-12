import 'dart:ui';

import 'package:flutter/material.dart';

/// 毛玻璃容器：使用 [BackdropFilter] + [ImageFilter.blur] 实现玻璃质感
///
/// - 半透明背景叠加在模糊层之上
/// - 0.5px 边框模拟 iOS 玻璃边缘高光
class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.isDark,
    this.blur = 20,
    this.opacity = 0.6,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
    this.child,
  });

  /// 当前是否为深色模式（决定玻璃底色）
  final bool isDark;

  /// 高斯模糊强度（sigma）
  final double blur;

  /// 背景透明度（0.0 ~ 1.0）
  final double opacity;

  /// 圆角半径
  final double radius;

  /// 内边距
  final EdgeInsets padding;

  /// 子节点
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final alpha = opacity.clamp(0.0, 1.0);
    final baseColor = isDark
        ? Color.fromARGB((alpha * 255).round(), 28, 28, 30)
        : Color.fromARGB((alpha * 255).round(), 255, 255, 255);
    final borderColor =
        isDark ? const Color(0x33FFFFFF) : const Color(0x33000000);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
