#!/usr/bin/env bash

DOTFILE_DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILE_DEV_ROOT/modules/00_core.sh"
source "$DOTFILE_DEV_ROOT/modules/10_shell_basics.sh"
source "$DOTFILE_DEV_ROOT/modules/20_profiles.sh"
source "$DOTFILE_DEV_ROOT/modules/30_system_tools.sh"
source "$DOTFILE_DEV_ROOT/modules/40_sync_tools.sh"
source "$DOTFILE_DEV_ROOT/modules/50_runtime_tools.sh"

dotfile_cli_dispatch_if_executed "$@"
