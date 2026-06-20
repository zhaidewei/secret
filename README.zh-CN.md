# secret

![version](https://img.shields.io/badge/version-0.1.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) · [English](README.md)

macOS 钥匙串（Keychain）的薄封装，给 agent / 脚本管理凭据。把 API key、token、
密码存进登录钥匙串，用固定的 account 字段（`agent-secrets`）标记，从而能枚举出
"自己管的"那批，并直接注入命令——不碰 `.env`、不留 shell history、不进源码。

```sh
ALIBABA_CLOUD_ACCESS_KEY_ID=$(secret get aliyun-main-access-key-id) aliyun ecs DescribeInstances
```

`get` 在条目缺失 / 为空 / 钥匙串被锁时会大声失败（exit 1，报错到 stderr），而不是
返回空字符串——给脚本和 agent 用更安全。

## 要解决的问题

给 CLI 和 agent 用的凭据，通常会落在容易泄漏的地方：

- **`.env` / `.envrc`** —— 明文落盘，离 `git add .` 一步之遥，一旦提交就永久进历史。
- **`export VAR=...`** —— 进 shell history，且任何进程都能通过 `ps -E` 看到。
- **硬编码进源码** —— 随仓库到处跑，出现在 diff 和日志里。

macOS 本身有加密存储（钥匙串），但原生 `security` 命令用起来别扭：它列不出"自己的"
条目（埋在几百条系统项里）、命令冗长，而且缺 key 时静默返回空串，脚本会照样往下传。

`secret` 正好补这个缺口：凭据只待在钥匙串里，用时按需注入命令（`$(secret get NAME)`），
任何地方都没有明文；同时这个工具可枚举（`list`）、命名统一、fail-loud、带 Tab 补全。

## 安装

```sh
git clone git@github-personal:zhaidewei/secret.git
cd secret
./install.sh
```

`install.sh` 把 `secret` 软链到 `~/.local/bin`，把 zsh 补全 `_secret` 软链到
`$fpath` 里第一个可写目录。确保 `~/.local/bin` 在 `PATH` 上。

## 卸载

```sh
./uninstall.sh
```

删掉两个软链。存进钥匙串的凭据不动——`uninstall.sh` 绝不碰它们。要一并清掉，
先在卸载**之前**用 `secret list` 看一遍，再对每个 `secret rm <name>`。

## 用法

```
secret list                   列出所有托管的 key 名
secret list -l                列出 key 名 + 描述（表格）
secret get <name>             打印值到 stdout（无结尾换行）
secret add <name> [desc]      新增（隐藏式 tty 输入，或从 stdin 读）
secret update <name> [desc]   替换值；省略 desc 则保留原描述
secret rm <name>              删除
secret --version              打印版本
```

命名约定：`<vendor>-<env>-<type>`，例如 `aliyun-main-access-key-id`。

从管道写入（值不会以明文出现在 history 里）：

```sh
pbpaste | secret add databricks-dev-token "Databricks dev workspace PAT"
```

## Tab 补全（zsh）

装好后 `secret get <Tab>` 会补全 key 名：前缀唯一直接补上，否则弹出可用方向键
选择的菜单。依赖 `menu select`（oh-my-zsh 默认开启；否则在 `.zshrc` 加
`zstyle ':completion:*' menu select`）。

## 和其他密码工具的差异

| 工具 | 存储后端 | 主密码 | 额外依赖 | 同步 / 分享 | 适用场景 |
|---|---|---|---|---|---|
| **secret** | macOS Keychain | 无（随登录解锁） | 无（系统自带 `security`） | 无 | 本机单人，给 CLI/agent 注入凭据 |
| `security`（原生） | macOS Keychain | 无 | 无 | iCloud Keychain | 不想要任何封装的人 |
| `pass` | GPG 加密文件 | GPG passphrase | gpg + git | 自托管 git | 跨平台 CLI 党 |
| 1Password `op` | 1Password 云 | 账户主密码 | op 二进制 + 订阅 | 云同步 + 团队分享 | 团队 / 跨设备 |
| `.env` / 环境变量 | 明文文件 | 无 | 无 | 手动 | 不推荐，易随仓库泄漏 |
| HashiCorp Vault | 服务端 | token / policy | vault server | 集中式 + 审计 | 生产基础设施 |

最接近的两个：

- **对比原生 `security`**（同样用 Keychain）：`secret` 加了 `list`（靠固定 account
  字段，把自己管的条目从几百条系统钥匙串里筛出来）、fail-loud 的 `get`、统一的
  `<vendor>-<env>-<type>` 命名、以及 zsh 补全。原生 `security find-generic-password`
  命令长、不能枚举，缺 key 时静默返回空串。
- **对比 `pass` / 1Password**：它们提供同步、分享、审计、跨平台，代价是引入新的加密
  体系（GPG）或一个二进制 + 订阅，而且每次都要解主密码。`secret` 反过来——复用
  macOS 登录态，零主密码、零新依赖，代价是只在 macOS 本机、不能同步 / 分享 / 审计。

一句话：`secret` 不是密码库，是"把 Keychain 变成顺手的脚本凭据源"的薄封装。

## 适合谁 / 不适合谁

适合你，如果你：

- 在 **macOS** 上开发，凭据只在这一台机器上用；
- 经常给 **CLI、脚本、agent** 注入凭据，想要干净（`$(secret get NAME)`）、可枚举、
  命名统一、带 Tab 补全；
- 不想每次都输主密码。

去找别的工具，如果你需要：

- **跨设备同步 / 团队分享** → 1Password、Bitwarden、Vault；
- **跨平台**（Linux / Windows） → `pass`、Vault；
- **审计日志 / 合规 / 轮换策略** → Vault、AWS/GCP Secret Manager；
- 团队或服务的**共享生产密钥管理** → Vault。

`secret` 故意都不做这些——这是换取零依赖、零主密码的代价。

存储位置：`~/Library/Keychains/login.keychain-db`，macOS 登录后自动解锁。
