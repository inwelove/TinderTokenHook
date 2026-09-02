@echo off
echo ========================================
echo Tinder Token Hook 编译脚本 (Windows)
echo ========================================
echo.

REM 检查是否安装了clang
where clang >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到clang编译器
    echo.
    echo 请先安装以下工具之一:
    echo 1. LLVM/Clang: https://releases.llvm.org/
    echo 2. MinGW-w64: https://www.mingw-w64.org/
    echo 3. WSL (Windows Subsystem for Linux)
    echo.
    echo 或者使用macOS/Linux编译后传输到设备
    pause
    exit /b 1
)

echo 使用clang编译TinderTokenHook.dylib...
echo.

REM 编译dylib
clang -dynamiclib -o TinderTokenHook.dylib TinderTokenHook.m -framework Foundation -fobjc-arc

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo 编译成功!
    echo ========================================
    echo 输出文件: TinderTokenHook.dylib
    echo.
    echo 下一步:
    echo 1. 将TinderTokenHook.dylib传输到iOS设备
    echo 2. 使用TrollFools注入到Tinder应用
    echo 3. 重启Tinder，登录后即可捕获token
    echo.
    echo 查看README.md获取详细说明
) else (
    echo.
    echo 编译失败!
    echo.
    echo 可能的原因:
    echo 1. 缺少Foundation框架（需要iOS SDK）
    echo 2. 源代码语法错误
    echo.
    echo 建议使用macOS或Linux编译
)

pause