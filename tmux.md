# tmux

## Goal

Make `tmux` feel more direct and GUI-like without over-customizing it.

## Preferences

These are the defaults I want to keep when moving to a new machine:

1. Enable mouse support.
2. Start window numbering from `1`.
3. Start pane numbering from `1`.
4. Use `|` for horizontal split and `-` for vertical split.
5. Renumber windows automatically after closing one.
6. Use clearer automatic window titles.
7. Prefer better terminal color support and faster status refresh.
8. Keep clipboard integration working with the system clipboard.
9. Use `TPM`, `tmux-sensible`, and `tmux-yank`.

## Preferred Config

```tmux
# Mouse support for pane selection, resizing, and scrollback.
set -g mouse on

# Start window and pane numbering at 1 and keep numbering contiguous.
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# More direct split bindings.
unbind '"'
unbind %
bind | split-window -h
bind - split-window -v

# Window names should follow the active program, with a stable terminal title.
setw -g automatic-rename on
setw -g automatic-rename-format '#{?pane_in_mode,[copy],#{pane_current_command}}'
set -g set-titles on
set -g set-titles-string '#S:#I:#W'

# Better color handling and more responsive refresh behavior.
set -g default-terminal "tmux-256color"
set -ga terminal-features ",xterm-256color:RGB"
set -g focus-events on
set -g status-interval 5

# Clipboard integration works well with tmux-yank and modern terminals.
set -s set-clipboard on

# Plugins managed through TPM.
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'

# Initialize TPM. Keep this line at the bottom.
run '~/.tmux/plugins/tpm/tpm'
```

## Plugin Notes

### `tmux-sensible`

Keep it installed as a conservative baseline plugin. It overlaps a little with the manual config, mainly in these areas:

- `status-interval`
- `focus-events`
- some default terminal handling
- a few generic quality-of-life defaults like `escape-time`, `history-limit`, and `display-time`

Important: it does not override explicit user settings, so keep writing the exact behaviors I care about in `.tmux.conf`.

### `tmux-yank`

Keep it for clipboard integration. It does not replace the main layout/settings above.

What it adds:

- copy selected text to the system clipboard
- mouse drag selection integration
- copy-mode bindings such as `y`

It depends on having a valid clipboard backend on the current OS.

## Cross-Platform Clipboard Backend

Use `tmux-yank`, but verify the clipboard command per platform:

- WSL: `clip.exe`
- Linux X11: `xsel` or `xclip`
- Linux Wayland: `wl-copy`
- macOS: `pbcopy`

If auto-detection fails, set:

```tmux
set -g @override_copy_command 'your-copy-command'
```

## Install Checklist

1. Install `tmux`.
2. Clone TPM:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

3. Put the preferred config into `~/.tmux.conf`.
4. Start `tmux`.
5. Press `prefix + I` to let TPM install/load plugins.

## References

- `https://github.com/tmux-plugins/tpm`
- `https://github.com/tmux-plugins/tmux-sensible`
- `https://github.com/tmux-plugins/tmux-yank`
