/// 播放器自定义异常
class PlayerException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;
  
  const PlayerException(this.message, {this.code = 'unknown', this.originalError});
  
  @override
  String toString() => 'PlayerException($code): $message';
}

/// 播放超时异常
class PlayTimeoutException extends PlayerException {
  const PlayTimeoutException() : super('播放超时', code: 'play_timeout');
}

/// 缓冲超时异常
class BufferTimeoutException extends PlayerException {
  const BufferTimeoutException() : super('缓冲超时', code: 'buffer_timeout');
}

/// 解码错误异常
class DecodeException extends PlayerException {
  const DecodeException(String message) : super(message, code: 'decode_error');
}

/// 网络错误异常
class NetworkException extends PlayerException {
  const NetworkException(String message) : super(message, code: 'network_error');
}

/// 播放器状态
enum PlayerState {
  idle,
  loading,
  buffering,
  playing,
  paused,
  error,
  completed,
}
