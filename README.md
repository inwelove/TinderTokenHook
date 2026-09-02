# Tinder Token Hook - TrollFools插件

这是一个用于Tinder的dylib插件，可以通过TrollFools注入到Tinder应用中，自动捕获登录token。

## 快速开始（3分钟完成）

### 前提条件
1. iOS设备已安装TrollStore（iOS 14.0 - 17.0）
2. 已安装TrollFools（从TrollStore安装）
3. Tinder应用已安装并登录

### 编译dylib（需要macOS或Linux）
```bash
# 在macOS/Linux上执行
clang -dynamiclib -o TinderTokenHook.dylib TinderTokenHook.m -framework Foundation -fobjc-arc
```

### 注入和使用
1. 将 `TinderTokenHook.dylib` 传输到iOS设备（AirDrop/Filza/SCP）
2. 打开TrollFools → 找到Tinder → 点击"导入Tweak" → 选择dylib文件
3. 重启Tinder，登录后进行任何网络操作
4. 使用Filza查看 `/tmp/tinder_tokens.plist` 获取token

## 功能特性

- ✅ 自动拦截HTTP请求头中的token
- ✅ 捕获X-AUTH-TOKEN、Authorization等关键头
- ✅ 实时保存到多个位置，方便查看
- ✅ 支持TrollFools注入，无需越狱
- ✅ 捕获时间戳，便于追踪

## 捕获的Token类型

1. **X-AUTH-TOKEN** - Tinder主要认证token
2. **Authorization** - 认证头
3. **X-Client-Id** - 客户端ID
4. **X-Client-Session** - 会话ID
5. **X-Task-Lease** - 任务租约
6. 任何包含"token"、"auth"、"session"的头

## 保存位置

插件会将捕获的token保存到以下位置：

1. `/tmp/tinder_tokens.plist` - 主要位置（可通过Filza访问）
2. `/tmp/tinder_tokens.txt` - 纯文本格式，便于阅读
3. `<Tinder Documents>/tinder_tokens.plist` - Tinder文档目录

## 安装TrollStore和TrollFools

### 安装TrollStore
1. 访问 https://github.com/opa334/TrollStore
2. 根据你的iOS版本选择合适的安装方法
3. 安装TrollStore到设备

### 安装TrollFools
1. 打开TrollStore应用
2. 点击"设置" → "安装ldid"
3. 从GitHub下载TrollFools IPA：https://github.com/Lessica/TrollFools/releases
4. 在TrollStore中安装TrollFools IPA

## 编译方法

### 方法一：GitHub Actions自动编译（推荐 - 无需本地环境）

1. 将代码推送到GitHub仓库
2. GitHub Actions会自动编译dylib
3. 在Actions页面下载编译好的`TinderTokenHook.dylib`

**步骤：**
```bash
# 1. 初始化Git仓库
git init
git add .
git commit -m "Initial commit"

# 2. 在GitHub上创建新仓库，然后推送
git remote add origin https://github.com/your-username/your-repo.git
git push -u origin main
```

3. 访问GitHub仓库的Actions页面
4. 点击最新的构建
5. 在Artifacts部分下载`TinderTokenHook.zip`
6. 解压得到`TinderTokenHook.dylib`

### 方法二：在macOS上编译（推荐）

需要安装Xcode Command Line Tools：

```bash
# 编译dylib
clang -dynamiclib -o TinderTokenHook.dylib TinderTokenHook.m -framework Foundation -fobjc-arc

# 或者使用Makefile
make
```

### 方法三：在Windows上编译

1. 安装MinGW-w64或WSL
2. 使用交叉编译器：

```bash
# 使用MinGW-w64
x86_64-w64-mingw32-clang -dynamiclib -o TinderTokenHook.dylib TinderTokenHook.m -framework Foundation

# 或使用WSL中的clang
clang -dynamiclib -o TinderTokenHook.dylib TinderTokenHook.m -framework Foundation
```

### 方法四：使用预编译版本

