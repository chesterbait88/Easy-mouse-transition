@echo off
setlocal enabledelayedexpansion
title Easy Mouse Transition - Setup Tool
color 0A

:MENU
cls
echo ===================================================
echo            EASY MOUSE TRANSITION TOOL
echo ===================================================
echo.
echo  1. Run PowerShell script directly
echo  2. Create EXE file (installs PS2EXE if needed)
echo  3. Run the created EXE file
echo  4. Exit
echo.
echo ===================================================
echo.

choice /C 1234 /N /M "Select an option [1-4]: "

if errorlevel 4 goto :EXIT
if errorlevel 3 goto :RUNEXE
if errorlevel 2 goto :CREATEEXE
if errorlevel 1 goto :RUNPS1

:RUNPS1
cls
echo ===================================================
echo           RUNNING POWERSHELL SCRIPT
echo ===================================================
echo.
echo Starting Mouse Position Tracker script...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0Easy-mouse-transition.ps1"
echo.
echo Script execution finished. Press any key to return to menu...
pause >nul
goto :MENU

:CREATEEXE
cls
echo ===================================================
echo               CREATING EXE FILE
echo ===================================================
echo.

:: Check if PS2EXE is installed
echo Checking if PS2EXE module is installed...
powershell -Command "$module = Get-Module -ListAvailable -Name ps2exe; if ($module) { Write-Output 'PS2EXE is installed.' } else { Write-Output 'PS2EXE is not installed.' }" > "%TEMP%\ps2exe_check.txt"
set /p PS2EXE_STATUS=<"%TEMP%\ps2exe_check.txt"
del "%TEMP%\ps2exe_check.txt"

echo %PS2EXE_STATUS%
echo.

if "%PS2EXE_STATUS%" == "PS2EXE is not installed." (
    echo Installing PS2EXE module...
    echo This may take a moment, please wait...
    powershell -Command "Install-Module -Name ps2exe -Scope CurrentUser -Force" || (
    echo Failed to install PS2EXE module.
    echo Please check your internet connection or try running PowerShell as administrator.
    echo Press any key to return to menu...
    pause >nul
    goto :MENU
    )
    echo PS2EXE module installed successfully.
    echo.
)

echo Creating EXE file from PowerShell script with custom icon...
powershell -Command "Invoke-ps2exe -InputFile '%~dp0Easy-mouse-transition.ps1' -OutputFile '%~dp0Easy-mouse-transition.exe' -NoConsole -IconFile '%~dp0Easy-mouse.ico'"

if not exist "%~dp0Easy-mouse-transition.exe" (
    echo Failed to create EXE file.
    echo Please check for errors and try again.
    echo Press any key to return to menu...
    pause >nul
    goto :MENU
) else (
    echo.
    echo EXE file created successfully: Easy-mouse-transition.exe
    echo.
    choice /C YN /N /M "Do you want to run the EXE now? [Y/N]: "
    if errorlevel 2 goto :MENU
    if errorlevel 1 goto :RUNEXE
)

:RUNEXE
cls
echo ===================================================
echo               RUNNING EXE FILE
echo ===================================================
echo.

if not exist "%~dp0Easy-mouse-transition.exe" (
    echo EXE file doesn't exist yet.
    echo Please create it first using option 2.
    echo Press any key to return to menu...
    pause >nul
    goto :MENU
)

echo Starting Easy-mouse-transition.exe...
echo The application will run in the system tray.
echo.
start "" "%~dp0Easy-mouse-transition.exe"
echo.
echo Application started. Look for the icon in your system tray.
echo Closing this window in 3 seconds...
timeout /t 3 >nul
exit

:EXIT
cls
echo ===================================================
echo Thank you for using Easy Mouse Transition Tool!
echo ===================================================
echo.
echo Exiting in 3 seconds...
timeout /t 3 >nul
exit
