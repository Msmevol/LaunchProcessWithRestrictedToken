# 🎯 Sandboxie 完全解锁指南

## 📚 文档索引

本项目包含以下文档和脚本：

| 文件 | 说明 |
|------|------|
| **README.md** | 本文件 - 快速开始指南 |
| **修改指南.md** | 详细的代码修改说明 |
| **编译和签名指南.md** | 完整的编译、签名、安装流程 |
| **build_and_sign.bat** | 🔥 一键编译和签名脚本 |
| **install.bat** | 🔥 一键安装脚本 |
| **restore.bat** | 恢复原始版本脚本 |

---

## ⚡ 快速开始（3步完成）

### 前提条件
- ✅ Windows 10/11 (64位)
- ✅ 已安装官方 Sandboxie-Plus
- ✅ 管理员权限

### 步骤1️⃣：准备环境（首次需要）

```powershell
# 1. 安装 Visual Studio 2019
# 下载: https://visualstudio.microsoft.com/vs/older-downloads/
# 选择: Desktop development with C++

# 2. 安装 Windows Driver Kit (WDK) 10.0.19041
# 下载: https://go.microsoft.com/fwlink/?linkid=2128854

# 3. 克隆官方仓库
git clone https://github.com/sandboxie-plus/Sandboxie.git
cd Sandboxie
```

### 步骤2️⃣：修改代码

只需修改 **1个文件**：`core/drv/verify.c`

在 `KphValidateCertificate()` 函数中（约第530行），找到：
```c
Verify_CertInfo.State = 0; // clear
```

在这行**之后**添加：
```c
// 🔓 解除所有限制
Verify_CertInfo.type = eCertEternal;
Verify_CertInfo.level = eCertMaxLevel;
Verify_CertInfo.opt_sec = 1;
Verify_CertInfo.opt_enc = 1;
Verify_CertInfo.opt_net = 1;
Verify_CertInfo.opt_desk = 1;
Verify_CertInfo.expired = 0;
Verify_CertInfo.outdated = 0;
Verify_CertInfo.active = 1;
Verify_CertInfo.lock_req = 0;
return STATUS_SUCCESS;
```

> 💡 详细修改说明请查看 **修改指南.md**

### 步骤3️⃣：编译、签名、安装

```batch
# 方法A：使用自动化脚本（推荐）
.\build_and_sign.bat    # 编译和签名
.\install.bat           # 安装

# 方法B：手动操作
# 1. 打开 Visual Studio 2019
# 2. 打开 Sandbox.sln
# 3. 选择 Release + x64
# 4. 生成解决方案
# 5. 按照"编译和签名指南.md"进行签名和安装
```

---

## 🎉 验证解锁成功

安装完成后：

1. **启动 Sandboxie Control**
2. **右键任意沙盒 → 沙盒设置**
3. **检查以下功能是否可用**（不显示需要证书的提示）：

| 功能 | 位置 | 配置项 |
|------|------|--------|
| ✅ 高级安全模式 | 安全 | UseSecurityMode |
| ✅ 系统调用锁定 | 安全 | SysCallLockDown |
| ✅ 加密沙盒 | 资源访问 | ConfidentialBox |
| ✅ 网络DNS过滤 | 网络 | NetworkDnsFilter |
| ✅ 独立沙盒桌面 | 外观 | UseSandboxDesktop |
| ✅ 隐私模式 | 安全 | UsePrivacyMode |

如果这些选项都可以正常设置，**恭喜！解锁成功！** 🎊

---

## 📁 项目结构

```
Sandboxie/
├── core/
│   ├── drv/
│   │   └── verify.c          ⭐ 需要修改的文件
│   ├── svc/                  (服务)
│   └── dll/                  (注入DLL)
├── apps/
│   ├── control/              (控制台)
│   └── start/                (启动器)
├── install/                  (安装程序)
├── msgs/                     (消息文件)
└── Sandbox.sln               (解决方案文件)
```

---

## 🔧 详细操作指南

### 方案A：使用自动化脚本（推荐）

#### 1. 编译和签名
```batch
# 双击运行或在 PowerShell 中执行
.\build_and_sign.bat
```

