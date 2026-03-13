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
