@echo off
REM === Hunting Ground - Windows Build Script ===
REM Usage: tools\build.bat
REM Prerequisites: Godot 4.6 export templates installed

set GODOT="D:\Program Files (x86)\Godot\Godot_v4.6-stable_win64_console.exe"

if not exist %GODOT% (
    echo [ERROR] Godot console not found at %GODOT%
    echo Please update GODOT path in tools\build.bat
    exit /b 1
)

echo [1/3] Creating build directory...
if not exist build mkdir build

echo [2/3] Exporting Windows release build...
%GODOT% --headless --export-release "Windows" "build/Hunting Ground.exe"
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Export failed.
    echo.
    echo === How to Install Export Templates ===
    echo 1. Open Godot Editor
    echo 2. Editor menu ^> Manage Export Templates
    echo 3. Click "Download and Install" (~800 MB)
    echo 4. Re-run: tools\build.bat
    echo.
    echo Manual download: https://godotengine.org/download/windows/
    exit /b 1
)

echo [3/3] Build complete! Output: build\Hunting Ground.exe
exit /b 0