脚本会自动：
- ✅ 检查编译环境
- ✅ 编译 LowLevel (Win32)
- ✅ 编译主项目 (x64)
- ✅ 检查/启用测试模式
- ✅ 创建测试证书
- ✅ 签名所有文件
- ✅ 创建发布包

#### 2. 安装
```batch
# 以管理员身份运行
.\install.bat
```

脚本会自动：
- ✅ 检查测试模式
- ✅ 停止 Sandboxie 服务
- ✅ 备份原始文件
- ✅ 复制新文件
- ✅ 启动服务

#### 3. 恢复原始版本（如需要）
```batch
# 以管理员身份运行
.\restore.bat
```

### 方案B：手动操作

详细步骤请查看 **编译和签名指南.md**

---

## 🔐 驱动签名说明

Windows 要求所有内核驱动必须签名。有三种方法：

### 方法1：测试模式（推荐）

```powershell
# 启用测试模式
bcdedit /set testsigning on
shutdown /r /t 0

# 重启后桌面右下角会显示"测试模式"水印
```

**优点：**
- ✅ 简单快速
- ✅ 适合个人使用
- ✅ 免费

**缺点：**
- ⚠️ 桌面有水印
- ⚠️ 降低系统安全性

### 方法2：自签名证书

脚本 `build_and_sign.bat` 会自动创建和使用自签名证书。

### 方法3：商业证书

如果你有 EV 代码签名证书，可以直接签名，无需测试模式。

---

## 🎯 解锁的功能

修改后，以下所有功能将无需证书即可使用：

### 🔒 安全功能
- ✅ **UseSecurityMode** - 高级安全模式
- ✅ **SysCallLockDown** - 系统调用锁定
- ✅ **RestrictDevices** - 限制设备访问
- ✅ **UseRuleSpecificity** - 规则特异性
- ✅ **UsePrivacyMode** - 隐私模式
- ✅ **ProtectHostImages** - 保护主机映像
- ✅ **NoSecurityIsolation** - 降低隔离模式

### 🔐 加密功能
- ✅ **ConfidentialBox** - 加密沙盒
- ✅ **UseFileImage** - 文件映像
- ✅ **EnableEFS** - 启用 EFS 加密

### 🌐 网络功能
- ✅ **NetworkDnsFilter** - DNS 过滤
- ✅ **NetworkUseProxy** - 代理设置

### 🖥️ 桌面功能
- ✅ **UseSandboxDesktop** - 独立沙盒桌面

### 💾 其他功能
- ✅ **UseRamDisk** - RAM 磁盘
- ✅ **ForceUsbDrives** - 强制 USB 驱动器隔离
- ✅ 自动更新

---

## ⚠️ 注意事项

### 法律和道德
- ✅ **完全合法** - Sandboxie 使用 GPL v3 开源许可证
- ✅ **允许修改** - GPL 明确允许修改和分发
- ✅ **个人使用** - 自己编译使用完全没问题
- 💡 **建议支持** - 如果觉得有用，请考虑支持官方项目

### 安全风险
- ⚠️ **测试模式** - 降低系统安全性
- ⚠️ **自签名** - 仅用于个人测试
- ⚠️ **第三方编译版** - 不要下载他人编译的版本（可能含恶意代码）
- ✅ **自己编译** - 最安全的方式

### 技术限制
- ⚠️ **无官方更新** - 需要手动跟进新版本
- ⚠️ **无技术支持** - 官方不提供支持
- ⚠️ **兼容性** - 新版 Windows 可能需要重新编译

---

## 🐛 常见问题

### Q1: 编译失败 - 找不到 WDK
**A:** 
```
1. 确认 WDK 已安装
2. 安装 WDK 扩展：
   C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix
3. 重启 Visual Studio
```

### Q2: 驱动加载失败 - 代码 52
**A:**
```powershell
# 检查测试模式
bcdedit /enum | findstr testsigning

# 如果显示 No，启用测试模式
bcdedit /set testsigning on
shutdown /r /t 0
```

### Q3: 服务无法启动
**A:**
```powershell
# 查看详细错误
sc query SbieSvc

# 查看事件日志
eventvwr.msc
# 导航到: Windows 日志 -> 系统
# 查找 SbieSvc 或 SbieDrv 相关错误
```

