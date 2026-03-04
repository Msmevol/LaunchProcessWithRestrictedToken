@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Sandboxie 完整编译和签名脚本
echo ========================================
echo.

REM ===== 配置区域 =====
set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
set "WDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VERSION=10.0.19041.0"
set "CERT_NAME=Sandboxie Test Certificate"
set "CERT_FILE=SandboxieTestCert.pfx"
set "CERT_PASSWORD=Test123456"

REM ===== 检查环境 =====
echo [检查] 验证编译环境...

if not exist "%VS_PATH%" (
    echo ❌ 错误: 未找到 Visual Studio 2019
    echo    路径: %VS_PATH%
    pause
    exit /b 1
)

if not exist "%WDK_PATH%" (
    echo ❌ 错误: 未找到 Windows Driver Kit
    echo    路径: %WDK_PATH%
    pause
    exit /b 1
)

echo ✅ 环境检查通过
echo.

REM ===== 设置编译环境 =====
echo [1/6] 设置编译环境...
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo ❌ 错误: 无法设置 Visual Studio 环境
    pause
    exit /b 1
)
echo ✅ 编译环境已设置
echo.

REM ===== 编译 LowLevel =====
echo [2/6] 编译 LowLevel (Win32)...
msbuild Sandbox.sln /t:LowLevel /p:Configuration=Release /p:Platform=Win32 /m /v:minimal /nologo
if !ERRORLEVEL! NEQ 0 (
    echo ❌ 错误: LowLevel 编译失败
    pause
    exit /b 1
)
echo ✅ LowLevel 编译成功
echo.

REM ===== 编译主项目 =====
echo [3/6] 编译主项目 (x64)...
msbuild Sandbox.sln /t:Build /p:Configuration=Release /p:Platform=x64 /m /v:minimal /nologo
if !ERRORLEVEL! NEQ 0 (
    echo ❌ 错误: 主项目编译失败
    pause
    exit /b 1
)
echo ✅ 主项目编译成功
echo.

REM ===== 检查测试模式 =====
echo [4/6] 检查测试模式...
bcdedit /enum | findstr /i "testsigning.*Yes" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo ⚠️  警告: 测试模式未启用
    echo.
    echo 是否现在启用测试模式？（需要重启）
    choice /C YN /M "启用测试模式"
    if !ERRORLEVEL! EQU 1 (
        bcdedit /set testsigning on
        echo.
        echo ✅ 测试模式已启用，请重启后重新运行此脚本
        pause
        shutdown /r /t 30 /c "重启以启用测试模式，30秒后自动重启"
        exit /b 0
    )
) else (
    echo ✅ 测试模式已启用
)
echo.

REM ===== 创建/检查证书 =====
echo [5/6] 检查签名证书...

if not exist "%CERT_FILE%" (
    echo 📝 创建测试证书...
    
    powershell -Command "& { $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=%CERT_NAME%' -KeyUsage DigitalSignature -FriendlyName '%CERT_NAME%' -CertStoreLocation 'Cert:\CurrentUser\My' -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}'); $password = ConvertTo-SecureString -String '%CERT_PASSWORD%' -Force -AsPlainText; Export-PfxCertificate -Cert $cert -FilePath '%CERT_FILE%' -Password $password | Out-Null; Export-Certificate -Cert $cert -FilePath 'SandboxieTestCert.cer' | Out-Null; Write-Host '✅ 证书创建成功' }"
    
    echo 📝 安装证书到受信任的根...
    powershell -Command "Import-Certificate -FilePath 'SandboxieTestCert.cer' -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null; Import-Certificate -FilePath 'SandboxieTestCert.cer' -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher' | Out-Null; Write-Host '✅ 证书已安装'"
) else (
    echo ✅ 找到现有证书
)
echo.

REM ===== 签名文件 =====
echo [6/6] 签名所有文件...
set "SIGNTOOL=%WDK_PATH%\bin\%SDK_VERSION%\x64\signtool.exe"

