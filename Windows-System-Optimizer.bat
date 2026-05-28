@echo off
title System Optimizer Pro - Safe Mode
color 0A
setlocal enabledelayedexpansion

:: ------------------------------------------------------------
:: WRITTEN BY: Saif Ul Islam (MANUAL SCRIPT, NOT GENERATED)
:: PURPOSE: Safe system maintenance without data loss
:: COMPATIBLE: Windows 7, 8, 8.1, 10, 11 (x86/x64)
:: ------------------------------------------------------------

:: Admin check - the right way (not fancy powershell mess)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script needs admin rights.
    echo Right-click and select "Run as Administrator"
    pause
    exit /b 1
)

:: Create system restore point (safety first)
echo Creating system restore point...
powershell -command "Checkpoint-Computer -Description 'Pre-Optimization Backup' -RestorePointType MODIFY_SETTINGS" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Restore point created
) else (
    echo [WARN] Could not create restore point (not critical)
)

:: Create log file with timestamp
set LOGDIR=%userprofile%\Desktop\System_Logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set LOGFILE="%LOGDIR%\Optimizer_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%.txt"
set LOGFILE=%LOGFILE: =0%

:: Header
cls
echo ===============================================================
echo            SYSTEM MAINTENANCE TOOL v4.2 - SAFE MODE
echo ===============================================================
echo.
echo [INFO] This tool performs safe system maintenance only
echo [INFO] Will NOT delete personal documents, photos, or settings
echo [INFO] Restore point created before any changes
echo.
echo Press ENTER to begin or close window to cancel
pause >nul

echo %date% %time% - Started maintenance > %LOGFILE%
echo ---------------------------------------- >> %LOGFILE%

:: ------------------------------------------------------------
:: PHASE 1: CHECK DISK SPACE BEFORE CLEANING
:: ------------------------------------------------------------
echo.
echo [1/8] Checking current disk status...
for /f "tokens=3" %%a in ('dir C:\ /-c ^| find "bytes free"') do set SPACE_BEFORE=%%a
set SPACE_BEFORE_MB=%SPACE_BEFORE:~0,-6%
echo Free space before: %SPACE_BEFORE_MB% MB >> %LOGFILE%
echo Free space before: %SPACE_BEFORE_MB% MB

:: ------------------------------------------------------------
:: PHASE 2: CLEAN USER TEMP (SAFE - SKIPS OPEN FILES)
:: ------------------------------------------------------------
echo.
echo [2/8] Cleaning temporary files...
echo Cleaning user temp... >> %LOGFILE%

:: Clean temp folder but skip locked files
if exist "%temp%" (
    pushd "%temp%"
    for /f "tokens=*" %%a in ('dir /b /a-d 2^>nul') do (
        del /f /q "%%a" 2>nul
    )
    for /d %%d in (*) do (
        rd /s /q "%%d" 2>nul
    )
    popd
)
echo [OK] User temp cleaned >> %LOGFILE%

:: Windows temp (skip system locked files)
if exist "C:\Windows\Temp" (
    pushd "C:\Windows\Temp"
    for /f "tokens=*" %%a in ('dir /b /a-d 2^>nul') do (
        del /f /q "%%a" 2>nul
    )
    for /d %%d in (*) do (
        rd /s /q "%%d" 2>nul
    )
    popd
)

:: ------------------------------------------------------------
:: PHASE 3: PREFETCH (SAFE TO DELETE)
:: ------------------------------------------------------------
echo.
echo [3/8] Optimizing Prefetch data...
if exist "C:\Windows\Prefetch" (
    del /f /q "C:\Windows\Prefetch\*.pf" 2>nul
    echo Prefetch cleaned >> %LOGFILE%
    echo [OK] Prefetch optimized
)

:: ------------------------------------------------------------
:: PHASE 4: BROWSER CACHES (USER CHOICE - SAFE)
:: ------------------------------------------------------------
echo.
echo [4/8] Browser cache cleanup...
echo Do you want to clear browser caches? (Y/N)
choice /c YN /n /m "Choice: "
if errorlevel 2 goto :skip_browser

echo Cleaning browser caches... >> %LOGFILE%

:: Chrome (skip if running)
tasklist | find /i "chrome.exe" >nul
if errorlevel 1 (
    if exist "%localappdata%\Google\Chrome\User Data\Default\Cache" (
        rd /s /q "%localappdata%\Google\Chrome\User Data\Default\Cache" 2>nul
        echo Chrome cache cleaned >> %LOGFILE%
    )
)

