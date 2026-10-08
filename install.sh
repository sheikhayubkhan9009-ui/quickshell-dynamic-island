#!/bin/sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
target_dir="$config_home/quickshell/dynamic-island"

if ! command -v quickshell >/dev/null 2>&1; then
    printf '%s\n' "QuickShell is required. Install it for your Linux distribution, then run this script again." >&2
    exit 1
fi

for file in shell.qml CircularArtwork.qml; do
    if [ ! -f "$script_dir/$file" ]; then
        printf 'Required file not found: %s\n' "$script_dir/$file" >&2
        exit 1
    fi
done

mkdir -p "$target_dir"
cp "$script_dir/shell.qml" "$target_dir/shell.qml"
cp "$script_dir/CircularArtwork.qml" "$target_dir/CircularArtwork.qml"

printf 'Installed QuickShell Dynamic Island to %s\n' "$target_dir"
printf '%s\n' 'Run it with: quickshell --config dynamic-island'