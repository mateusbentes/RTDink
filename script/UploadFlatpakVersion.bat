@echo off
setlocal

set SCRIPT_DIR=%~dp0

echo Uploading Flatpak bundles...
echo.

for %%F in ("%SCRIPT_DIR%DinkSmallwoodHD-*.flatpak") do (
    echo Uploading %%~nxF...
    call %RT_PROJECTS%\UploadFileToRTsoftSSH.bat %%~nxF dink
    if errorlevel 1 (
        echo ERROR: Failed to upload %%~nxF
        pause
        exit /b 1
    )
    echo.
)

echo All bundles uploaded.
pause