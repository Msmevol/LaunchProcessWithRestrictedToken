@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Sandboxie 恢复原始版本脚本
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

set "INSTALL_PATH=C:\Program Files\Sandboxie-Plus"

echo 📋 此脚本将:
echo    1. 停止 Sandboxie 服务
echo    2. 恢复原始文件（从备份）
echo    3. 重新启动服务
echo.

REM 查找备份目录
echo [1/5] 查找备份目录...
set "BACKUP_PATH="
for /f "delims=" %%D in ('dir /b /ad "%INSTALL_PATH%.backup*" 2^>nul') do (
    set "BACKUP_PATH=%%D"
)

if "!BACKUP_PATH!"=="" (
    echo ❌ 错误: 未找到备份目录
    echo.
    echo 备份目录应该类似: %INSTALL_PATH%.backup_20250305
    echo.
    echo 如果没有备份，请重新安装官方 Sandboxie-Plus
    pause
    exit /b 1
)

echo ✅ 找到备份: !BACKUP_PATH!
echo.

REM 确认操作
choice /C YN /M "确认恢复原始版本"
if !ERRORLEVEL! NEQ 1 (
    echo 操作已取消
    pause
    exit /b 0
)
echo.

REM 停止服务
echo [2/5] 停止 Sandboxie 服务...
sc query SbieSvc | findstr "RUNNING" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    sc stop SbieSvc >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo ✅ 服务已停止
) else (
    echo ✅ 服务未运行
)

sc query SbieDrv >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    sc stop SbieDrv >nul 2>&1
    timeout /t 1 /nobreak >nul
)
echo.

REM 恢复文件
echo [3/5] 恢复原始文件...
xcopy "!BACKUP_PATH!\*" "%INSTALL_PATH%\" /E /Y /Q >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo ✅ 文件恢复成功
) else (
    echo ❌ 文件恢复失败
    pause
    exit /b 1
)
echo.

REM 重新安装驱动
echo [4/5] 重新安装驱动...
sc delete SbieDrv >nul 2>&1
sc create SbieDrv type= kernel start= demand binPath= "%INSTALL_PATH%\SbieDrv.sys" >nul 2>&1
echo ✅ 驱动已重新安装
echo.

REM 启动服务
echo [5/5] 启动服务...
sc start SbieSvc >nul 2>&1
timeout /t 2 /nobreak >nul

sc query SbieSvc | findstr "RUNNING" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo ✅ 服务启动成功
) else (
    echo ⚠️  服务启动失败，请手动启动: sc start SbieSvc
)
echo.

echo ========================================
echo ✅ 恢复完成！
echo ========================================
echo.
echo 原始版本已恢复，现在需要有效证书才能使用高级功能
echo.

REM 询问是否禁用测试模式
bcdedit /enum | findstr /i "testsigning.*Yes" >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo.
    choice /C YN /M "是否禁用测试模式（需要重启）"
    if !ERRORLEVEL! EQU 1 (
        bcdedit /set testsigning off
        echo ✅ 测试模式已禁用
        echo.
        choice /C YN /M "是否立即重启"
        if !ERRORLEVEL! EQU 1 (
            shutdown /r /t 10 /c "禁用测试模式，10秒后重启"
        )
    )
)

echo.
pause
