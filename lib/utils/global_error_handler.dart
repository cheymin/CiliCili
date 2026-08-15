/// 全局异常捕获和稳定性监控
/// 用于检测和恢复应用级别的卡顿和崩溃

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:PiliPlus/utils/logger.dart';

class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  
  factory GlobalErrorHandler() => _instance;
  
  GlobalErrorHandler._internal();
  
  // 错误统计
  int _errorCount = 0;
  int _fatalErrorCount = 0;
  DateTime? _lastErrorTime;
  static const Duration _errorResetTimeout = Duration(minutes: 5);
  static const int _maxErrorsBeforeRestart = 10;
  static const int _maxFatalErrors = 3;
  
  // 是否正在恢复
  bool _isRecovering = false;
  
  bool get isRecovering => _isRecovering;
  int get errorCount => _errorCount;
  int get fatalErrorCount => _fatalErrorCount;
  
  /// 初始化全局错误监听
  void init() {
    // 监听未捕获的异步错误
    PlatformDispatcher.instance.onError = _handlePlatformError;
    
    // 监听 Flutter 错误
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(details, isFatal: false);
    };
    
    if (kDebugMode) {
      debugPrint('[GlobalError] 全局错误处理器已初始化');
    }
  }
  
  /// 处理平台级别错误
  bool _handlePlatformError(dynamic error, StackTrace stackTrace) {
    handleError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'platform',
      ),
      isFatal: true,
    );
    return true;
  }
  
  /// 处理 Flutter 错误
  void handleError(FlutterErrorDetails details, {bool isFatal = false}) {
    final error = details.exception.toString();
    
    if (kDebugMode) {
      debugPrint('[GlobalError] ${isFatal ? "致命" : "普通"}错误: $error');
      if (details.stack != null) {
        debugPrint(details.stack.toString());
      }
    }
    
    // 检查是否需要重置错误计数
    _checkErrorReset();
    
    if (isFatal) {
      _fatalErrorCount++;
      
      // 多次致命错误时提示用户
      if (_fatalErrorCount >= _maxFatalErrors && !_isRecovering) {
        _isRecovering = true;
        SmartDialog.showToast(
          '检测到多次错误，应用可能不稳定',
          displayTime: const Duration(seconds: 3),
        );
        
        // 延迟后重置状态
        Future.delayed(const Duration(seconds: 5), () {
          _isRecovering = false;
          _fatalErrorCount = 0;
        });
      }
    } else {
      _errorCount++;
      
      // 记录到日志服务
      if (_errorCount >= 3) {
        Logger.error('应用级错误 (计数: $_errorCount)', error);
      }
    }
    
    // 上报错误
    _reportError(details, isFatal: isFatal);
  }
  
  /// 检查是否需要重置错误计数
  void _checkErrorReset() {
    if (_lastErrorTime != null && 
        DateTime.now().difference(_lastErrorTime!) > _errorResetTimeout) {
      _errorCount = 0;
      _fatalErrorCount = 0;
    }
  }
  
  /// 上报错误到远程服务
  void _reportError(FlutterErrorDetails details, {bool isFatal = false}) {
    // 这里可以集成 Crashlytics 或其他错误上报服务
    // 暂时只记录日志
    if (isFatal) {
      Logger.error('致命错误', details.exceptionAsString());
    }
  }
  
  /// 重置错误计数
  void reset() {
    _errorCount = 0;
    _fatalErrorCount = 0;
    _isRecovering = false;
  }
  
  /// 清理资源
  void dispose() {
    FlutterError.onError = null;
    PlatformDispatcher.instance.onError = null;
  }
}

// 全局实例
final globalErrorHandler = GlobalErrorHandler();

/// 初始化全局错误处理
void initGlobalErrorHandler() {
  globalErrorHandler.init();
}
