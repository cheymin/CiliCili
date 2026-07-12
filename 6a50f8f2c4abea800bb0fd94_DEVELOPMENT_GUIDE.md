# Cloud Mail App 开发指南（设计系统与架构模板）

> 本文档是一份**可复用的 Flutter 应用开发模板**，教你如何做出和 Cloud Mail App 一样质感的应用——双风格设计系统（Google Material 3 + Apple iOS）、玻璃拟态、流畅交互、优雅动画。任何类型的 App 都可以套用这套架构。

---

## 目录

1. [核心设计哲学](#1-核心设计哲学)
2. [项目架构](#2-项目架构)
3. [双风格设计系统](#3-双风格设计系统)
4. [主题与个性化](#4-主题与个性化)
5. [页面布局规范](#5-页面布局规范)
6. [组件样式库](#6-组件样式库)
7. [交互与动效](#7-交互与动效)
8. [数据层与状态管理](#8-数据层与状态管理)
9. [网络与缓存](#9-网络与缓存)
10. [初始化流程](#10-初始化流程)
11. [应用内更新](#11-应用内更新)
12. [WebDAV 同步](#12-webdav-同步)
13. [代码规范](#13-代码规范)
14. [快速开始模板](#14-快速开始模板)

---

## 1. 核心设计哲学

### 1.1 设计原则

- **双风格一等公民**：Google Material 3 和 Apple iOS 风格都是一等公民，用户可以随时切换。不是"一个主风格 + 另一个凑数"，而是两套都做得精致。
- **内容优先**：界面服务于内容，不是内容挤在界面里。卡片、列表、间距都是为了让内容呼吸。
- **轻盈质感**：毛玻璃、柔和阴影、微妙边框——有质感但不厚重。
- **即时反馈**：每一个操作都有视觉反馈——按钮按下态、列表滑动回弹、加载骨架屏、操作完成 SnackBar。
- **渐进式披露**：复杂功能折叠起来，需要时才展开（设置页的分组卡片、可折叠面板）。

### 1.2 两种风格的核心差异速查表

| 维度 | Google Material 3 | Apple iOS |
|------|-------------------|-----------|
| 主色 | `#1A73E8` Google 蓝 | `#007AFF` iOS 蓝 |
| 背景色 | `#FEFBFF` 偏暖白 | `#F2F2F7` 系统灰 |
| AppBar 标题 | 22sp / 常规字重 / 靠左 | 34sp / 粗体 / 靠左（大标题） |
| 卡片圆角 | 12px | 10px |
| 按钮形状 | 胶囊形（9999 圆角） | 10px 圆角矩形 |
| 分割线 | 1px 实线 | 0.5px 细线 |
| 输入框 | 填充式 + 圆角 12px | 填充式 + 圆角 10px |
| 列表项内边距 | vertical 8 | vertical 10 |
| 字重体系 | Regular / Medium / Bold 三级 | Semibold / Bold 偏粗 |
| FAB 阴影 | elevation 3 | elevation 1 |
| 图标尺寸 | 24dp | 22dp |

---

## 2. 项目架构

### 2.1 目录结构

```
lib/
├── main.dart                 # 应用入口 + 路由 + 主题注入
├── models/                   # 数据模型（纯 Dart，无 Flutter 依赖）
│   ├── email.dart
│   └── contact.dart
├── services/                 # 业务服务（API 调用、同步、更新等）
│   ├── api_service.dart      # 核心 API 客户端
│   ├── ai_service.dart
│   ├── update_service.dart
│   ├── contact_sync.dart
│   ├── app_sync.dart
│   └── webdav_service.dart
├── screens/                  # 页面（按功能模块分子目录）
│   ├── login_screen.dart
│   ├── email/
│   │   ├── mailbox_screen.dart
│   │   ├── email_detail_screen.dart
│   │   └── compose_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   ├── accounts/
│   ├── ai/
│   ├── contacts/
│   └── update/
└── utils/                    # 工具类（可复用，无业务依赖）
    ├── theme.dart            # 主题系统 + ThemeProvider
    ├── storage.dart          # 本地存储封装
    └── glass.dart            # 毛玻璃效果
```

### 2.2 架构原则

- **分层清晰**：models → services → screens → utils，依赖单向流动
- **胖页面瘦服务**：页面管状态和 UI，服务只管数据获取，不掺 UI 逻辑
- **Provider 做全局状态**：只有主题这种真正全局的才用 Provider，页面内状态用 StatefulWidget
- **静态方法工具类**：StorageService、ErrorMessages 等用静态方法，简单直接

### 2.3 main.dart 标准写法

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'App Name',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.resolve(themeProvider.uiStyle, Brightness.light,
          customPrimary: themeProvider.customPrimaryColor,
          fontFamily: themeProvider.customFontFamily),
      darkTheme: AppTheme.resolve(themeProvider.uiStyle, Brightness.dark,
          customPrimary: themeProvider.customPrimaryColor,
          fontFamily: themeProvider.customFontFamily),
      themeMode: themeProvider.themeMode,
      home: const _LaunchChecker(),
    );
  }
}
```

---

## 3. 双风格设计系统

### 3.1 架构：UiStyle 枚举 + AppTheme 静态方法

核心文件：[`lib/utils/theme.dart`](file:///workspace/lib/utils/theme.dart)

```dart
enum UiStyle { google, apple }

class ThemeProvider extends ChangeNotifier {
  UiStyle _uiStyle = UiStyle.google;
  ThemeMode _themeMode = ThemeMode.system;
  // ... 个性化字段
}

class AppTheme {
  static ThemeData googleLight() { ... }
  static ThemeData googleDark() { ... }
  static ThemeData appleLight() { ... }
  static ThemeData appleDark() { ... }

  static ThemeData resolve(UiStyle style, Brightness brightness, {
    Color? customPrimary,
    String? fontFamily,
  }) { ... }
}
```

**关键设计**：`AppTheme.resolve()` 是唯一入口，内部根据 style + brightness 选基础主题，再叠加个性化覆盖（自定义主色、自定义字体）。

### 3.2 Google Material 3 主题要点

**颜色（浅色）**：
- Primary: `#1A73E8`（Google Blue）
- Surface: `#FEFBFF`（偏暖的白）
- SurfaceVariant: `#E1E2EC`
- OnSurfaceVariant: `#44474F`
- Outline: `#74777F`

**排版**：
- 使用 M3 完整 TextTheme（display/headline/title/body/label 各 3 级）
- 标题字重偏 Regular（w400），强调用 Medium（w500）
- 行高紧凑但不拥挤（body 1.5, headline 1.25~1.33）

**组件**：
- 按钮：胶囊形（borderRadius: 9999）
- 卡片：圆角 12px，elevation 0（完全扁平）
- 输入框：填充式（filled: true），无默认边框，聚焦时 2px 主色边框
- SnackBar：floating 类型，圆角 8px
- FAB：圆形，elevation 3

### 3.3 Apple iOS 主题要点

**颜色（浅色）**：
- Primary: `#007AFF`（iOS Blue）
- Scaffold 背景: `#F2F2F7`（系统组背景色）
- Surface: 纯白（卡片/列表背景）
- SurfaceVariant: `#E5E5EA`
- OnSurfaceVariant: `#3C3C43`
- 分割线: `0.5px #E5E5EA`

**排版**：
- 大标题：34sp / Bold（类似 iOS large title）
- 字重偏粗：标题用 w600/w700
- SF Pro 风格的字重体系

**组件**：
- 按钮：圆角 10px 的矩形（不是胶囊）
- 卡片：圆角 10px
- 输入框：填充式，圆角 10px
- 分割线：0.5px 极细（iOS 标志性细节）
- 列表项 vertical padding 更大（10px vs 8px）
- FAB：elevation 1（更柔和）

### 3.4 深色模式

两套风格都有完整的深色主题：
- Google 深色：Surface `#1B1B1F`，Primary `#A4C8FF`（浅蓝）
- Apple 深色：Scaffold 纯黑 `#000000`，Surface `#1C1C1E`，Primary `#0A84FF`

**深色模式原则**：
- 文字颜色从纯白到次级灰分级
- 卡片用比背景稍亮的色（不是纯黑卡片）
- 主色变浅（在深色背景上更可见）
- 分割线更暗但仍可辨

### 3.5 在代码中判断风格

```dart
final isGoogle = context.watch<ThemeProvider>().isGoogle;
// 或者
final uiStyle = context.watch<ThemeProvider>().uiStyle;
```

**什么时候需要判断风格**：
- AppBar 行为（Google 用滚动隐藏，Apple 用大标题）
- 列表项的具体布局（头像位置、间距）
- 手势交互（左滑操作的样式）
- 过渡动画（Material 用 fade-through，Apple 用横向滑入）

---

## 4. 主题与个性化

### 4.1 ThemeProvider 全局状态

```dart
class ThemeProvider extends ChangeNotifier {
  // 基础
  ThemeMode _themeMode = ThemeMode.system;
  UiStyle _uiStyle = UiStyle.google;

  // 个性化
  Color? _customPrimaryColor;    // 自定义主题色
  String? _customFontFamily;     // 自定义字体家族名
  String? _customFontPath;       // 自定义字体文件路径（持久化）
  String? _customBackgroundImage;// 自定义背景图

  // 每个属性都有 getter + setter
  // setter 同时更新 StorageService + notifyListeners()
}
```

### 4.2 自定义主题色算法

当用户选了一个自定义颜色，不只是改 primary——而是生成一整套协调色：

```dart
theme.colorScheme.copyWith(
  primary: customPrimary,
  primaryContainer: _lighten(customPrimary, 0.85),  // 浅 85%
  onPrimaryContainer: _darken(customPrimary, 0.5),  // 深 50%
  inversePrimary: _lighten(customPrimary, 0.3),     // 浅 30%
  surfaceTint: customPrimary,
)
```

工具函数：
```dart
static Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}
```

### 4.3 自定义字体

- 支持用户导入字体文件（.ttf/.otf）
- 文件复制到应用文档目录持久化（`getApplicationDocumentsDirectory()/fonts/`）
- 用 `FontLoader` 动态加载到 Flutter 字体注册表
- 切换字体只改 `fontFamily`，不重新加载文件

### 4.4 StorageService 持久化

所有设置都通过 `StorageService` 持久化到 SharedPreferences：

```dart
StorageService.uiStyle          // String: 'google' | 'apple'
StorageService.themeMode        // String: 'light' | 'dark' | 'system'
StorageService.customPrimaryColor  // int? (Color.value)
StorageService.customFontFamily    // String?
StorageService.customFontPath      // String?
StorageService.customBackgroundImage // String?
```

---

## 5. 页面布局规范

### 5.1 标准页面骨架

```dart
Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  appBar: AppBar(
    title: Text('页面标题'),
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  body: ListView(  // 或 CustomScrollView
    padding: const EdgeInsets.all(16),
    children: [
      _buildSectionTitle('分组标题'),
      _buildCard([ ... ]),
      const SizedBox(height: 24),
      // ... 更多分组
    ],
  ),
)
```

### 5.2 分组卡片布局

这是设置页、详情页等页面的**核心布局模式**：

```
┌─────────────────────────────┐
│ 分组标题                      │  ← _buildSectionTitle()
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  ListTile / 自定义行    │ │  ← _buildCard([...])
│ │  Divider(indent: 56)   │ │
│ │  ListTile               │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

辅助方法：

```dart
Widget _buildSectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    ),
  );
}

Widget _buildCard(List<Widget> children) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12), // 或 10，看风格
      border: Border.all(color: cs.outlineVariant, width: 0.5),
    ),
    child: Column(children: children),
  );
}

Widget _buildTile({...}) {
  return ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: subtitle != null ? Text(subtitle!) : null,
    trailing: trailing ?? Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
    onTap: onTap,
  );
}
```

### 5.3 AppBar 的两种风格

**Google 风格**：
- 标题：22sp，常规字重
- 左对齐
- 背景透明
- 滚动时有 Tab 或操作

**Apple 风格**：
- 大标题：34sp，粗体
- 左对齐（类似 `navigationBarTitleDisplayMode: .large`）
- 背景和 Scaffold 一致
- 滚动时标题自动缩小

### 5.4 间距系统

使用 4/8/12/16/24 的间距体系：
- 4px：图标和文字的微小间距
- 8px：列表项内部、卡片内元素之间
- 12px：卡片内边距
- 16px：页面左右边距、卡片之间
- 24px：大分组之间

---

## 6. 组件样式库

### 6.1 按钮

| 类型 | 用途 | Google 样式 | Apple 样式 |
|------|------|-------------|------------|
| FilledButton | 主操作 | 胶囊，填充主色 | 10px 圆角，填充主色 |
| ElevatedButton | 次主操作 | 胶囊，elevation 0 | 10px 圆角 |
| OutlinedButton | 次要操作 | 胶囊，描边 | 10px 圆角，描边 |
| TextButton | 三级操作 | 胶囊，纯文字 | 无形状，纯文字 |
| FAB | 悬浮主操作 | 圆形，elevation 3 | 圆形，elevation 1 |
| IconButton | 工具栏操作 | 24dp 图标 | 22dp 图标 |

**统一写法**（通过主题配置，使用时不用写样式）：

```dart
FilledButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.add, size: 18),
  label: const Text('新建'),
  style: FilledButton.styleFrom(minimumSize: Size.fromHeight(44)),
)
```

### 6.2 输入框

```dart
TextField(
  decoration: InputDecoration(
    hintText: '请输入...',
    prefixIcon: Icon(Icons.search, size: 20),
    suffixIcon: _isSearching
        ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2))
        : null,
  ),
)
```

主题已配置好：
- 填充式（filled: true）
- 默认状态无边框
- 聚焦时 2px 主色边框
- 圆角：Google 12px / Apple 10px

### 6.3 卡片

- **扁平卡片**：elevation 0，靠边框和背景色区分（主要样式）
- **高亮卡片**：主色边框 + 主色容器背景（用于"最新版本"、"推荐"等强调项）
- **状态卡片**：大图标 + 文字说明（成功/失败/空状态）

### 6.4 列表项 ListTile

```dart
ListTile(
  leading: Icon(icon, color: cs.primary, size: 22),
  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
  subtitle: Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
  trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
  onTap: () {},
)
```

**分割线**：`Divider(height: 1, indent: 56)` —— 左侧缩进和图标对齐（Apple 风格缩进更小）。

### 6.5 毛玻璃效果

核心文件：[`lib/utils/glass.dart`](file:///workspace/lib/utils/glass.dart)

```dart
GlassBox(
  isDark: isDark,
  blur: 20,
  opacity: 0.6,
  radius: 16,
  padding: const EdgeInsets.all(16),
  child: Text('毛玻璃容器'),
)
```

**原理**：`BackdropFilter` + `ImageFilter.blur` + 半透明白色/黑色背景 + 0.5px 边框。

**使用场景**：
- 浮动工具栏
- 底部操作栏
- 弹窗背景
- 覆盖在图片上的文字层

### 6.6 头像与字母头像

```dart
Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: AppTheme.accountColor(email),
    shape: BoxShape.circle,
  ),
  child: Center(
    child: Text(
      initial,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  ),
)
```

颜色分配：基于邮箱哈希取模，从 9 色预设板中选一个，保证同一邮箱始终同色。

---

## 7. 交互与动效

### 7.1 操作反馈

**点击反馈**：
- 按钮：`InkWell` / `InkResponse` 的水波纹（Material 风格自动）
- 卡片/列表项：整体可点击，有轻微按压感
- 禁用状态：透明度降低 + 灰色

**长按反馈**：
- 列表项长按进入多选模式
- 触觉反馈（可选，`HapticFeedback.mediumImpact()`）

### 7.2 加载状态

**骨架屏 shimmer**（`shimmer` 包）：
- 进入页面时先显示骨架
- 数据加载后替换为真实内容
- 骨架形状和真实布局一致（卡片、圆形头像、文字条）

**浮动加载**：
- 下拉刷新：`pull_to_refresh` 或 `RefreshIndicator`
- 加载更多：列表底部显示 CircularProgressIndicator

### 7.3 SnackBar 反馈

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('操作成功')),
);
```

