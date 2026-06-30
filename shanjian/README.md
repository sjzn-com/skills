# Shanjian CLI Skill

这是给 Claude Code 使用的闪剪 CLI 技能包。它不包含 CLI 源码，只包含让 Claude Code 安装、验证和安全使用 `shanjian` 命令所需的技能说明与安装脚本。

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
npx skills add https://github.com/imocat/shanjian
```

安装后重启或刷新 Claude Code，让技能重新加载。

本地开发调试时，如果你还没有发布到 GitHub，可以临时复制当前目录：

```bash
mkdir -p ~/.claude/skills
cp -R v2/skills/shanjian-cli ~/.claude/skills/shanjian-cli
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

默认下载仓库是 `shanjian-tv/shanjian-cli`。如果你的 CLI 二进制发布在其他仓库：

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

登录需要你明确授权后再执行：

```bash
shanjian auth login
```

如果由 Claude Code 帮你登录，应让它输出二维码图片并直接展示给你扫码，而不是只贴二维码链接：

```bash
mkdir -p work/shanjian-state
shanjian auth login --state-dir work/shanjian-state --qr-output work/shanjian-login-qr.png --timeout 300 --interval 2 --yes
```

CLI 会先打印 `二维码图片：<absolute-path>`，Claude Code 应该立刻用 Markdown 图片把这张 PNG 发出来给你扫码，然后继续保持登录命令运行并等待确认。

只读查询：

```bash
shanjian agent list
shanjian templates list --workflow-type shortVideo --json
shanjian creation short-video templates
shanjian creation ai-short-film models
shanjian creation ai-short-film prompts
shanjian tasks list
shanjian creations list
```

创建任务前先使用 `--dry-run`：

```bash
shanjian creation short-video create "短视频主题" --duration 30 --dry-run
```

确认要真实提交后，再移除 `--dry-run`。

## 安全注意

- 登录态通常保存在 `~/.shanjian/session.json`。
- 不要提交、打印或分享 `bhb-session-token`。
- `auth login --qr-output <path>` 会写出登录二维码 PNG；登录成功后会写入本机登录态；`auth logout` 会删除登录态。
- 创建类命令会提交真实任务，可能消耗积分。
- 下载命令会写入文件，不要把下载产物提交到 skill 仓库。

## 发布到 GitHub

这个仓库只需要发布 skill 文件，不要放 CLI 源码、构建目录、下载产物或登录态文件。

推荐发布结构：

```text
README.md
SKILL.md
agents/openai.yaml
scripts/install-shanjian.sh
scripts/install-shanjian.ps1
```

CLI 二进制应通过 GitHub Release assets 发布。安装脚本会按平台下载匹配文件，并在 release 中存在 `SHA256SUMS` 时校验哈希。
