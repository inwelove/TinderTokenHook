# Tinder Token Hook 快速开始指南

## 3分钟快速提取Tinder Token

### 前提条件
- iOS设备已安装TrollStore
- 已安装TrollFools
- Tinder应用已登录

### 步骤1：获取编译好的dylib

#### 方法A：使用GitHub Actions（推荐）
1. 将`TinderTokenHook`文件夹上传到GitHub
2. 等待GitHub Actions自动编译
3. 在Actions页面下载`TinderTokenHook.dylib`

#### 方法B：本地编译（需要macOS）
```bash
cd TinderTokenHook
clang -dynamiclib -o TinderTokenHook.dylib TinderTokenHook.m -framework Foundation -fobjc-arc
```

### 步骤2：传输到iOS设备
- 使用AirDrop发送`TinderTokenHook.dylib`到设备
- 或使用Filza文件管理器传输
- 或通过SCP/SFTP传输

### 步骤3：使用TrollFools注入
1. 打开TrollFools
2. 找到Tinder（`com.cardify.tinder`）
3. 点击"导入Tweak"
4. 选择`TinderTokenHook.dylib`
5. 重启Tinder

### 步骤4：捕获Token
1. 打开Tinder并登录
2. 进行任何网络操作（浏览、点赞等）
3. 使用Filza查看`/tmp/tinder_tokens.plist`

### 步骤5：使用Token
1. 打开`/tmp/tinder_tokens.plist`
2. 复制`X-AUTH-TOKEN`字段的值
3. 将token用于云机登录

## 常见问题

**Q: 如何查看捕获的token？**
A: 使用Filza文件管理器导航到`/tmp/`目录，查看`tinder_tokens.plist`文件。

**Q: Token保存在哪里？**
A: 主要位置：`/tmp/tinder_tokens.plist`
备份位置：`/tmp/tinder_tokens.txt`

**Q: 如何卸载插件？**
A: 在TrollFools中移除Tinder的tweak即可。

**Q: 插件会影响Tinder功能吗？**
A: 不会，插件只读取token，不修改任何功能。

## 技术支持
- 查看`README.md`获取详细说明
- 查看`TinderTokenHook.m`了解源代码
- 在GitHub上提交issue获取帮助