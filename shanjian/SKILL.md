---
name: shanjian-cli
description: Install and safely operate the Shanjian CLI in Claude Code. Use when the user invokes /shanjian-cli, wants Claude Code to install shanjian, check authorization first, show QR-code auth login when needed, run Shanjian workflow commands, list templates/tasks/creations, or download outputs.
---

# Shanjian CLI

在 Claude Code 中安装和使用闪剪 CLI 时使用本技能。

## 默认行为

用户只输入 `/shanjian-cli` 或只点选本技能时，不要只解释本技能。直接执行以下流程：

1. 定位本技能目录，也就是当前 `SKILL.md` 所在目录。
2. 检查 `shanjian` 是否已在 PATH 中：运行 `shanjian --help` 或等价命令。
3. 如果已安装，运行 `shanjian auth status`，然后报告安装可用和登录状态。
4. 如果未安装，在 macOS/Linux 执行 `<skill_dir>/scripts/install-shanjian.sh --version latest --install-dir "$HOME/.local/bin"`；在 Windows PowerShell 执行 `<skill_dir>\scripts\install-shanjian.ps1 -Version latest -InstallDir "$HOME\.local\bin"`。
5. 安装后重新运行 `shanjian --help` 和 `shanjian auth status`。
6. 如果 `auth status` 显示未登录、授权失败、session 缺失或返回非零状态，马上按“登录二维码展示流程”执行 `shanjian auth login` 并展示二维码。不要停下来等待额外确认口令。

如果执行脚本需要网络、写入用户目录或提升权限，使用工具请求许可；不要把安装命令作为最终答案停在说明层。

## 包内容

- `SKILL.md`：Claude Code 使用说明。
- `agents/openai.yaml`：技能 UI 元数据。
- `scripts/install-shanjian.sh`：macOS/Linux 安装脚本。
- `scripts/install-shanjian.ps1`：Windows PowerShell 安装脚本。

## 安装 CLI

优先使用本技能自带脚本安装 GitHub Release 二进制。默认下载来源是 `sjzn-com/skills`；如需改下载来源，传 `--repo owner/name` 或设置 `SHANJIAN_CLI_REPO`。

macOS/Linux：

```bash
<skill_dir>/scripts/install-shanjian.sh --version latest --install-dir "$HOME/.local/bin"
```

Windows PowerShell：

```powershell
<skill_dir>\scripts\install-shanjian.ps1 -Version latest -InstallDir "$HOME\.local\bin"
```

安装脚本按当前系统下载匹配的 release asset，并在存在 `SHA256SUMS` 时校验哈希：

```text
shanjian_darwin_arm64.tar.gz
shanjian_darwin_amd64.tar.gz
shanjian_linux_amd64.tar.gz
shanjian_linux_arm64.tar.gz
shanjian_windows_amd64.zip
SHA256SUMS
```

安装完成后先检查授权状态：

```bash
shanjian --help
shanjian auth status
```

## 登录二维码展示流程

所有需要授权的命令前都要先运行 `shanjian auth status`。如果未登录，不要反复重试业务命令，也不要只提示“需要授权”；要明确告诉用户当前未登录，然后立即启动扫码登录流程。

当用户已经要求执行查询、下载、创作等需要授权的工作时，未登录就是当前任务的阻塞条件；此时直接执行 `shanjian auth login`，展示微信扫码二维码，并保持命令运行等待扫码结果。不要等待额外口令，不要把最终答案停在等待确认，也不要用本地文案替代原本的闪剪任务。

1. 先确认当前 CLI 支持默认控制台二维码输出：运行 `shanjian auth login --help`，检查 `--qr-output` 说明是否写明“控制台默认输出二维码”。如果没有，重新安装最新 release 后再继续；不要回退到旧的 `shanjian login` 或只贴链接。
2. 默认把登录态和二维码放在当前项目下，避免写入不可控位置：`work/shanjian-state`、`work/shanjian-login-qr.png`。如果用户指定了状态目录或图片路径，使用用户指定值。
3. 用可持续运行的终端会话启动登录命令，并让命令尽快返回首屏输出；不要等命令结束后才给出进展。如果工具要求执行许可，按工具流程请求许可；不要改成普通文本确认。

```bash
mkdir -p work/shanjian-state
shanjian auth login --state-dir work/shanjian-state --qr-output work/shanjian-login-qr.png --timeout 300 --interval 2 --yes
```

