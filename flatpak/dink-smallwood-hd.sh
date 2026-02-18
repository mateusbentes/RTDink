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

# Link game data from the app bundle
for dir in dink interface audio; do
    if [ ! -e "$DATA_DIR/$dir" ]; then
        ln -sf "$APP_SHARE/$dir" "$DATA_DIR/$dir"
    fi
done

# Link the binary
if [ ! -e "$DATA_DIR/RTDinkApp" ]; then
    ln -sf "/app/bin/RTDinkApp" "$DATA_DIR/RTDinkApp"
fi

cd "$DATA_DIR"
exec ./RTDinkApp "$@"
