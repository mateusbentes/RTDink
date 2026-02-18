#!/bin/bash
# Wrapper script for Dink Smallwood HD inside Flatpak sandbox
#
# The game expects dink/, interface/, audio/, and dmods/ directories
# next to the binary. This script sets up the data directory
# and launches the game from there.

DATA_DIR="$XDG_DATA_HOME/dink-smallwood-hd"
APP_SHARE="/app/share/com.rtsoft.DinkSmallwoodHD"

mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/dmods"

# interface/ and audio/ are read-only, symlink directly
for dir in interface audio; do
    if [ ! -e "$DATA_DIR/$dir" ]; then
        ln -sf "$APP_SHARE/$dir" "$DATA_DIR/$dir"
    fi
done

# dink/ needs to be writable (save games go here) but game data is read-only.
# Create a real directory and symlink the read-only contents inside it.
# On updates, refresh symlinks to pick up any changed game data.
mkdir -p "$DATA_DIR/dink"
for item in "$APP_SHARE/dink/"*; do
    name=$(basename "$item")
    # Only create symlinks for items that aren't real files (i.e. user save data)
    if [ ! -f "$DATA_DIR/dink/$name" ]; then
        ln -sf "$item" "$DATA_DIR/dink/$name"
    fi
done

# Link the binary
if [ ! -e "$DATA_DIR/RTDinkApp" ]; then
    ln -sf "/app/bin/RTDinkApp" "$DATA_DIR/RTDinkApp"
fi

cd "$DATA_DIR"
exec ./RTDinkApp "$@"
