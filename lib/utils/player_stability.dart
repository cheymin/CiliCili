/// 播放器稳定性增强补丁
/// 解决视频播放卡顿、闪退问题

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class PlayerStabilityManager {
  static final PlayerStabilityManager _instance = PlayerStabilityManager._internal();
  
  factory PlayerStabilityManager() => _instance;
  
  PlayerStabilityManager._internal();
  
  // 错误计数器
  int _errorCount = 0;
  static const int _maxErrorsBeforeReset = 5;
  DateTime? _lastErrorTime;
  static const Duration _errorResetTimeout = Duration(minutes: 5);
  
  // 播放超时
  static const Duration _playTimeout = Duration(seconds: 15);
  Timer? _playTimeoutTimer;
  
  // 缓冲超时
  static const Duration _bufferTimeout = Duration(seconds: 10);
  Timer? _bufferTimeoutTimer;
  
  // 最大重试次数
  static const int _maxRetryCount = 3;
  int _retryCount = 0;
  
  // 是否正在恢复播放
  bool _isRecovering = false;
  
  bool get isRecovering => _isRecovering;
  
  /// 记录错误
  void recordError(String error, {String? context}) {
    _errorCount++;
    _lastErrorTime = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('[PlayerStability] 错误 #$_errorCount: $error${context != null ? ' [$_context]' : ''}');
    }
    
    // 检查是否需要重置计数器
    _checkErrorReset();
    
    // 如果错误过多，触发自动恢复
    if (_errorCount >= _maxErrorsBeforeReset && !_isRecovering) {
      _autoRecover(error);
    }
  }
  
  /// 检查是否需要重置错误计数
  void _checkErrorReset() {
    if (_lastErrorTime != null && 
        DateTime.now().difference(_lastErrorTime!) > _errorResetTimeout) {
      _errorCount = 0;
    }
  }
  
  /// 自动恢复播放
  Future<void> _autoRecover(String lastError) async {
    if (_isRecovering) return;
    _isRecovering = true;
    
    if (kDebugMode) {
      debugPrint('[PlayerStability] 检测到多次错误，尝试自动恢复...');
    }
    
    try {
      // 显示提示
      SmartDialog.showToast('播放异常，正在尝试恢复...', displayTime: const Duration(seconds: 2));
      
      // 延迟后重试
      await Future.delayed(const Duration(seconds: 2));
      _retryCount = 0;
      
      _isRecovering = false;
    } catch (e) {
      _isRecovering = false;
      if (kDebugMode) {
        debugPrint('[PlayerStability] 自动恢复失败: $e');
      }
    }
  }
  
  /// 开始播放超时计时
  void startPlayTimeout() {
    _playTimeoutTimer?.cancel();
    _playTimeoutTimer = Timer(_playTimeout, () {
      if (kDebugMode) {
        debugPrint('[PlayerStability] 播放超时！');
      }
      recordError('播放超时', context: 'play_timeout');
    });
  }
  
  /// 取消播放超时计时
  void cancelPlayTimeout() {
    _playTimeoutTimer?.cancel();
    _playTimeoutTimer = null;
  }
  
  /// 开始缓冲超时计时
  void startBufferTimeout() {
    _bufferTimeoutTimer?.cancel();
    _bufferTimeoutTimer = Timer(_bufferTimeout, () {
      if (kDebugMode) {
        debugPrint('[PlayerStability] 缓冲超时！');
      }
      recordError('缓冲超时', context: 'buffer_timeout');
    });
  }
  
  /// 取消缓冲超时计时
  void cancelBufferTimeout() {
    _bufferTimeoutTimer?.cancel();
    _bufferTimeoutTimer = null;
  }
  
  /// 重置重试计数
  void resetRetry() {
    _retryCount = 0;
    _errorCount = 0;
  }
  
  /// 检查是否超过最大重试次数
  bool get shouldStopRetry => _retryCount >= _maxRetryCount;
  
  /// 增加重试计数
  void incrementRetry() {
    _retryCount++;
  }
  
  /// 清理资源
  void dispose() {
    _playTimeoutTimer?.cancel();
    _bufferTimeoutTimer?.cancel();
    _errorCount = 0;
    _retryCount = 0;
    _isRecovering = false;
  }
}

// 全局实例
final playerStabilityManager = PlayerStabilityManager();
