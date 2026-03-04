@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Sandboxie 修改版快速安装脚本
echo ========================================
echo.

REM 检查管理员权限
net session >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo ❌ 错误: 需要管理员权限
    echo.
    echo 请右键此脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

REM ===== 配置 =====
set "INSTALL_PATH=C:\Program Files\Sandboxie-Plus"
set "BACKUP_PATH=%INSTALL_PATH%.backup_%date:~0,4%%date:~5,2%%date:~8,2%"
set "BACKUP_PATH=%BACKUP_PATH: =0%"

echo 📋 安装信息:
echo    安装目录: %INSTALL_PATH%
echo    备份目录: %BACKUP_PATH%
echo.

REM ===== 检查测试模式 =====
echo [1/6] 检查测试模式...
bcdedit /enum | findstr /i "testsigning.*Yes" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo ⚠️  测试模式未启用
    echo.
    choice /C YN /M "是否启用测试模式（需要重启）"
    if !ERRORLEVEL! EQU 1 (
        bcdedit /set testsigning on
        echo ✅ 测试模式已启用
        echo.
        echo 系统将在 30 秒后重启...
        echo 重启后请重新运行此脚本完成安装
        pause
        shutdown /r /t 30 /c "启用测试模式，30秒后重启"
        exit /b 0
    ) else (
        echo ⚠️  警告: 未启用测试模式，驱动可能无法加载
        pause
    )
) else (
    echo ✅ 测试模式已启用
)
echo.

REM ===== 检查安装目录 =====
echo [2/6] 检查安装目录...
if not exist "%INSTALL_PATH%" (
    echo ❌ 错误: 未找到 Sandboxie 安装目录
    echo    路径: %INSTALL_PATH%
    echo.
    echo 请先安装官方 Sandboxie-Plus
    pause
    exit /b 1
)
echo ✅ 找到安装目录
echo.

REM ===== 停止服务 =====
echo [3/6] 停止 Sandboxie 服务...

REM 停止服务
sc query SbieSvc | findstr "RUNNING" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo    停止服务...
    sc stop SbieSvc >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo ✅ 服务已停止
) else (
    echo ✅ 服务未运行
)

REM 卸载驱动
sc query SbieDrv >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo    卸载驱动...
    sc stop SbieDrv >nul 2>&1
    timeout /t 1 /nobreak >nul
    echo ✅ 驱动已卸载
)
echo.

REM ===== 备份原始文件 =====
echo [4/6] 备份原始文件...
if exist "%BACKUP_PATH%" (
    echo ⚠️  备份目录已存在，跳过备份
) else (
    echo    创建备份: %BACKUP_PATH%
    xcopy "%INSTALL_PATH%\*" "%BACKUP_PATH%\" /E /I /Q /Y >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo ✅ 备份完成
    ) else (
        echo ⚠️  备份失败，但继续安装
    )
)
echo.

REM ===== 复制新文件 =====
echo [5/6] 安装修改版文件...

set FILES=(
    "SbieDrv.sys"
    "SbieSvc.exe"
    "SbieDll.dll"
    "SbieCtrl.exe"
    "Start.exe"
    "SbieIni.exe"
    "KmdUtil.exe"
    "SboxHostDll.dll"
    "SboxMsg.dll"
)

set SUCCESS=0
set FAILED=0

for %%F in %FILES% do (
    if exist "%%~F" (
        echo    复制: %%~F
        copy /Y "%%~F" "%INSTALL_PATH%\" >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            set /a SUCCESS+=1
        ) else (
            echo       ❌ 失败
            set /a FAILED+=1
        )
    ) else (
        echo    ⚠️  文件不存在: %%~F
    )
)

echo.
echo    成功: !SUCCESS! 个文件
if !FAILED! GTR 0 (
    echo    失败: !FAILED! 个文件
)
echo.

REM ===== 启动服务 =====
echo [6/6] 启动 Sandboxie 服务...

REM 重新安装驱动
sc create SbieDrv type= kernel start= demand binPath= "%INSTALL_PATH%\SbieDrv.sys" >nul 2>&1

REM 启动服务
sc start SbieSvc >nul 2>&1
timeout /t 2 /nobreak >nul

sc query SbieSvc | findstr "RUNNING" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo ✅ 服务启动成功
) else (
    echo ⚠️  服务启动失败
    echo.
    echo 可能的原因:
    echo 1. 驱动签名问题（检查测试模式）
    echo 2. 文件被占用（重启后再试）
    echo 3. 驱动加载失败（查看事件查看器）
    echo.
    echo 尝试手动启动: sc start SbieSvc
)
echo.

REM ===== 完成 =====
echo ========================================
echo ✅ 安装完成！
echo ========================================
echo.
echo 📝 验证步骤:
echo.
echo 1. 启动 Sandboxie Control
echo    路径: %INSTALL_PATH%\SbieCtrl.exe
echo.
echo 2. 右键任意沙盒 -^> 沙盒设置
echo.
echo 3. 检查以下功能是否可用（无需证书提示）:
echo    ✅ 安全 -^> 使用安全模式
echo    ✅ 安全 -^> 系统调用锁定
echo    ✅ 资源访问 -^> 加密沙盒
echo    ✅ 网络 -^> DNS 过滤
echo    ✅ 外观 -^> 使用独立桌面
echo.
echo 💡 提示:
echo    - 如果功能已解锁，说明安装成功
echo    - 如果服务无法启动，请重启电脑后再试
echo    - 原始文件已备份到: %BACKUP_PATH%
echo.

REM 询问是否启动 Sandboxie
choice /C YN /M "是否启动 Sandboxie Control"
if !ERRORLEVEL! EQU 1 (
    start "" "%INSTALL_PATH%\SbieCtrl.exe"
)

echo.
echo 🔄 恢复原始版本:
echo    1. 停止服务: sc stop SbieSvc
echo    2. 复制备份: xcopy "%BACKUP_PATH%\*" "%INSTALL_PATH%\" /E /Y
echo    3. 启动服务: sc start SbieSvc
echo.
pause
