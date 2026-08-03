@echo off
setlocal

if "%~1"=="" (
    echo Keine Datei angegeben.
    goto Ende
)

:Signieren
echo.
echo Signiere: %~1
echo.

"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" sign ^
    /fd SHA256 ^
    /a ^
    /tr http://timestamp.digicert.com ^
    /td SHA256 ^
    "%~1"

echo.
shift
if not "%~1"=="" goto Signieren

echo Fertig.

:Ende
pause
