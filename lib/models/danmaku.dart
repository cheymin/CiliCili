/// 弹幕模型
///
/// mode：1=右→左滚动，4=底部固定，5=顶部固定
class Danmaku {
  final String text;

  /// 出现时间（秒）
  final double time;
  final int mode;

  /// 颜色（十进制 RGB，如 16777215 = 白色）
  final int color;
  final int fontSize;

  Danmaku({
    required this.text,
    required this.time,
    required this.mode,
    required this.color,
    required this.fontSize,
  });

  /// 从 XML 弹幕的 p 属性解析
  ///
  /// p 属性格式："time,mode,fontsize,color,timestamp,pool,midHash,dmid"
  factory Danmaku.fromXml(String pAttribute, String content) {
    final parts = pAttribute.split(',');
    return Danmaku(
      text: content,
      time: parts.isNotEmpty ? (double.tryParse(parts[0]) ?? 0.0) : 0.0,
      mode: parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1,
      fontSize: parts.length > 2 ? (int.tryParse(parts[2]) ?? 25) : 25,
      color: parts.length > 3 ? (int.tryParse(parts[3]) ?? 16777215) : 16777215,
    );
  }

  /// 从 protobuf 风格的 JSON 解析
  ///
  /// progress 单位为毫秒，需除以 1000 转为秒。
  factory Danmaku.fromJson(Map<String, dynamic> json) {
    final progress = (json['progress'] as num?)?.toDouble();
    return Danmaku(
      text: json['content'] as String? ?? '',
      time: progress != null ? progress / 1000.0 : 0.0,
      mode: (json['mode'] as num?)?.toInt() ?? 1,
      color: (json['color'] as num?)?.toInt() ?? 16777215,
      fontSize: (json['fontsize'] as num?)?.toInt() ?? 25,
    );
  }
}
