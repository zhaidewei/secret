# secret

macOS Keychain wrapper for agent-managed secrets. Stores API keys / tokens /
passwords in the login keychain under a fixed account field (`agent-secrets`)
so they can be listed and injected into commands without ever touching
`.env` files, shell history, or source code.

```sh
ALIBABA_CLOUD_ACCESS_KEY_ID=$(secret get aliyun-main-access-key-id) aliyun ecs DescribeInstances
```

`get` fails loudly (exit 1, message to stderr) on a missing/empty/locked
entry instead of returning an empty string — safe for scripts and agents.

## Install

```sh
git clone git@github-personal:zhaidewei/secret.git
cd secret
./install.sh
```

`install.sh` symlinks `secret` into `~/.local/bin` and the zsh completion
`_secret` into a directory on your `$fpath`. Make sure `~/.local/bin` is on
your `PATH`.

## Usage

```
secret list                   List all managed secret names
secret list -l                List names + descriptions (table)
secret get <name>             Print value to stdout (no trailing newline)
secret add <name> [desc]      Add new secret (hidden tty prompt, or stdin)
secret update <name> [desc]   Replace value; desc omitted => keep existing
secret rm <name>              Delete a secret
```

Naming convention: `<vendor>-<env>-<type>`, e.g. `aliyun-main-access-key-id`.

Add from a pipe (value never appears as a literal in history):

```sh
pbpaste | secret add databricks-dev-token "Databricks dev workspace PAT"
```

## Tab completion (zsh)

After install, `secret get <Tab>` completes key names — unique prefix fills
in directly, otherwise an arrow-navigable menu appears. Requires
`menu select` (oh-my-zsh enables it by default; otherwise add
`zstyle ':completion:*' menu select` to `.zshrc`).

Storage: `~/Library/Keychains/login.keychain-db`, unlocked at macOS login.
