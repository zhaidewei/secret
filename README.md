# secret

> An **AI-friendly, lightweight, free, macOS-only** secret manager.

![version](https://img.shields.io/badge/version-0.1.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) ![platform](https://img.shields.io/badge/platform-macOS-lightgrey) · [中文文档](README.zh-CN.md)

macOS Keychain wrapper for agent-managed secrets. Stores API keys / tokens /
passwords in the login keychain under a fixed account field (`agent-secrets`)
so they can be listed and injected into commands without ever touching
`.env` files, shell history, or source code.

```sh
ALIBABA_CLOUD_ACCESS_KEY_ID=$(secret get aliyun-main-access-key-id) aliyun ecs DescribeInstances
```

`get` fails loudly (exit 1, message to stderr) on a missing/empty/locked
entry instead of returning an empty string — safe for scripts and agents.

## The problem

Secrets for CLIs and agents usually end up somewhere they leak from:

- **`.env` / `.envrc`** — plaintext on disk, one `git add .` away from being
  committed and pushed forever.
- **`export VAR=...`** — lands in shell history and is visible to any process
  via `ps -E` / `/proc`.
- **Hardcoded in source** — travels with the repo, shows up in diffs and logs.

macOS already has an encrypted store (the Keychain), but the raw `security`
command is awkward for this: it can't list *your* entries (they're buried among
hundreds of system items), the commands are long, and a missing key returns a
silent empty string that scripts happily pass downstream.

And if you don't want to type *yet another* master password every time you
fetch a secret — the way `pass` or 1Password make you — the Keychain is already
unlocked by your macOS login, so there's no extra password at all.

`secret` fixes exactly that gap: secrets live only in the Keychain, get injected
into a command on demand (`$(secret get NAME)`) with no plaintext anywhere, and
the tool is enumerable (`list`), consistently named, fail-loud, and tab-completed.

## Install

```sh
git clone git@github-personal:zhaidewei/secret.git
cd secret
./install.sh
```

`install.sh` symlinks `secret` into `~/.local/bin` and the zsh completion
`_secret` into a directory on your `$fpath`. Make sure `~/.local/bin` is on
your `PATH`.

## Uninstall

```sh
./uninstall.sh
```

Removes both symlinks. Your stored secrets stay in the Keychain — `uninstall.sh`
never touches them. To wipe those too, run `secret list` and `secret rm <name>`
for each **before** uninstalling.

## Usage

```
secret list                   List all managed secret names
secret list -l                List names + descriptions (table)
secret get <name>             Print value to stdout (no trailing newline)
secret add <name> [desc]      Add new secret (hidden tty prompt, or stdin)
secret update <name> [desc]   Replace value; desc omitted => keep existing
secret rm <name>              Delete a secret
secret --version              Print version
```

Naming convention: `<vendor>-<env>-<type>`, e.g. `aliyun-main-access-key-id`.

Add from a pipe (value never appears as a literal in history):

```sh
pbpaste | secret add databricks-dev-token "Databricks dev workspace PAT"
```

## Tab completion

After install, `secret get <Tab>` completes key names from `secret list`.

- **zsh** — unique prefix fills in directly, otherwise an arrow-navigable menu
  appears. Requires `menu select` (oh-my-zsh enables it by default; otherwise
  add `zstyle ':completion:*' menu select` to `.zshrc`).
- **bash** — completes the same names; Tab cycles, double-Tab lists candidates
  (no arrow menu — that's a zsh feature). Needs the `bash-completion` package.

## How it compares

| Tool | Backend | Master password | Extra deps | Sync / sharing | Best for |
|---|---|---|---|---|---|
| **secret** | macOS Keychain | none (login unlock) | none (built-in `security`) | none | single machine, injecting creds into CLI/agents |
| `security` (raw) | macOS Keychain | none | none | iCloud Keychain | people who want no wrapper |
| `pass` | GPG-encrypted files | GPG passphrase | gpg + git | self-hosted git | cross-platform CLI users |
| 1Password `op` | 1Password cloud | account password | op binary + subscription | cloud sync + team sharing | teams / multi-device |
| `.env` / env vars | plaintext file | none | none | manual | not recommended — leaks with the repo |
| HashiCorp Vault | server | token / policy | vault server | centralized + audit | production infrastructure |

The two closest tools:

- **vs raw `security`** (same Keychain): `secret` adds `list` (a fixed account
  field filters *your* entries out of the hundreds of system keychain items),
  fail-loud `get`, a `<vendor>-<env>-<type>` naming convention, and zsh
  completion. Raw `security find-generic-password` can't enumerate and returns
  a silent empty string on a missing key.
- **vs `pass` / 1Password**: they give sync, sharing, audit, and cross-platform
  support — at the cost of a new crypto system (GPG) or a binary + subscription,
  plus a master-password unlock every time. `secret` goes the other way: reuse
  the macOS login session, zero master password, zero new dependencies — in
  exchange for being macOS-only with no sync/sharing/audit.

In short: `secret` is not a password vault. It's a thin layer that turns the
Keychain into a convenient credential source for scripts.

## Who it's for

A good fit if you:

- work on **macOS** and want credentials to stay on this one machine;
- frequently inject secrets into **CLIs, scripts, or agents** and want it clean
  (`$(secret get NAME)`), enumerable, consistently named, and tab-completed;
- don't want to type a master password every time.

Look elsewhere if you need:

- **cross-device sync or team sharing** → 1Password, Bitwarden, Vault;
- **cross-platform** (Linux / Windows) → `pass`, Vault;
- **audit logs / compliance / rotation policies** → Vault, AWS/GCP Secret Manager;
- **shared production secret management** for a team or services → Vault.

`secret` deliberately has none of those — that's the trade for zero dependencies
and zero master password.

Storage: `~/Library/Keychains/login.keychain-db`, unlocked at macOS login.
