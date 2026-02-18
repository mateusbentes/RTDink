@echo off
CHCP 437 >NUL
setlocal

set GLADOS_HOST=glados@glados
set GLADOS_REPO=/home/glados/RTDink
set FLATPAK_ID=com.rtsoft.DinkSmallwoodHD
set BUNDLE_NAME=DinkSmallwoodHD.flatpak
set SCRIPT_DIR=%~dp0

echo ============================================
echo  Dink Smallwood HD - Flatpak Builder
echo ============================================
echo.

REM -- Step 1: Push current repo to glados --
echo [1/5] Pushing current repo to glados...

git remote get-url glados >NUL 2>&1
if errorlevel 1 (
    echo Adding glados as git remote...
    git remote add glados %GLADOS_HOST%:%GLADOS_REPO%
)

git push glados HEAD:flatpak-build --force
if errorlevel 1 (
    echo ERROR: Failed to push to glados. Is it reachable?
    pause
    exit /b 1
)
echo Push OK.
echo.

REM -- Step 2: Build on glados --
echo [2/5] Building Flatpak on glados (this may take a minute)...

ssh %GLADOS_HOST% "cd %GLADOS_REPO% && git checkout -- . && git clean -fd -e build-flatpak/ && git checkout flatpak-build && flatpak-builder --user --force-clean --install build-flatpak flatpak/%FLATPAK_ID%.json 2>&1 | tail -5"
if errorlevel 1 (
    echo ERROR: Flatpak build failed on glados.
    echo Run manually on glados to see full output:
    echo   cd %GLADOS_REPO% ^&^& flatpak-builder --user --force-clean --install build-flatpak flatpak/%FLATPAK_ID%.json
    pause
    exit /b 1
)
echo Build OK.
echo.

REM -- Step 3: Smoke test --
echo [3/5] Running smoke test (launching for 5 seconds)...

ssh %GLADOS_HOST% "timeout 5 flatpak run %FLATPAK_ID% 2>&1; echo SMOKE_TEST_DONE"
echo Smoke test done.
echo.

REM -- Step 4: Export bundle --
echo [4/5] Exporting .flatpak bundle...

ssh %GLADOS_HOST% "flatpak build-bundle ~/.local/share/flatpak/repo %GLADOS_REPO%/%BUNDLE_NAME% %FLATPAK_ID% 2>&1"
if errorlevel 1 (
    echo ERROR: Failed to export bundle.
    pause
    exit /b 1
)
echo Bundle exported on glados.
echo.

REM -- Step 5: Copy bundle back --
echo [5/5] Copying bundle to %SCRIPT_DIR%...

scp %GLADOS_HOST%:%GLADOS_REPO%/%BUNDLE_NAME% "%SCRIPT_DIR%%BUNDLE_NAME%"
if errorlevel 1 (
    echo ERROR: Failed to copy bundle from glados.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  SUCCESS!
echo  Bundle: %SCRIPT_DIR%%BUNDLE_NAME%
echo ============================================
echo.

for %%A in ("%SCRIPT_DIR%%BUNDLE_NAME%") do echo Size: %%~zA bytes
echo.
echo To install locally:  flatpak install %BUNDLE_NAME%
echo To upload to rtsoft:  use your upload script
echo.

pause
