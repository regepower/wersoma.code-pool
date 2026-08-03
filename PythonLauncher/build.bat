@echo off
setlocal

echo ============================
echo PythonLauncher Build
echo ============================


rem ============================
rem Resource mit Icon erstellen
rem ============================

windres PythonLauncher.rc PythonLauncher.o


if errorlevel 1 (
    echo Fehler beim Erstellen der Resource!
    pause
    exit /b 1
)


rem ============================
rem EXE kompilieren
rem ============================

g++ PythonLauncher.cpp PythonLauncher.o ^
-o PythonLauncher.exe ^
-mwindows ^
-municode ^
-static


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
echo Signiere PythonLauncher.exe
echo.


"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe" sign ^
    /fd SHA256 ^
    /a ^
    /tr http://timestamp.digicert.com ^
    /td SHA256 ^
    PythonLauncher.exe


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
    PythonLauncher.exe


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