- 操作成功/失败后必弹
- 浮动样式（`SnackBarBehavior.floating`）
- 2~4 秒自动消失
- 重要操作可加 `action` 按钮（如"撤销"）

### 7.4 页面过渡

- **主路由**：Material 默认过渡（从下往上滑入）
- **详情页**：从右往左滑入（Apple 风格）或淡入（Material）
- **弹窗**：BottomSheet 从底部滑入，AlertDialog 缩放淡入

### 7.5 动画细节

- **缩放交互**：`InteractiveViewer` 包裹可缩放内容，minScale 0.3 / maxScale 5.0，boundaryMargin infinite
- **烟花效果**：`CustomPainter` + `AnimationController`，粒子爆炸 + 重力下落
- **进度条**：`LinearProgressIndicator` 平滑动画

---

## 8. 数据层与状态管理

### 8.1 Model 层

纯 Dart 类，带 `fromJson`/`toJson`：

```dart
class Email {
  final int emailId;
  final String subject;
  final String sendEmail;
  // ...

  factory Email.fromJson(Map<String, dynamic> json) => Email(
    emailId: json['emailId'] as int,
    subject: json['subject'] as String? ?? '',
    // ...
  );
}
```

**响应包装**：

```dart
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code >= 200 && code < 300;

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? Function(dynamic)? dataParser) { ... }
}
```

