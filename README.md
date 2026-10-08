# QuickShell Dynamic Island

A compact, centered top-bar widget for QuickShell. It combines a clock, searchable app launcher, and MPRIS music controls in one capsule.

## Features

- Shows the clock when no media is playing.
- Searches installed desktop applications and can filter to music/audio apps.
- Shows album art and a scrolling track title while music plays.
- Expands to playback controls and track seeking for MPRIS players.
- Offers 12-hour and 24-hour clock formats.

## Requirements

- Linux with a Wayland session supported by QuickShell. This is a QuickShell config, not a standalone application, and does not target X11 desktops.
- QuickShell installed with its standard QML modules.
- An MPRIS-compatible music player for the music interface.

Install QuickShell using the instructions for your Linux distribution in the [QuickShell installation guide](https://quickshell.org/docs/v0.1.0/guide/install-setup/).

## Install

```sh
git clone https://github.com/sheikhayubkhan9009-ui/quickshell-dynamic-island.git
cd quickshell-dynamic-island
sh install.sh
quickshell --config dynamic-island
```

To download without Git, use **Code > Download ZIP** on the GitHub repository, extract the archive, open a terminal in the extracted folder, and run `sh install.sh` followed by `quickshell --config dynamic-island`.

The installer copies the config into `${XDG_CONFIG_HOME:-~/.config}/quickshell/dynamic-island`. Running it again updates the installed QML files.

## Start Automatically

Add `quickshell --config dynamic-island` to your desktop environment or compositor's Wayland session startup. The exact setting depends on your desktop.

## Settings

Hover the capsule to open the app launcher when idle or media controls during playback. The 12h/24h selection and app filter are retained across QuickShell config reloads.