如果没有编译环境，可以从以下地址下载预编译版本：
- [GitHub Releases](https://github.com/your-repo/releases) (示例链接)

## 使用方法

### 步骤1：传输dylib到iOS设备

将编译好的 `TinderTokenHook.dylib` 传输到iOS设备，可以使用：
- AirDrop
- Filza文件管理器
- iTunes文件共享
- SCP/SFTP

### 步骤2：使用TrollFools注入

1. 确保设备已安装TrollStore和TrollFools
2. 打开TrollFools应用
3. 在应用列表中找到Tinder（`com.cardify.tinder`）
4. 点击"Tinder"进入详情
5. 点击"导入Tweak"或"Import Tweak"
6. 选择 `TinderTokenHook.dylib`
7. TrollFools会自动处理注入
8. 重启Tinder应用

### 步骤3：捕获Token

1. 打开Tinder应用
2. 登录你的账号
3. 进行任何网络操作（浏览、点赞、发送消息等）
4. Token会自动被捕获并保存

### 步骤4：查看捕获的Token

#### 方法A：使用Filza文件管理器
1. 打开Filza
2. 导航到 `/tmp/`
3. 查看 `tinder_tokens.plist` 或 `tinder_tokens.txt`
4. 可以复制内容或分享文件

#### 方法B：使用其他应用读取
其他应用可以通过以下代码读取捕获的token：
```objc
NSDictionary *tokens = [NSDictionary dictionaryWithContentsOfFile:@"/tmp/tinder_tokens.plist"];
NSString *authToken = tokens[@"X-AUTH-TOKEN"];
```

#### 方法C：通过电脑访问
1. 使用iFunBox、iMazing等工具
2. 导航到 `/tmp/` 目录
3. 复制 `tinder_tokens.plist` 文件

## 测试和调试

### 查看日志
1. 连接设备到电脑
2. 打开Xcode → Window → Devices and Simulators
3. 选择你的设备
4. 点击"View Device Logs"
5. 搜索"[TinderTokenHook]"查看日志

### 常见问题

**Q: 为什么没有捕获到token？**
A: 
1. 确保Tinder已登录并进行了网络操作
2. 检查TrollFools是否成功注入（重启Tinder时应看到日志）
3. 查看设备日志是否有错误信息

**Q: 文件保存位置在哪里？**
A: 主要位置是 `/tmp/tinder_tokens.plist`，需要使用Filza等文件管理器访问。

**Q: 可以同时使用多个插件吗？**
A: 可以，但建议只使用一个token提取插件，避免冲突。

**Q: 插件会影响Tinder的正常功能吗？**
A: 不会，插件只拦截HTTP头进行读取，不会修改或发送任何数据。

## 技术细节

### Hook原理
插件使用Method Swizzling技术，hook了 `NSURLRequest` 类的 `allHTTPHeaderFields` 方法。每当Tinder发起网络请求时，我们的hook函数会被调用，从而捕获HTTP请求头中的token。

### 兼容性
- iOS版本：11.0+
- 架构：arm64（iPhone 5s及以后设备）
- Tinder版本：理论上支持所有版本

### 安全性
- 插件只读取token，不会发送到任何外部服务器
- 所有捕获的数据仅保存在本地设备
- 不会修改Tinder的任何功能或数据

## 卸载方法

1. 打开TrollFools
2. 找到Tinder应用
3. 点击"移除Tweak"或"Remove Tweak"
4. 选择 `TinderTokenHook.dylib`
5. 重启Tinder应用

## 文件说明

- `TinderTokenHook.m` - 插件源代码
- `Makefile` - 编译脚本（可选）
- `README.md` - 本说明文档

## 注意事项

1. 仅用于个人学习和研究，请勿用于非法用途
2. Token可能有时效性，需要定期重新捕获
3. Tinder更新后可能需要重新注入插件
4. 建议在测试设备上使用，避免影响主要设备

## 更新日志

### v1.0 (2026-09-02)
- 初始版本
- 支持捕获HTTP请求头中的token
- 保存到多个位置便于访问