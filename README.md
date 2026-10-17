# 备份任务跟踪器

用 Delphi 13 Community Edition 和 VCL 编写的 Windows 桌面项目，用来练习窗体设计、按钮事件、表格刷新和业务状态流转。

围绕备份任务登记场景，可以选择资源类型、记录任务、手动更新工作进度，并查看各状态的数量。程序不执行实际备份；记录仅保存在当前进程，关闭窗口后清空。

## 打开与运行

1. 在 Windows 安装 Delphi 13，并确认已安装 Windows VCL 开发组件。
2. 用 Delphi 打开 `BackupTracker.dproj`。
3. 选择 Windows 64 位、Debug 配置，按 **F9** 编译并运行。
4. 默认生成位置为 `Win64/Debug/BackupTracker.exe`。

若弹出 Compile 窗口并出现错误，程序尚未成功运行。打开 IDE 的 Messages／消息面板，双击第一条编译错误可定位代码行。

## 第一次操作

1. 输入“业务数据库每日备份”，资源类型选择“数据库”。
2. 点击“新增任务”，表格出现一项“待处理”记录。
3. 选中记录，点击“标记进行中”。
4. 点击“标记完成”，查看表格和统计数字变化。
5. 点击“移除记录”，查看空状态。

状态规则：`待处理 → 进行中 → 已完成`。进行中的记录禁止删除，任务不能跳过“进行中”直接完成。

## 亲手改一个按钮

1. 关闭运行窗口，在 Delphi 打开 `MainForm.pas`，按 **F12** 切换到窗体设计器。
2. 选中“新增任务”按钮，在对象查看器中把 `Caption` 改成“添加备份任务”；保留 `Name = AddButton`。
3. 全部保存，按 **F9**，确认按钮文字变化。
4. 回到设计器，双击按钮，进入 `AddButtonClick`，从这里阅读新增任务的数据流。

`TaskNameEdit.Text`、`ResourceCombo.ItemIndex` → `AddButtonClick` → `TBackupTaskStore.Add` → `RefreshGrid` → 表格、统计和按钮状态。

`Name` 是代码使用的控件标识，`Caption` 是显示文字，`OnClick` 是点击事件；这些属性名称会保留英文。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `BackupTracker.dpr` / `.dproj` | 程序入口、平台和编译配置 |
| `MainForm.dfm` | 控件布局、属性和事件绑定 |
| `MainForm.pas` | 输入处理、表格刷新、按钮状态和反馈 |
| `BackupTasks.pas` | 任务记录、输入校验和状态流转规则 |
| `BackupTrackerTests.dpr` / `.dproj` | 业务规则与实际 VCL 窗体检查 |
| `remote.sh` / `remote.ps1` | Mac 通过 SSH 同步、打开、构建和运行 Windows 工程 |

业务规则集中在 `TBackupTaskStore`，窗体负责收集输入和显示结果。资源类型包括文件、数据库和虚拟机，任务名称最多 80 个字符。

## 功能检查

在 Delphi 中打开 `BackupTrackerTests.dproj`，使用工程默认的 Win32 / Debug 配置编译。生成后从 Windows PowerShell 运行：

```powershell
& .\Win32\Debug\BackupTrackerTests.exe
```

成功时输出 `N checks passed`，失败时输出 `FAILED:` 并返回非零退出码。检查涵盖中文输入、空输入、名称长度、非法状态转换、删除保护、行选择、统计和空状态。

检查完成后，重新打开 `BackupTracker.dproj` 继续练习。

### 已验证范围（2026-10-17）

- Win64 / Debug 主程序编译成功，并已在 Windows 交互桌面启动。
- Win32 / Debug 检查程序输出 **`77 checks passed`**，退出码为 0。
- Mac 和 Windows 对应的源码、工程配置与远程脚本哈希一致。
- 未统计代码覆盖率，尚未进行屏幕画面的视觉核验。

## 从 Mac 远程操作

这些脚本使用已有的 SSH 别名 `win-delphi`，Windows 工程目录为 `E:\Projects\delphi-backup-tracker`，Delphi 安装目录为 `C:\Program Files (x86)\Embarcadero\Studio\37.0`。在其他机器上使用时，先调整脚本中的路径，并自行配置 SSH 密钥登录。

```sh
./remote.sh status
./remote.sh open
./remote.sh build
./remote.sh test
./remote.sh run
```

`build` 和 `test` 使用已验证的 `bin\bds.exe` 自动构建入口，要求 Windows 当前账号已登录桌面。主程序输出 Win64，检查程序输出 Win32，脚本分别读取各自工程的默认平台和配置。`run` 的窗口显示在 Windows；SSH 仅传输文件和执行操作。自动构建若超时，会保留 IDE 以便查看提示；超时不代表编译成功。

`./remote.sh sync` 会把 Mac 源码写入 Windows。若在 Windows 设计器中做过修改，先全部保存并取回改动，再同步，避免覆盖练习内容。重建前先关闭运行程序。

## 版本管理范围

仓库保存 Pascal 源码、文本窗体、工程配置、检查程序、脚本和本说明。编译产物、IDE 自动恢复文件、日志和本机配置由 `.gitignore` 排除。安装器、许可证和账号凭证不属于工程文件。
