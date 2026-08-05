@echo off
setlocal enabledelayedexpansion

echo ============================
echo Dynamischer Build
echo ============================

rem =========================================
rem 1. Nach einer .c-Datei suchen
rem =========================================
set "cfile="
for %%f in (*.c) do (
    if defined cfile (
        echo Fehler: Es gibt mehrere .c-Dateien im Ordner.
        echo Bitte lassen Sie nur eine .c-Datei hier.
        pause
        exit /b 1
    )
    set "cfile=%%f"
)

if not defined cfile (
    echo Fehler: Keine .c-Datei im Ordner gefunden.
    pause
    exit /b 1
)

rem =========================================
rem 2. Basisnamen (ohne .c) extrahieren
rem =========================================
for %%i in ("!cfile!") do set "basename=%%~ni"

echo Gefundene Quelldatei: !cfile!
echo Basisname:            !basename!
echo.

rem =========================================
rem 3. Kompilieren
rem =========================================
gcc -DNDEBUG -mwindows -Os -s -fno-ident -fno-asynchronous-unwind-tables "!cfile!" -o "!basename!.exe"

if errorlevel 1 (
    echo.
    echo Fehler beim Kompilieren!
    pause
    exit /b 1
)

echo.
echo Build erfolgreich: !basename!.exe

rem =========================================
rem 4. EXE signieren
rem =========================================
echo.
echo Signiere !basename!.exe
echo.

"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" sign ^
    /fd SHA256 ^
    /a ^
    /tr http://timestamp.digicert.com ^
    /td SHA256 ^
    "!basename!.exe"

if errorlevel 1 (
    echo.
    echo Fehler beim Signieren!
    pause
    exit /b 1
)

echo.
echo Signatur pruefen...

"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" verify ^
    /pa ^
    "!basename!.exe"

if errorlevel 1 (
    echo.
    echo Signaturpruefung fehlgeschlagen!
    pause
    exit /b 1
)

rem =========================================
rem 5. Dateigr  e anzeigen
rem =========================================
echo.
echo ============================
echo Dateigroesse der erstellten EXE:
for %%i in ("!basename!.exe") do (
    set "size=%%~zi"
    set /a "size_kb=%%~zi / 1024"
    echo   !size! Bytes  ca. !size_kb! KiB
)
echo ============================

echo.
echo Build und Signierung fertig
pause