if not exist "%SIGNTOOL%" (
    echo ❌ 错误: 未找到 signtool.exe
    echo    路径: %SIGNTOOL%
    pause
    exit /b 1
)

set FILES=(
    "core\drv\x64\Release\SbieDrv.sys"
    "core\svc\x64\Release\SbieSvc.exe"
    "core\dll\x64\Release\SbieDll.dll"
    "apps\control\x64\Release\SbieCtrl.exe"
    "apps\start\x64\Release\Start.exe"
    "apps\ini\x64\Release\SbieIni.exe"
    "install\kmdutil\x64\Release\KmdUtil.exe"
    "SboxHostDll\x64\Release\SboxHostDll.dll"
    "msgs\x64\Release\SboxMsg.dll"
)

for %%F in %FILES% do (
    if exist "%%~F" (
        echo   签名: %%~F
        "%SIGNTOOL%" sign /f "%CERT_FILE%" /p "%CERT_PASSWORD%" /t http://timestamp.digicert.com /fd sha256 /v "%%~F" >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo     ✅ 成功
        ) else (
            echo     ⚠️  失败 ^(可能不影响使用^)
        )
    ) else (
        echo   ⚠️  文件不存在: %%~F
    )
)
echo.

REM ===== 创建发布包 =====
echo [打包] 创建发布包...
set "OUTPUT_DIR=Release_Package_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "OUTPUT_DIR=%OUTPUT_DIR: =0%"

if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

for %%F in %FILES% do (
    if exist "%%~F" (
        xcopy "%%~F" "%OUTPUT_DIR%\" /Y /Q >nul
    )
)

REM 创建安装说明
(
echo Sandboxie 修改版安装说明
echo ========================================
echo.
echo 编译时间: %date% %time%
echo 修改内容: 解除所有功能限制
echo.
echo 安装步骤:
echo 1. 确保测试模式已启用: bcdedit /set testsigning on
echo 2. 停止 Sandboxie 服务: sc stop SbieSvc
echo 3. 备份原始文件
echo 4. 复制本目录所有文件到 Sandboxie 安装目录
echo 5. 启动服务: sc start SbieSvc
echo.
echo 验证解锁:
echo - 打开 Sandboxie Control
echo - 右键沙盒 -^> 沙盒设置
echo - 检查高级功能是否可用（无需证书提示）
echo.
echo 功能列表:
echo ✅ 加密沙盒 ^(ConfidentialBox^)
echo ✅ 网络过滤 ^(NetworkDnsFilter^)
echo ✅ 独立桌面 ^(UseSandboxDesktop^)
echo ✅ 高级安全模式 ^(UseSecurityMode^)
echo ✅ 系统调用锁定 ^(SysCallLockDown^)
echo ✅ 隐私模式 ^(UsePrivacyMode^)
echo.
echo 注意事项:
echo - 仅供个人学习和测试使用
echo - 遵守 GPL v3 开源协议
echo - 建议支持官方项目
echo.
) > "%OUTPUT_DIR%\安装说明.txt"

echo ✅ 发布包已创建: %OUTPUT_DIR%
echo.

REM ===== 完成 =====
echo ========================================
echo ✅ 编译和签名完成！
echo ========================================
echo.
echo 📦 输出目录: %OUTPUT_DIR%
echo.
echo 📝 下一步操作:
echo.
echo 1. 查看输出目录中的文件
echo 2. 阅读"安装说明.txt"
echo 3. 备份现有 Sandboxie 安装
echo 4. 按照说明安装修改版
echo.
echo 💡 提示:
echo - 桌面右下角应显示"测试模式"水印
echo - 首次安装可能需要重启
echo - 如遇问题，恢复备份文件即可
echo.

REM 询问是否打开输出目录
choice /C YN /M "是否打开输出目录"
if !ERRORLEVEL! EQU 1 (
    explorer "%OUTPUT_DIR%"
)

echo.
pause