### 8.2 Service 层

```dart
class CloudMailApi {
  final String baseUrl;
  String? token;

  Future<ApiResponse<List<Email>>> getEmailList({...}) async {
    final response = await http.get(Uri.parse(_url('/email/list')), headers: _headers);
    return _parseListResponse(response, Email.fromJson);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

### 8.3 状态管理策略

| 状态类型 | 管理方式 | 示例 |
|---------|----------|------|
| 全局主题/设置 | Provider (ChangeNotifier) | ThemeProvider |
| 页面内状态 | StatefulWidget setState | 列表数据、加载状态 |
| 列表选中状态 | Set + 局部 setState | 多选模式 |
| 表单输入 | TextEditingController | 登录表单 |
| 未来快照 | FutureBuilder / StreamBuilder | 异步数据展示 |

**原则**：能用 setState 就不用 Provider，能不用包就不加包。简单直接优先。

---

## 9. 网络与缓存

### 9.1 缓存优先策略

进入页面时：
1. 先读本地缓存 → 立刻渲染（用户看到内容）
2. 后台请求最新数据 → 刷新 UI（用户看到更新）

```dart
Future<void> _loadData() async {
  // 1. 先显示缓存
  final cached = StorageService.getCache(_cacheKey);
  if (cached != null) {
    setState(() {
      _items = cached;
      _loading = false;
    });
  }

  // 2. 后台刷新
  final response = await _api.fetchData();
  if (response.isSuccess && response.data != null) {
    StorageService.setCache(_cacheKey, response.data!);
    if (mounted) {
      setState(() => _items = response.data!);
    }
  }
}
```

### 9.2 分页加载（游标分页）

```dart
int? _lastItemId; // 游标
bool _hasMore = true;
bool _loadingMore = false;