### Q4: 功能仍然显示需要证书
**A:**
```
1. 确认修改的代码已编译
2. 确认新文件已复制到安装目录
3. 重启 Sandboxie 服务
4. 如果还不行，重启电脑
```

### Q5: 蓝屏 (BSOD)
**A:**
```
1. 进入安全模式
2. 运行 restore.bat 恢复原始版本
3. 或手动删除驱动: sc delete SbieDrv
4. 检查编译配置（必须是 Release + x64）
```

### Q6: 如何移除测试模式水印
**A:**
```
测试模式水印无法移除，这是 Windows 的安全机制。
如果不想看到水印，需要使用商业 EV 代码签名证书。
```

---

## 📊 对比：官方版 vs 修改版

| 特性 | 官方免费版 | 官方付费版 | 修改版 |
|------|-----------|-----------|--------|
| 基础沙盒 | ✅ | ✅ | ✅ |
| 高级安全 | ❌ | ✅ | ✅ |
| 加密沙盒 | ❌ | ✅ | ✅ |
| 网络过滤 | ❌ | ✅ | ✅ |
| 独立桌面 | ❌ | ✅ | ✅ |
| 官方更新 | ✅ | ✅ | ❌ |
| 技术支持 | ❌ | ✅ | ❌ |
| 合法性 | ✅ | ✅ | ✅ |
| 安全性 | ✅ | ✅ | ⚠️ |

---

## 🔄 更新到新版本

当官方发布新版本时：

```bash
# 1. 拉取最新代码
cd Sandboxie
git pull

# 2. 重新应用修改（修改 core/drv/verify.c）

# 3. 重新编译
.\build_and_sign.bat

# 4. 重新安装
.\install.bat
```

---

## 📞 支持官方项目

如果你觉得 Sandboxie 有用，请考虑支持官方项目：

- 🌟 **GitHub Star**: https://github.com/sandboxie-plus/Sandboxie
- 💰 **购买证书**: https://sandboxie-plus.com/
- 🐛 **报告 Bug**: https://github.com/sandboxie-plus/Sandboxie/issues
- 💬 **社区讨论**: https://github.com/sandboxie-plus/Sandboxie/discussions

---

## 📜 许可证

Sandboxie-Plus 使用 **GNU General Public License v3.0**

这意味着：
- ✅ 可以自由使用
- ✅ 可以修改源代码
- ✅ 可以分发修改版
- ✅ 可以商业使用
- ⚠️ 必须保留原始版权声明
- ⚠️ 必须使用相同的 GPL v3 许可证
- ⚠️ 必须提供源代码（如果分发二进制）

---

## 🎓 学习资源

- [Sandboxie 官方文档](https://sandboxie-plus.com/sandboxie/)
- [Windows Driver Kit 文档](https://docs.microsoft.com/en-us/windows-hardware/drivers/)
- [代码签名指南](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing)
- [GPL v3 许可证](https://www.gnu.org/licenses/gpl-3.0.html)

---

## 🙏 致谢

- **David Xanatos** - Sandboxie-Plus 维护者
- **Sandboxie Holdings, LLC** - 原始 Sandboxie 开发者
- **开源社区** - 所有贡献者

---

## 📝 更新日志

### 2025-03-05
- ✅ 创建完整的编译和签名指南
- ✅ 添加自动化脚本
- ✅ 添加安装和恢复脚本
- ✅ 完善文档

---

## 💡 提示

1. **首次使用建议**：先在虚拟机中测试
2. **备份重要数据**：修改系统驱动有风险
3. **保留原始文件**：install.bat 会自动备份
4. **遇到问题**：查看"常见问题"章节
5. **安全第一**：不要在生产环境使用测试模式

---

## 🚀 开始使用

```batch
# 1. 修改代码（只需修改 1 个文件）
# 2. 运行编译脚本
.\build_and_sign.bat

# 3. 运行安装脚本（以管理员身份）
.\install.bat

# 4. 享受完整功能！
```

---

**祝你使用愉快！** 🎉

如有问题，请查看 **编译和签名指南.md** 获取详细说明。
