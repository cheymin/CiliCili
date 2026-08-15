# cilicili

一个第三方哔哩哔哩客户端，基于 Flutter 开发。

## 🌟 功能特点

- 🎬 高清视频播放
- 💬 弹幕支持
- 👤 用户登录
- ❤️ 一键三连
- 📺 直播功能
- 🎵 音乐模式
- 🎨 个性化主题

## 📱 平台支持

- Android
- Windows
- Linux
- macOS
- iOS (测试中)

## 🚀 安装

### Android
前往 [Releases](https://github.com/cheymin/cilicili/releases) 下载最新 APK

### Windows
前往 [Releases](https://github.com/cheymin/cilicili/releases) 下载最新版本

### Linux
前往 [Releases](https://github.com/cheymin/cilicili/releases) 下载 AppImage 或 deb 包

## 🛠️ 构建

### 前置要求
- Flutter SDK 3.24.0
- Android Studio / Xcode (iOS/macOS)
- Java 17

### Android 构建
```bash
flutter build apk --release --split-per-abi
```

### Windows 构建
```bash
fastforge package --platform windows --targets exe
```

### Linux 构建
```bash
flutter build linux --release
```

## 📦 发布流程

项目使用 GitHub Actions 自动构建和发布：

1. 推送 tag (`v*`) 到 main 分支
2. Actions 自动触发构建
3. 生成各平台安装包
4. 创建 GitHub Release

### 手动触发
```bash
git tag v3.1.0 -m "Release v3.1.0"
git push origin main
git push origin v3.1.0
```

## 🌐 配置

在根目录创建 `pili_release.json`:
```json
{
  "bili_bili_url": "https://api.bilibili.com",
  "bili_live_url": "wss://broadcastlv.chat.bilibili.com/wss",
  "bili_api_url": "https://api.bilibili.com",
  "bili_player_url": "https://player.bilibili.com",
  "bili_live_api_url": "https://api.live.bilibili.com",
  "bili_room_api_url": "https://api.live.bilibili.com/room/v1/Room",
  "bili_user_api_url": "https://api.bilibili.com/x/space/wbi/acc/info",
  "bili_dynamic_api_url": "https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/space",
  "bili_relation_api_url": "https://api.bilibili.com/x/relation",
  "bili_tag_api_url": "https://api.bilibili.com/x/tag/archives",
  "bili_search_api_url": "https://s.search.bilibili.com",
  "bili_message_api_url": "https://api.bilibili.com/x/im-api",
  "bili_live_room_api_url": "https://api.live.bilibili.com/room/v1/Room",
  "bili_live_room_list_api_url": "https://api.live.bilibili.com/live_user/v1/Master/info",
  "bili_live_room_info_api_url": "https://api.live.bilibili.com/xlive/web-ucenter/v1/xfetter/GetXfetterConf",
  "bili_live_recommend_api_url": "https://api.live.bilibili.com/xlive/web-interface/v1/second/getListByArea",
  "bili_live_area_api_url": "https://api.live.bilibili.com/xlive/web-interface/v1/version/getArea"
}
```

## 📝 注意事项

- 本项目仅供学习研究使用，请勿用于商业用途
- 请遵守哔哩哔哩用户协议和相关法规
- 项目不包含任何付费功能，所有功能免费使用

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

GPL-3.0

## 🙏 致谢

- [bilibili-API-collect](https://github.com/Nemo2011/bilibili-api) - Bilibili API 文档
- [flutter_bilibili_player](https://github.com/florent37/flutter_bilibili_player) - Flutter 播放器

---

Made with ❤️ by [cheymin](https://github.com/cheymin)
