# Agents

This dotfiles repo serves both my macOS laptop and Ubuntu cloud server.

Keep this split in mind when adding or editing files so each machine only sources what it needs.

`Mac/` and `Ubuntu/` hold the active machine-specific configs. `old/` is just for archival purposes.

## macOS symlinks

On macOS, these symlinks in `~` point back into this repository:

- `~/.zshrc` → `Mac/.zshrc`
- `~/.gitconfig` → `.gitconfig`
- `~/.pylintrc` → `.pylintrc`

## Ubuntu symlinks

On the Ubuntu server, these symlinks in `~` (and user-level systemd) point back into this repository:

- `~/.bash_profile` → `Ubuntu/.bash_profile`
- `~/.bashrc` → `Ubuntu/.bashrc`
- `~/.gitconfig` → `.gitconfig`
- `~/.inputrc` → `Ubuntu/.inputrc`
- `~/.pylintrc` → `.pylintrc`
- `~/.tmux.conf` → `Ubuntu/.tmux.conf`
- `~/.config/systemd/user/ssh-agent.service` → `Ubuntu/ssh-agent.service`
- `~/.config/systemd/user/default.target.wants/ssh-agent.service` → `Ubuntu/ssh-agent.service`

## Universal tips
- Use `s` to run commands as root while still loading user shell config
- Use `sl` to rerun last command with `sudo`
- Use `j <dir>` for fast jumps (`zoxide` on Mac, `autojump` on Ubuntu)

## macOS tips

- macOS uses `zsh`, and the active shell config lives in `Mac/.zshrc`.
- `zoxide` is enabled on Mac via `eval "$(zoxide init zsh)"`.
- Use `jj` for interactive directory selection because `jj` is aliased to `zi`.
- `fzf` is loaded from `~/.fzf.zsh`. Prefer `fzf`-based interactive selection over ad hoc shell loops when suggesting terminal workflows on Mac.
- `Ctrl-T` opens `fzf` path selection from the current directory tree, which is the quickest fuzzy file-finding workflow on Mac.
- If `Ctrl-T` stops working, regenerate `~/.fzf.zsh` with `/opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc`.
- `fd` is available as `fd` on Mac. Prefer it over `find` for concise file discovery.
- Example Mac commands: `j dotfiles`, `jj`, `fd AGENTS`, `fd -t f zsh Mac`, `fd . | fzf`.
- Mac also has `eza` aliases in `Mac/.zshrc`: `l`, `ll`, and `lt`.

## Ubuntu tips

- Ubuntu uses `bash`, not `zsh`. Keep shell changes in `Ubuntu/.bashrc` or `Ubuntu/.bash_profile`.
- `Ubuntu/.bash_profile` just sources `Ubuntu/.bashrc`, so interactive shell behavior should usually be added to `.bashrc`.
- Ubuntu currently wires up `autojump` if installed, not `zoxide`. Do not assume the Mac `jj` alias or `fzf` key bindings exist there.
- The Ubuntu user session expects a systemd-managed `ssh-agent`, with `SSH_AUTH_SOCK` pointing at `ssh-agent.socket`.
- Prefer GNU/Linux command conventions in Ubuntu-specific examples and keep macOS/Homebrew-specific advice out of Ubuntu sections.
