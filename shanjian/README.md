# Shanjian CLI Skill

这是给 Claude Code 使用的闪剪 CLI 技能包，用于安装、验证和安全使用 `shanjian` 命令。

## 包内容

```text
SKILL.md
agents/openai.yaml
scripts/install-shanjian.sh
scripts/install-shanjian.ps1
README.md
```

## 安装这个技能

直接使用 `skills` 命令安装：

```bash
npx skills add https://github.com/sjzn-com/skills --skill shanjian-cli
```

安装后重启或刷新 Claude Code，让技能重新加载。

本地开发调试时，可以临时复制当前目录：

```bash
mkdir -p ~/.claude/skills
cp -R v2/skills/shanjian ~/.claude/skills/shanjian-cli
```

## 使用方式

在 Claude Code 中输入：

```text
/shanjian-cli
```

技能的默认行为是：

1. 检查 `shanjian` 是否已经在 `PATH` 中。
2. 如果未安装，执行本技能内的安装脚本下载 GitHub Release 二进制。
3. 安装完成后运行 `shanjian --help`。
4. 运行 `shanjian auth status` 检查登录状态。
5. 如果未登录，Claude Code 应立即启动扫码登录流程并展示微信二维码。

如果安装脚本需要联网或写入 `~/.local/bin`，Claude Code 应该先请求你的许可。

## 手动安装 CLI

通常不需要手动执行脚本；直接触发 `/shanjian-cli` 即可。需要手动安装时可以运行：

macOS / Linux：

```bash
~/.claude/skills/shanjian-cli/scripts/install-shanjian.sh --version latest --install-dir "$HOME/.local/bin"
```

Windows PowerShell：

```powershell
~\.claude\skills\shanjian-cli\scripts\install-shanjian.ps1 -Version latest -InstallDir "$HOME\.local\bin"
```

默认下载来源是 `sjzn-com/skills`。如需改下载来源：

```bash
~/.claude/skills/shanjian-cli/scripts/install-shanjian.sh --repo owner/name --version latest
```

或设置环境变量：

```bash
export SHANJIAN_CLI_REPO=owner/name
```

## 常用命令

检查安装：

```bash
shanjian --help
shanjian auth status
```

执行任何查询、创作或下载命令前，Claude Code 都应该先运行：

```bash
shanjian auth status
```

如果显示未登录，Claude Code 应暂停原命令，立即启动扫码登录流程并展示微信二维码，而不是停下来等待额外确认，也不是反复执行业务命令并提示授权失败。

```bash
shanjian auth login
```

`auth login` 默认会在控制台输出二维码。如果由 Claude Code 帮你登录，也应让它额外输出二维码图片并直接展示给你扫码，而不是只贴二维码链接：

```bash
mkdir -p work/shanjian-state
shanjian auth login --state-dir work/shanjian-state --qr-output work/shanjian-login-qr.png --timeout 300 --interval 2 --yes
```

CLI 会先在控制台打印二维码，并输出 `二维码图片：<absolute-path>`。Claude Code 应该立刻用 Markdown 图片把这张 PNG 发出来给你扫码，然后继续保持登录命令运行并等待确认。

扫码成功后，Claude Code 应再次运行：

```bash
shanjian auth status --state-dir work/shanjian-state
```

确认已登录后，再继续执行原本的查询、下载或创作命令。后续命令如果使用了 `work/shanjian-state`，必须继续带同一个 `--state-dir`，并建议放在长文本主题前面，避免界面截断时看不到参数。

只读查询：

```bash
shanjian agent list --state-dir work/shanjian-state
shanjian templates list --state-dir work/shanjian-state --workflow-type shortVideo --json
shanjian creation short-video templates --state-dir work/shanjian-state
shanjian creation ai-short-film models --state-dir work/shanjian-state
shanjian creation ai-short-film prompts --state-dir work/shanjian-state
shanjian tasks list --state-dir work/shanjian-state
shanjian creations list --state-dir work/shanjian-state
```

创建任务前先使用 `--dry-run`：

```bash
shanjian creation short-video create --state-dir work/shanjian-state "短视频主题" --duration 30 --dry-run
```

确认要真实提交后，只移除 `--dry-run`，继续保留同一个 `--state-dir`。

## 安全注意

- 登录态通常保存在 `~/.shanjian/session.json`。
- 如果登录时使用了 `--state-dir work/shanjian-state`，后续命令也必须继续使用同一个 `--state-dir`。
- 仅通过 `auth status` 判断授权状态，不要打开、提交或分享本地登录态文件。
- `auth login` 默认在控制台输出二维码；`auth login --qr-output <path>` 会额外写出登录二维码 PNG；登录成功后会写入本机登录态；`auth logout` 会删除登录态。
- 创建类命令会提交真实任务，可能消耗积分。
- 下载命令会写入文件。
