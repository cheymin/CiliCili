/// 网络请求超时配置
class NetworkTimeoutConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration videoPlayTimeout = Duration(seconds: 15);
  static const Duration imageTimeout = Duration(seconds: 10);
  static const Duration apiTimeout = Duration(seconds: 20);
  
  // 重试配置
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration retryBackoffMultiplier = Duration(seconds: 2);
  
  // 连接超时
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  /// 获取超时时间
  static Duration getTimeout(RequestType type) {
    switch (type) {
      case RequestType.videoPlay:
        return videoPlayTimeout;
      case RequestType.image:
        return imageTimeout;
      case RequestType.api:
        return apiTimeout;
      default:
        return defaultTimeout;
    }
  }
}

enum RequestType {
  default_,
  videoPlay,
  image,
  api,
}