Future<void> _loadMore() async {
  if (_loadingMore || !_hasMore) return;
  setState(() => _loadingMore = true);
  final response = await _api.fetchMore(cursor: _lastItemId);
  if (response.isSuccess && response.data != null) {
    final list = response.data!;
    setState(() {
      _items.addAll(list);
      _lastItemId = list.last.id;
      _hasMore = list.length >= _pageSize;
      _loadingMore = false;
    });
  }
}
```

### 9.3 错误处理

```dart
try {
  final response = await _api.someCall();
  if (response.isSuccess) {
    // 成功
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ErrorMessages.fromException(e))),
  );
}
```

ErrorMessages 分类处理网络错误、超时、认证错误、服务器错误。

---

## 10. 初始化流程

### 10.1 多步骤引导

使用 PageView + 步骤指示器：

```dart
// 步骤：欢迎(0) → 服务器(1) → 登录(2) → 个性化(3) → 完成动画(4)
int _currentStep = 0;
late final PageController _pageController;

void _goToStep(int step) {
  setState(() => _currentStep = step);
  _pageController.animateToPage(step,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut);
}
```

**进度指示器**：小圆点，当前步高亮，已完成步变实色。

**步骤设计原则**：
- 每步一个核心任务，不拥挤
- 可以跳过的步骤明确标注"跳过"
- 完成后有庆祝感（烟花动画 🎆）
- 老用户自动跳过已完成的步骤

### 10.2 烟花动画

核心实现：
- `AnimationController` 控制总时长（2 秒）
- `CustomPainter` 绘制粒子
- 3 波交错爆炸（0ms / 400ms / 800ms）
- 每波约 42 个粒子，随机颜色、角度、初速度
- 重力加速度模拟下落
- 粒子半径随时间缩小至消失

```dart
class _FireworksPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Particle> _particles = [];

  @override
  void paint(Canvas canvas, Size size) { ... }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

