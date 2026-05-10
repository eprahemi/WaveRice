#!/usr/bin/env bash
quickshell -p ~/.config/hypr/scripts/quickshell/Main.qml ipc call main forceReload
quickshell -p ~/.config/hypr/scripts/quickshell/TopBar.qml ipc call topbar forceReload
quickshell -p ~/.config/hypr/scripts/quickshell/Floating.qml ipc call floating forceReload
