# Reader iOS

一款基于 iOS 的浏览阅读工具。本项目本质上是一个套着 iOS 外壳的浏览器，专为提升网页阅读体验而设计。

## 功能特性 (Features)

- **自定义网址**: 支持添加任意网址，构建专属的阅读列表。
- **沉浸式阅读**: 提供沉浸模式（Immersive Mode），自动隐藏干扰元素，专注于内容。
- **阅读进度记忆**: 自动记录上次阅读位置，随时继续阅读。
- **后台支持**: 支持后台运行
- **浏览器内核**: 基于 `WKWebView` 构建，保留原汁原味的网页渲染。

## 许可证 (License)

本项目采用 **AGPL-3.0** 许可证。

## 安装与使用 (Installation & Usage)

**本项目仅供个人学习与使用，未上架 App Store。**

### 方式一：GitHub Releases (自签安装)
1. 在 [Releases](../../releases) 页面下载最新的 `.ipa` 文件。
2. 使用自签工具（如 AltStore, Sideloadly, 爱思助手等）将 `.ipa` 安装到您的 iOS 设备上。
   - 注意：由于未签名，您必须拥有有效的 Apple ID 用于生成个人证书。
   - 免费开发者账号通常有 7 天有效期，过期后需重新签名。

### 方式二：源码编译
1. 克隆本项目：
   ```bash
   git clone <repository-url>
   ```
2. 使用 Xcode 打开 `阅读.xcodeproj`。
3. 修改 "Signing & Capabilities" 中的 Team 为您自己的开发者账号。
4. 连接真机进行编译运行。

## 致谢 (Acknowledgements)

感谢 [hectorqin/reader](https://github.com/hectorqin/reader) 