## 11. 应用内更新

### 11.1 检查更新

- 调 GitHub Releases API（`GET /repos/{owner}/{repo}/releases/latest`）
- 语义化版本比较（`compareVersions`）
- 无更新 / 有更新 / 网络错误 三种状态

### 11.2 镜像源系统

**内置镜像**（解决国内下载慢）：
```
direct                  GitHub 直连
https://ghproxy.com/
https://mirror.ghproxy.com/
https://github.moeyy.xyz/
https://kkgithub.com/    （域名替换型）
https://gh.api.99988866.xyz/
https://hub.gitmirror.com/
```

**URL 拼接逻辑**：
- `direct`：原样返回
- `kkgithub.com`：把 `github.com` 替换为 `kkgithub.com`
- 其他：前缀 + 原始 URL

### 11.3 测速与选择

- 并发对所有镜像发 HEAD 请求（`dio.head(url)`）
- 5 秒超时
- 显示延迟（ms），按延迟排序
- 最低延迟标"推荐"徽章
- 颜色：<500ms 绿色，<1500ms 橙色，更久/超时红色

### 11.4 应用内下载

- `dio.download()` 下载到临时目录
- `onReceiveProgress` 回调实时更新进度
- `CancelToken` 支持取消
- 进度条 UI：标题 + 百分比 + 已下载/总大小 + 取消按钮
- 下载完成自动 `OpenFile.open()` 触发系统安装
- 失败显示错误 + 重试

