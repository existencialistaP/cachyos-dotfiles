#!/bin/sh
# Keeps the cliphist store watchers alive. Populates the clipboard history by
# watching wl-paste (text and images) and storing into cliphist, feeding the
# picker in clipboard.sh. Restarts a watcher if it ever dies (they are plain
# wl-paste --watch processes). flock guarantees a single instance.

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/niri-cliphist-store.lock"
flock -n 9 || exit 0

watch() {
    mime=$1
    while :; do
        wl-paste --type "$mime" --watch cliphist store
        sleep 1
    done
}

watch text &
watch image/png &
trap 'kill 0 2>/dev/null' INT TERM
wait