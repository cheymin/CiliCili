import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// 移植自 PiliPlus 的网格布局逻辑：
/// 封面按 [childAspectRatio] 计算高度，再额外叠加固定的 [mainAxisExtent]（文字区），
/// 列数由 [maxCrossAxisExtent] 自适应。手机 2 列、平板 3~4 列、电视 5~6 列。
class SliverGridDelegateWithExtentAndRatio extends SliverGridDelegate {
  const SliverGridDelegateWithExtentAndRatio({
    required this.maxCrossAxisExtent,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent = 0.0,
  })  : assert(maxCrossAxisExtent > 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(childAspectRatio > 0);

  final double maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final double mainAxisExtent;

  int _getCrossAxisCount(double crossAxisExtent) {
    return (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil();
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final int crossAxisCount =
        math.max(1, _getCrossAxisCount(constraints.crossAxisExtent));
    final double usableCrossAxisExtent = math.max(
      0.0,
      constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1),
    );
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    // 封面高度 = 卡宽 / 宽高比；再加上文字区固定高度
    final double childMainAxisExtent =
        childCrossAxisExtent / childAspectRatio + mainAxisExtent;
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithExtentAndRatio oldDelegate) {
    return oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.childAspectRatio != childAspectRatio ||
        oldDelegate.mainAxisExtent != mainAxisExtent;
  }
}