### 11.5 权限配置

AndroidManifest.xml 需要：
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```

---

## 12. WebDAV 同步

### 12.1 WebDavService 基础

```dart
class WebDavService {
  final WebDavConfig config;

  Future<bool> testConnection() async { ... }  // PROPFIND
  Future<bool> uploadString(String filename, String content) async { ... } // PUT
  Future<String?> downloadString(String filename) async { ... } // GET
  Future<bool> ensureDir() async { ... } // MKCOL
}
```

### 12.2 同步服务模式

每种可同步数据都有独立的 Sync 服务：

```dart
class ContactSync {
  static Future<SyncResult> upload() async { ... }
  static Future<SyncResult> download() async { ... }
  static Future<SyncResult> sync() async {  // 双向：先下载合并，再上传
    final dl = await download();
    if (!dl.success) return dl;
    final ul = await upload();
    return SyncResult(...);
  }
}

class AppSync {
  static Map<String, dynamic> exportSettings() { ... }
  static int importSettings(Map<String, dynamic> data) { ... }
  static Future<SyncResult> uploadSettings() async { ... }
  static Future<SyncResult> downloadSettings() async { ... }
}
```

### 12.3 全量设置同步清单

`AppSync.exportSettings()` 导出所有用户可修改的设置：
- uiStyle, themeMode
- showSenderAvatar, autoLoadImages
- openaiApiKey, openaiBaseUrl, openaiModel
- customPrimaryColor, customFontFamily
- rememberLogin, chatHistory

---

## 13. 代码规范

### 13.1 命名

- 文件名：`snake_case.dart`（如 `email_detail_screen.dart`）
- 类名：`PascalCase`（如 `EmailDetailScreen`）
- 变量/方法：`camelCase`（如 `_loadEmails`）
- 私有成员：下划线前缀（`_loading`, `_emails`）
- 常量：`lowerCamelCase`（不是 SCREAMING_SNAKE_CASE，Dart 惯例）

### 13.2 文件结构

```dart
// 1. imports（dart: 先，再 package:，再相对路径）
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/email.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