4. 命令会先在控制台打印二维码，并在使用 `--qr-output` 时打印 `二维码图片：<absolute-path>`，然后继续等待扫码。拿到路径或确认文件已生成后，立刻向用户发送 Markdown 图片，路径必须是绝对路径：

```markdown
![微信扫码登录](/absolute/path/to/work/shanjian-login-qr.png)
```

5. 保持登录命令会话运行并轮询它，直到登录成功、超时或用户取消。登录成功后，后续 `shanjian` 命令都要继续带同一个 `--state-dir work/shanjian-state`，除非用户要求改用默认登录态。
6. 登录成功后必须再次运行 `shanjian auth status --state-dir work/shanjian-state` 确认授权有效，再继续用户原本要执行的查询、下载或创作命令。

## 状态目录传递规则

如果本轮登录或授权确认使用了自定义状态目录，例如 `work/shanjian-state`，就把它视为当前会话的 active state dir。之后每一条 `shanjian` 业务命令都必须包含完全相同的 `--state-dir <active-state-dir>`，包括 `--dry-run`、真实提交、查询、下载和轮询命令。

执行命令前先检查即将运行的 shell 命令文本；如果命令里没有 `--state-dir <active-state-dir>`，停止并重写命令。为避免长主题文本导致界面截断看不见参数，把 `--state-dir` 放在自由文本主题之前：

```bash
shanjian creation moments create --state-dir work/shanjian-state "朋友圈主题" --dry-run
shanjian creation moments create --state-dir work/shanjian-state "朋友圈主题"
```

## 授权预检

执行下面任何命令前，都必须先确认授权状态：

- `shanjian agent list`
- `shanjian templates ...`
- `shanjian creation ...`
- `shanjian tasks ...`
- `shanjian creations ...`

预检规则：

1. 先运行 `shanjian auth status`，或在使用自定义登录态时运行 `shanjian auth status --state-dir <dir>`。
2. 如果未登录，暂停原业务命令，说明需要微信扫码登录，然后立刻按“登录二维码展示流程”启动登录命令并展示二维码。
3. 如果登录成功后使用了自定义 `--state-dir`，后续所有命令都必须带同一个 `--state-dir`。
4. 只有 `auth status` 确认已登录后，才执行用户原本请求的业务命令。

## 安全边界

- 授权判断只通过 `auth status`，不要直接读取 `~/.shanjian/session.json` 或自定义 `--state-dir` 下的会话文件。
- `auth login` 默认在控制台输出二维码；`auth login --qr-output <path>` 会额外写出登录二维码 PNG；`auth login` 会写入本地登录态；`auth logout` 会删除登录态。
- 所有 `create` 命令都会提交真实任务，除非带 `--dry-run`，否则可能消耗积分。
- 检查请求体时优先使用 `--dry-run`；对比接口结构时优先使用 `--json`。
- 下载命令会写文件；除非用户要求，不要处理下载产物。

## 常用命令

只读或低风险检查：

```bash
shanjian agent list --state-dir work/shanjian-state
shanjian templates list --state-dir work/shanjian-state --workflow-type shortVideo --json
shanjian creation short-video templates --state-dir work/shanjian-state
shanjian creation ai-short-film models --state-dir work/shanjian-state
shanjian creation ai-short-film prompts --state-dir work/shanjian-state
shanjian tasks list --state-dir work/shanjian-state
shanjian creations list --state-dir work/shanjian-state
```

真实创建前先 dry-run：

```bash
shanjian creation moments create --state-dir work/shanjian-state "朋友圈主题" --dry-run
shanjian creation article create --state-dir work/shanjian-state "文章主题" --dry-run
shanjian creation image-text create --state-dir work/shanjian-state "图文主题" --dry-run
shanjian creation short-video create --state-dir work/shanjian-state "短视频主题" --duration 30 --dry-run
shanjian creation ai-short-film create --state-dir work/shanjian-state "AI短剧主题" --image-url "https://example.com/ref.jpg" --dry-run
```

确认用户明确要提交后，只移除 `--dry-run`，继续保留同一个 `--state-dir`。

## 工作流注意

- 支持的工作流类型：`shortVideo`、`imageText`、`article`、`moments`、`aiShortFlim`。
- 服务端工作流拼写 `aiShortFlim` 是故意保留，不要改成 `aiShortFilm`。
- `--template-id` 指 `/ai_agent_user/template` 返回的记录 `id`，不是嵌套的 `templateId` 或 `styleId`。
- `ai-short-film create` 当前使用已有图片 URL；`--image-url` 可重复。
