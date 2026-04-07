#!/usr/bin/env bash

# Development entrypoint. The build script expands the source lines below
# into a single distributable bashrc_common.sh artifact.
DOTFILE_DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILE_DEV_ROOT/modules/core/constants.sh"
source "$DOTFILE_DEV_ROOT/modules/core/region.sh"
source "$DOTFILE_DEV_ROOT/modules/core/artifact.sh"
source "$DOTFILE_DEV_ROOT/modules/core/install_ssh.sh"
source "$DOTFILE_DEV_ROOT/modules/core/install.sh"
source "$DOTFILE_DEV_ROOT/modules/core/cli.sh"
source "$DOTFILE_DEV_ROOT/modules/core/update.sh"

source "$DOTFILE_DEV_ROOT/modules/shell/navigation.sh"

source "$DOTFILE_DEV_ROOT/modules/network/inspection.sh"
source "$DOTFILE_DEV_ROOT/modules/network/environment.sh"
source "$DOTFILE_DEV_ROOT/modules/network/proxy_diagnostics.sh"

source "$DOTFILE_DEV_ROOT/modules/filesystem/archives.sh"
source "$DOTFILE_DEV_ROOT/modules/filesystem/backup_restore.sh"

source "$DOTFILE_DEV_ROOT/modules/gpu/shortcuts.sh"

source "$DOTFILE_DEV_ROOT/modules/python/envs.sh"
source "$DOTFILE_DEV_ROOT/modules/python/huggingface_downloads.sh"
source "$DOTFILE_DEV_ROOT/modules/python/vllm_bench.sh"

source "$DOTFILE_DEV_ROOT/modules/profiles/claude.sh"
source "$DOTFILE_DEV_ROOT/modules/profiles/codex.sh"

source "$DOTFILE_DEV_ROOT/modules/system/path.sh"
source "$DOTFILE_DEV_ROOT/modules/system/transfer_presets.sh"
source "$DOTFILE_DEV_ROOT/modules/system/process_inspection.sh"

source "$DOTFILE_DEV_ROOT/modules/docker/shell.sh"
source "$DOTFILE_DEV_ROOT/modules/docker/shortcuts.sh"
source "$DOTFILE_DEV_ROOT/modules/docker/image_sync.sh"

source "$DOTFILE_DEV_ROOT/modules/sync/core.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/huggingface_models.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/directories.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/huggingface_cache.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/claude.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/codex.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/opencode.sh"
source "$DOTFILE_DEV_ROOT/modules/sync/vibe.sh"

# When the file is sourced, this returns immediately. When executed via
# `bash bashrc_common.sh ...` or `bash -s -- ...`, it dispatches CLI commands.
dotfile_cli_dispatch_if_executed "$@"
