import 'dart:math';

/// 骚话错误信息系统：用接地气的中文段子代替干巴巴的报错文案
///
/// 让用户在遇到网络故障 / 服务器抽风 / 视频消失时也能会心一笑。
class FunnyMessages {
  FunnyMessages._();

  static final Random _random = Random();

  // ===================== 错误文案库 =====================

  static const List<String> _networkErrors = [
    '网络开小差了，可能是猫在踩网线',
    '信号断了...不会是路由器被拔了吧？',
    '网络比你前任还难搞，再试一次吧',
    '连接失败了，建议对着屏幕拜一拜',
    '网线大概是被松鼠啃断了',
    '网络已离家出走，请稍候寻回',
    'Wi-Fi 信号被风吹歪了，请重试',
    '网速像极了周一的我，提不起劲',
  ];

  static const List<String> _serverErrors = [
    '服务器大概是去吃饭了，等它回来',
    'B站服务器: 我裂开了，你等等',
    '服务器忙着补番呢，稍后再来',
    '服务器: 今天心情不好，不想工作',
    '服务器正在摸鱼，请勿打扰',
    '服务器的小电驴没电了，正在充电',
    'B站服务器: 我emo了，让我静静',
    '服务器被请求砸晕了，正在人工呼吸',
  ];

  static const List<String> _notFoundErrors = [
    '这视频怕不是被作者删了跑路了',
    '404...视频可能穿越到异世界了',
    '找不到这个视频，它可能害羞躲起来了',
    '视频不存在！难道是被奥特曼打死了？',
    '视频跑路啦，可能是被外星人劫走了',
    '这视频像咸鱼一样翻没影了',
    '404 - 视频已被时空裂缝吞噬',
    '视频躲进了第四维空间，三维生物看不到',
  ];

  static const List<String> _timeoutErrors = [
    '等太久了，你的网速是用鸽子传信的吗？',
    '超时了，建议检查下是不是在用2G网络',
    '请求飞了半天还没回来，可能迷路了',
    '鸽子还在路上，请稍等片刻',
    '请求正在爬着回来，请给它点时间',
    '你的网络大概是用乌龟拉的光纤',
    '请求走丢了，正在原地转圈圈',
  ];

  static const List<String> _unauthorizedErrors = [
    '你还没登录呢，快去扫码！',
    '请先登录，不然B站不让你看',
    '未登录，就像没带钥匙出门一样尴尬',
    '登录一下嘛，又不收你钱',
    '请先登录，不然我就告老师了',
    '未登录用户禁止入内，请扫码放行',
    '不登录就看视频？B站说你做梦呢',
  ];

  static const List<String> _rateLimitedErrors = [
    '你手速太快了，B站都拦不住了',
    '慢点慢点，B站说你请求太频繁了',
    '别急别急，给服务器喘口气',
    '你的手速震惊了B站，请休息一下',
    '请求太快啦，服务器CPU都要冒烟了',
    '你点这么快是想练电竞吗？慢点',
    'B站: 我承认你的手速，但求放过',
  ];

  static const List<String> _unknownErrors = [
    '出了点小问题，但我也不知道是啥',
    '啊这...出了点意外，试试重新来过？',
    '噗——出错了，但问题不大，再试一次',
    '不知道发生了啥，但刷新一下准没错',
    '出错了！是不是触发了什么隐藏剧情？',
    '出了点小状况，B站可能正在偷偷修',
    'emmm...这个错误连我也看不懂',
    '出错了，建议先深呼吸三次再重试',
  ];

  // ===================== 随机取一条 =====================

  static String get networkError =>
      _networkErrors[_random.nextInt(_networkErrors.length)];

  static String get serverError =>
      _serverErrors[_random.nextInt(_serverErrors.length)];

  static String get notFound =>
      _notFoundErrors[_random.nextInt(_notFoundErrors.length)];

  static String get timeout =>
      _timeoutErrors[_random.nextInt(_timeoutErrors.length)];

  static String get unauthorized =>
      _unauthorizedErrors[_random.nextInt(_unauthorizedErrors.length)];

  static String get rateLimited =>
      _rateLimitedErrors[_random.nextInt(_rateLimitedErrors.length)];

  static String get unknown =>
      _unknownErrors[_random.nextInt(_unknownErrors.length)];

  // ===================== 异常 -> 文案映射 =====================

  /// 根据异常字符串匹配最合适的骚话文案
  static String fromException(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('timeout') || str.contains('timed out')) return timeout;
    if (str.contains('socket') ||
        str.contains('network') ||
        str.contains('connection')) return networkError;
    if (str.contains('404') || str.contains('not found')) return notFound;
    if (str.contains('401') ||
        str.contains('403') ||
        str.contains('unauthorized')) return unauthorized;
    if (str.contains('429') || str.contains('rate') || str.contains('412')) {
      return rateLimited;
    }
    if (str.contains('500') || str.contains('502') || str.contains('503')) {
      return serverError;
    }
    return unknown;
  }
}
