# Agents

This dotfiles repo serves both my macOS laptop and Ubuntu cloud server.

- Shared configuration lives in files such as the git settings that apply in both environments.
- macOS-only files cover the Zsh shell setup under `Mac/` (including completions), any other Mac-specific tooling, and the symlinks that point `~/.zshrc`, `~/.gitconfig`, and `~/.pylintrc` back to their counterparts here.
- Ubuntu-only files include Bash shell settings and other Linux-specific configuration.

Keep this split in mind when adding or editing files so each machine only sources what it needs.
