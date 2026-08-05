@echo off
setlocal

echo ============================
echo TInput Build
echo ============================

gcc -O2 -s TInput.c -o TInput.exe

if errorlevel 1 (
    echo.
    echo Fehler beim Kompilieren!
    pause
    exit /b 1
)


echo.
echo Build erfolgreich!


rem ============================
rem EXE signieren
rem ============================

echo.
echo Signiere TInput.exe
echo.


"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" sign ^
    /fd SHA256 ^
    /a ^
    /tr http://timestamp.digicert.com ^
    /td SHA256 ^
    TInput.exe


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
    TInput.exe


if errorlevel 1 (
    echo.
    echo Signaturpruefung fehlgeschlagen!
    pause
    exit /b 1
)


echo.
echo ============================
echo Build und Signierung fertig
echo ============================

pause