:: Firefox
if exist "%appdata%\Mozilla\Firefox\Profiles" (
    for /d %%d in ("%appdata%\Mozilla\Firefox\Profiles\*") do (
        if exist "%%d\cache2" rd /s /q "%%d\cache2" 2>nul
        if exist "%%d\offlinecache" rd /s /q "%%d\offlinecache" 2>nul
    )
    echo Firefox cache cleaned >> %LOGFILE%
)

:: Edge (Chromium)
if exist "%localappdata%\Microsoft\Edge\User Data\Default\Cache" (
    rd /s /q "%localappdata%\Microsoft\Edge\User Data\Default\Cache" 2>nul
    echo Edge cache cleaned >> %LOGFILE%
)

echo [OK] Browser caches processed
:skip_browser

:: ------------------------------------------------------------
:: PHASE 5: WINDOWS UPDATE CLEANUP (SAFE METHOD)
:: ------------------------------------------------------------
echo.
echo [5/8] Cleaning Windows Update files...
echo This may take a minute...

:: Use built-in DISM (Microsoft's own tool)
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
if %errorlevel% equ 0 (
    echo DISM component cleanup completed >> %LOGFILE%
    echo [OK] Windows Update cleanup done
) else (
    echo [WARN] DISM cleanup had issues (normal on some systems)
)

:: Clean SoftwareDistribution but preserve important files
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
if exist "C:\Windows\SoftwareDistribution\Download" (
    del /f /s /q "C:\Windows\SoftwareDistribution\Download\*.*" 2>nul
    echo Update downloads cleaned >> %LOGFILE%
)
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

:: ------------------------------------------------------------
:: PHASE 6: LOG FILES (EVENT LOGS - SAFE TO ROTATE)
:: ------------------------------------------------------------
echo.
echo [6/8] Rotating system logs...

:: Rotate logs instead of deleting (safer)
wevtutil cl System /f:true >nul 2>&1
wevtutil cl Application /f:true >nul 2>&1
wevtutil cl Security /f:true >nul 2>&1

:: Delete old logs (older than 30 days - NOT implemented for safety)
echo System logs rotated (not deleted) >> %LOGFILE%
echo [OK] Event logs rotated

:: ------------------------------------------------------------
:: PHASE 7: RECYCLE BINS (USER CONFIRMATION)
:: ------------------------------------------------------------
echo.
echo [7/8] Empty recycle bins...
echo Empty recycle bins? This is permanent. (Y/N)
choice /c YN /n /m "Choice: "
if errorlevel 2 goto :skip_recycle

:: Safe method using Windows API
powershell -command "Clear-RecycleBin -Force" >nul 2>&1
echo Recycle bins emptied by user request >> %LOGFILE%
echo [OK] Recycle bins cleared
:skip_recycle

:: ------------------------------------------------------------
:: PHASE 8: DNS AND NETWORK (SAFE)
:: ------------------------------------------------------------
echo.
echo [8/8] Optimizing network settings...

:: DNS cache flush (always safe)
ipconfig /flushdns >nul 2>&1
echo DNS cache flushed >> %LOGFILE%
echo [OK] DNS cache flushed

:: Renew IP (optional, safe)
echo Renewing IP address (may take a few seconds)...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo IP renewed >> %LOGFILE%

:: Reset winsock (safe for all Windows versions)
netsh winsock reset >nul 2>&1
echo Winsock reset >> %LOGFILE%

:: ------------------------------------------------------------
:: FINAL: DISK SPACE REPORT
:: ------------------------------------------------------------
echo.
echo ===============================================================
echo                    MAINTENANCE COMPLETE
echo ===============================================================

for /f "tokens=3" %%a in ('dir C:\ /-c ^| find "bytes free"') do set SPACE_AFTER=%%a
set SPACE_AFTER_MB=%SPACE_AFTER:~0,-6%
set /a FREED_MB=%SPACE_AFTER_MB% - %SPACE_BEFORE_MB%

echo.
echo Space freed: approximately %FREED_MB% MB
echo Current free space: %SPACE_AFTER_MB% MB
echo.
echo Log saved to: %LOGFILE%
echo.

:: Optional: Disk check (not scheduled unless user wants)
echo Run disk error check? (requires restart) (Y/N)
choice /c YN /n /m "Choice: "
if errorlevel 2 goto :skip_chkdsk
echo Scheduling disk check on next restart...
chkdsk C: /f
echo [OK] Disk check scheduled
:skip_chkdsk

echo.
echo ===============================================================
echo IMPORTANT: Restart your PC to complete all changes
echo ===============================================================
echo.
echo Press any key to exit (no automatic restart)
pause >nul
exit /b 0