// 2. 主类（StatefulWidget + State）
class MyScreen extends StatefulWidget { ... }
class _MyScreenState extends State<MyScreen> { ... }

// 3. 辅助类/辅助方法（私有的）
class _MyHelperWidget extends StatelessWidget { ... }
```

### 13.3 异步与 mounted 检查

**永远在异步回调前检查 mounted**：

```dart
// 错误做法
setState(() => _loading = true);
final result = await _api.fetch();
setState(() { ... }); // 页面可能已经销毁

// 正确做法
setState(() => _loading = true);
final result = await _api.fetch();
if (mounted) {
  setState(() { ... });
}
```

### 13.4 lint 配置

使用 `flutter_lints`，关键规则：
- `prefer_const_constructors`（尽量用 const）
- `use_build_context_synchronously`（异步 gap 检查）
- `unnecessary_non_null_assertion`（避免多余的 !）
- `prefer_final_fields`（字段能 final 就 final）

---

## 14. 快速开始模板

用这套系统从零搭一个新 App，只需要以下步骤：

### 步骤 1：pubspec.yaml 依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  intl: ^0.18.1
  url_launcher: ^6.2.4
  path_provider: ^2.1.2
  dio: ^5.4.0
  package_info_plus: ^8.0.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 步骤 2：复制核心文件

从本项目复制这些文件（改改类名即可）：
- `lib/utils/theme.dart` —— 完整的双风格主题系统
- `lib/utils/storage.dart` —— 本地存储封装
- `lib/utils/glass.dart` —— 毛玻璃效果
- `lib/main.dart` —— 应用入口模板

### 步骤 3：搭建第一个页面

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用 _buildSectionTitle + _buildCard + _buildTile 组合
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 步骤 4：添加设置页（切换风格/主题/个性化）

参考 `settings_screen.dart` 的结构，把风格切换、深浅模式、主题色、字体等控件加进去。ThemeProvider 已经做好了，只要调 set 方法就行。

### 步骤 5：接入你的数据

- 创建 model 类（`fromJson`/`toJson`）
- 创建 service 类（API 调用）
- 创建 screen 页面（套用列表/详情模板）
- 用 StorageService 做缓存

---

## 附录：设计 Tokens 速查

### 颜色

| Token | Google Light | Google Dark | Apple Light | Apple Dark |
|-------|-------------|-------------|-------------|------------|
| primary | `#1A73E8` | `#A4C8FF` | `#007AFF` | `#0A84FF` |
| surface | `#FEFBFF` | `#1B1B1F` | `#FFFFFF` | `#1C1C1E` |
| background | `#FEFBFF` | `#1B1B1F` | `#F2F2F7` | `#000000` |
| surfaceVariant | `#E1E2EC` | `#44474F` | `#E5E5EA` | `#2C2C2E` |
| onSurfaceVariant | `#44474F` | `#C4C6D0` | `#3C3C43` | `#EBEBF5` |
| outline | `#74777F` | `#8E9099` | `#C6C6C8` | `#38383A` |

### 圆角

| 组件 | Google | Apple |
|------|--------|-------|
| 按钮 (胶囊) | 9999 | 10 |
| 卡片 | 12 | 10 |
| 输入框 | 12 | 10 |
| SnackBar | 8 | 10 |
| Chip | 8 | 8 |
| 头像 | 圆形 | 圆形 |

### 字号

| 层级 | Google | Apple |
|------|--------|-------|
| displayLarge | 57 / w400 | 34 / w700 |
| headlineLarge | 32 / w400 | 28 / w700 |
| titleLarge | 22 / w500 | 20 / w600 |
| bodyLarge | 16 / w400 | 16 / w400 |
| bodyMedium | 14 / w400 | 14 / w400 |
| bodySmall | 12 / w400 | 12 / w400 |
| labelLarge | 14 / w500 | 14 / w600 |

---

> 💡 **使用提示**：开发新 App 时，把这份文档丢给 AI，告诉它"按照 DEVELOPMENT_GUIDE.md 的设计系统和架构来写"，生成的代码就会和 Cloud Mail App 一模一样的质感。
