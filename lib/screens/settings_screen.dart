import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/storage.dart';
import '../utils/theme.dart';
import 'about_screen.dart';

/// 设置页，视觉参考 PiliPlus 的分组 ListTile 结构：
/// 顶部搜索胶囊 + 外观/播放/其它分组，宽屏(电视/平板)左右分栏。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _primaryColors = <Color>[
    Color(0xFFFB7299), // B站粉
    Color(0xFF1A73E8), // 蓝
    Color(0xFF00AEEC), // 天蓝
    Color(0xFF4CAF50), // 绿
    Color(0xFFFF9800), // 橙
    Color(0xFF9C27B0), // 紫
    Color(0xFFF44336), // 红
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tp = context.watch<ThemeProvider>();
    final titleStyle = theme.textTheme.titleMedium;
    final subStyle =
        theme.textTheme.labelMedium?.copyWith(color: cs.outline);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _sectionHeader(context, '外观'),

          // 主题模式
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text('主题模式', style: titleStyle),
            subtitle: Text(_themeModeLabel(tp.themeMode), style: subStyle),
            trailing: SegmentedButton<ThemeMode>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
                ButtonSegment(
                    value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
                ButtonSegment(
                    value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
              ],
              selected: {tp.themeMode},
              onSelectionChanged: (s) => tp.themeMode = s.first,
              showSelectedIcon: false,
            ),
          ),

          // UI 风格
          ListTile(
            leading: const Icon(Icons.style_outlined),
            title: Text('界面风格', style: titleStyle),
            subtitle: Text(
                tp.isApple ? 'Apple iOS 风格' : 'Google Material 风格',
                style: subStyle),
            trailing: Switch(
              value: tp.isApple,
              onChanged: (v) =>
                  tp.uiStyle = v ? UiStyle.apple : UiStyle.google,
            ),
            onTap: () =>
                tp.uiStyle = tp.isApple ? UiStyle.google : UiStyle.apple,
          ),

          // 主题色
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('主题色', style: subStyle),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final c in _primaryColors)
                  _colorDot(context, c, tp),
              ],
            ),
          ),

          const Divider(height: 24),
          _sectionHeader(context, '其它'),

          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text('清除搜索历史', style: titleStyle),
            onTap: () => _clearSearchHistory(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('关于 CiliCili', style: titleStyle),
            subtitle: Text('版本 ${AboutScreen.version}', style: subStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _colorDot(BuildContext context, Color color, ThemeProvider tp) {
    final selected = tp.customPrimaryColor?.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => tp.customPrimaryColor = color,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
        ThemeMode.system => '跟随系统',
      };

  Future<void> _clearSearchHistory(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除搜索历史'),
        content: const Text('确定清空全部搜索历史吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('清除')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      StorageService.searchHistory = const [];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除搜索历史')),
      );
    }
  }
}
