#!/bin/bash
# === Hunting Ground — Windows Build Script ===
# Requires: Godot 4.6 export templates installed
# Usage: bash tools/build.sh

GODOT="D:/Program Files (x86)/Godot/Godot_v4.6-stable_win64_console.exe"

if [ ! -f "$GODOT" ]; then
    echo "[ERROR] Godot console not found at $GODOT"
    echo "Please update GODOT path in tools/build.sh"
    exit 1
fi

echo "[1/3] Creating build directory..."
mkdir -p build

echo "[2/3] Exporting Windows release build..."
"$GODOT" --headless --export-release "Windows" "build/Hunting Ground.exe"
if [ $? -ne 0 ]; then
    echo "[ERROR] Export failed! Check that export templates are installed."
    echo "Open Godot Editor > Editor > Manage Export Templates > Download and Install"
    exit 1
fi

echo "[3/3] Build complete!"
echo "Output: build/Hunting Ground.exe"
