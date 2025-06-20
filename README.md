# GEEKPARK

`GEEKPARK` 是一个使用 Flutter 框架构建的跨平台应用程序，支持 Android、iOS、Windows、Linux 和 macOS 等多个主流平台。该项目具备丰富的新闻浏览与交互功能，为用户提供了统一且流畅的新闻阅读体验。

## 功能特性
1. **新闻展示**
    - **首页聚合**：在首页展示热门新闻和最新新闻，方便用户快速了解最新资讯。
    - **分类筛选**：提供多种新闻分类，如综合、人工智能、新能源汽车、财经等，用户可按需选择浏览。
    - **详情查看**：点击新闻条目可查看详细内容，包括封面图片、标题、正文、作者信息和发布时间等。
2. **状态管理**
    - 运用 `provider` 库进行状态管理，保证数据一致性和可维护性。
    - 支持新闻数据加载、错误处理和网络状态检测，实时反馈应用状态。
3. **数据存储与网络请求**
    - **本地存储**：借助 `sqflite` 库实现本地数据库操作，支持新闻数据缓存和离线阅读。
    - **网络请求**：使用 `http` 和 `dio` 库进行网络请求，获取最新新闻数据。
4. **用户交互**
    - **评论互动**：用户可对新闻进行评论和点赞，增强参与度。
    - **搜索功能**：支持关键词搜索，便于快速找到感兴趣的新闻。
    - **下拉刷新**：提供下拉刷新功能，及时获取最新新闻。
5. **网络连接检测**
    - 利用 `connectivity_plus` 库检测网络连接状态，并在界面提示，确保不同网络环境下正常使用。

## 项目结构
```
GEEKPARK/
├── .gitignore
├── README.md
├── analysis_options.yaml
├── pubspec.yaml
├── test/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── web/
├── android/
├── linux/
├── macos/
├── ios/
└── windows/
```
- **`lib` 目录**：包含项目核心代码，如界面、逻辑和数据模型等。
- **`android`、`ios`、`windows`、`linux` 和 `macos` 目录**：包含各平台配置文件和原生代码。
- **`web` 目录**：包含 Web 平台配置文件和资源。
- **`test` 目录**：包含项目测试代码。

## 技术选型
1. **框架**：Flutter
2. **状态管理**：`provider`
3. **网络请求**：`http`、`dio`
4. **本地存储**：`sqflite`、`shared_preferences`
5. **UI 组件**：`cached_network_image`、`flutter_html`、`pull_to_refresh`
6. **工具类**：`intl`、`connectivity_plus`

## 开发环境
- **开发语言**：Dart
- **开发工具**：Visual Studio Code 或 Android Studio
- **依赖管理**：Pubspec.yaml

## 部署与运行
1. 确保已安装 Flutter SDK 和相关开发环境。
2. 克隆项目代码到本地：
```bash
git clone <项目仓库地址>
```
3. 进入项目目录，安装依赖：
```bash
flutter pub get
```
4. 选择目标平台，运行项目：
```bash
flutter run
```

## 贡献指南
我们欢迎社区开发者为 `GEEKPARK` 项目贡献代码。如果您想参与项目开发，请遵循以下步骤：
1.  Fork 本仓库到您的 GitHub 账户。
2. 创建一个新的分支用于您的功能开发或问题修复：
```bash
git checkout -b feature/your-feature-name
```
3. 提交您的代码更改，并添加清晰的提交信息：
```bash
git commit -m "Add your detailed commit message here"
```
4. 将您的分支推送到您的 Fork 仓库：
```bash
git push origin feature/your-feature-name
```
5. 在 GitHub 上创建一个 Pull Request，详细描述您的更改和目的。

## 联系我们
如果您在使用过程中遇到问题，或者有任何建议和反馈，请通过以下方式联系我们：
- 提交 GitHub Issues：[https://github.com/your-repo/wei_sr/issues](https://github.com/nwt-q/GEEKPARK/issues)
- 发送邮件至：[your-email@example.com](mailto:3178146280l@qq.com)

## 许可证
本项目采用 [MIT 许可证](LICENSE) 进行授权。
