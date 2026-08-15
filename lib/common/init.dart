import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:PiliPlus/common/init_platform.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/utils/gstorage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

Future<void> initApp(ScaledWidgetsFlutterBinding binding) async {
  await preInit();
  await initFlutter(binding);
  await init();
  postInit();
}

/// 预初始化
Future<void> preInit() async {
  // 设置平台
  initPlatform();
  // 添加全局错误处理器
  addGlobalErrorHandlers();
}

/// 添加全局错误处理器
void addGlobalErrorHandlers() {
  // 捕获未处理的异常
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };
  
  // 捕获异步错误
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    debugPrint('$stack');
    return true;
  };
}

/// 初始化 Flutter
Future<void> initFlutter(ScaledWidgetsFlutterBinding binding) async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化图片缓存
  initImageCache();
  
  // 设置错误处理
  // 这些会在 main() 中添加
  
  // 保留原生启动画面
  FlutterNativeSplash.preserve(widgetsBinding: binding);
}

/// 初始化
Future<void> init() async {
  // 初始化存储
  await GStorage.init();
  
  // 初始化网络
  await Request.init();
  
  // 初始化主题
  await ThemeUtils.init();
  
  // 加载设置
  await loadSettings();
}

/// 初始化图片缓存
void initImageCache() {
  // 设置图片缓存参数
  // 可以根据需要调整
}

/// 加载设置
Future<void> loadSettings() async {
  // 加载字体大小
  // 加载主题设置
  // 加载其他个性化设置
}

/// 后初始化
void postInit() {
  // 移除原生启动画面
  FlutterNativeSplash.remove();
}

/// 设置图片缓存
void setMemoryCacheSettings() {
  // 可以根据设备性能调整缓存大小
  // UI.systemChromeSetPreferredOrientations(...)
}
