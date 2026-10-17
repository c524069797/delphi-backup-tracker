# 备份任务跟踪器

Windows 桌面备份任务管理工具，基于 Delphi 13 和 VCL，用于登记任务、更新处理状态和查看进度统计。

## 功能

- 任务登记：记录任务名称、资源类型和创建时间。
- 资源分类：支持文件、数据库和虚拟机三类资源。
- 状态管理：按待处理、进行中、已完成更新任务状态。
- 进度统计：显示任务总数及各状态的数量。
- 记录移除：支持移除待处理和已完成的任务，保留进行中的记录。

任务名称不能为空，长度上限为 80 个字符。状态按 `待处理 → 进行中 → 已完成` 转换，不能跳过中间状态。

应用负责备份工作的登记和进度跟踪，任务状态由使用者更新，备份作业由外部工具执行。当前版本使用内存存储，退出程序后记录清空。

## 运行环境

- Windows 64 位系统。
- Delphi 13，安装 Windows VCL 组件及 Win32、Win64 目标平台。

## 构建与运行

在 Delphi 中打开 `BackupTracker.dproj`，选择 **Win64 / Debug** 配置，构建工程后运行。生成文件位于：

```text
Win64\Debug\BackupTracker.exe
```

重新构建前需关闭正在运行的程序，避免输出文件被占用。

## 测试

在 Delphi 中打开 `BackupTrackerTests.dproj`，使用默认的 **Win32 / Debug** 配置构建，然后在工程目录执行：

```powershell
& .\Win32\Debug\BackupTrackerTests.exe
```

测试包括任务名称校验、资源类型、状态转换、删除保护，以及窗体中的行选择、统计更新和空状态。通过时输出检查数量并返回退出码 `0`；失败时输出 `FAILED:` 和错误信息，返回非零退出码。

## 项目结构

| 文件 | 作用 |
| --- | --- |
| `BackupTracker.dpr` / `.dproj` | 程序入口、平台和编译配置 |
| `MainForm.dfm` | 控件布局、属性和事件绑定 |
| `MainForm.pas` | 输入处理、表格刷新、按钮状态和反馈 |
| `BackupTasks.pas` | 任务记录、输入校验和状态流转规则 |
| `BackupTrackerTests.dpr` / `.dproj` | 业务规则和 VCL 窗体测试 |
| `remote.sh` / `remote.ps1` | SSH 文件同步、构建和运行脚本 |

`TBackupTaskStore` 管理任务数据和状态规则，窗体负责输入处理与界面更新。

## 远程开发

`remote.sh` 通过 SSH 调用 Windows 上的 `remote.ps1`。默认配置如下：

| 配置 | 默认值 |
| --- | --- |
| SSH 主机别名 | `win-delphi`，可通过 `DELPHI_SSH_HOST` 覆盖 |
| Windows 工程目录 | `E:\Projects\delphi-backup-tracker` |
| IDE 构建入口 | `C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bds.exe` |

```sh
./remote.sh status
./remote.sh open
./remote.sh build
./remote.sh test
./remote.sh run
```

使用前需配置 SSH 密钥登录，并按实际环境调整脚本路径。构建依赖 Windows 当前用户的交互桌面会话，运行窗口也显示在 Windows。脚本从各自工程配置中读取默认平台和配置，并核对构建日志与生成文件。

`./remote.sh sync` 会覆盖 Windows 端对应源文件。在 Windows IDE 中修改后，应先保存并取回文件，再执行同步。
