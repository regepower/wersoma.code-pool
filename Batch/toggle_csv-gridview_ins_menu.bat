@echo off
chcp 65001 >nul

set "KEY=HKCU\Software\Classes\SystemFileAssociations\.csv\Shell\PowerShellView"

:: Prfen, ob der Schlssel existiert
reg query "%KEY%" >nul 2>&1
if %errorlevel% equ 0 goto :loeschen
goto :erstellen

:loeschen
echo [INFO] Kontextmenue-Eintrag vorhanden. Loesche ihn...
reg delete "%KEY%" /f
if %errorlevel% equ 0 (
    echo [OK] Eintrag erfolgreich entfernt.
) else (
    echo [FEHLER] Loeschen fehlgeschlagen.
)
goto :ende

:erstellen
echo [INFO] Kontextmenue-Eintrag nicht vorhanden. Erstelle ihn mit showCSV...
reg add "%KEY%" /ve /t REG_SZ /d "Mit showCSV anzeigen" /f
if %errorlevel% neq 0 goto :fehler

reg add "%KEY%" /v "Icon" /t REG_SZ /d "shell32.dll,152" /f
if %errorlevel% neq 0 goto :fehler

reg add "%KEY%\command" /ve /t REG_SZ /d "\"N:\Download\PortableApps\showCSV.exe\" \"%%1\"" /f
if %errorlevel% neq 0 goto :fehler

echo [OK] Eintrag erfolgreich erstellt.
goto :ende

:fehler
echo [FEHLER] Beim Erstellen des Eintrags ist ein Fehler aufgetreten.

:ende
pause
