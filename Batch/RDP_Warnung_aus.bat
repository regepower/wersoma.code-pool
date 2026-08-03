@echo off
:: Entfernt temporär den Abfragerequeseter von win 11 seit April Update.
:: https://www.deskmodder.de/blog/2026/04/15/remote-desktop-mit-neuen-sicherheitsmassnahmen-unter-windows-10-11-und-server/

:: Admin-Rechte pruefen
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo Keine Admin-Rechte - starte reg.exe direkt als Administrator...
    powershell -Command "Start-Process 'reg.exe' -ArgumentList 'add \"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client\" /v RedirectionWarningDialogVersion /t REG_DWORD /d 1 /f' -Verb RunAs -Wait"
    goto :verify
)
 
:: Falls doch schon als Admin gestartet
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client" /v "RedirectionWarningDialogVersion" /t REG_DWORD /d 0x00000001 /f
 
:verify
:: Pruefen ob Schluessel wirklich gesetzt wurde
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client" /v "RedirectionWarningDialogVersion" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Registry-Eintrag erfolgreich gesetzt.
) else (
    echo [FEHLER] Eintrag wurde nicht gefunden - bitte UAC-Abfrage bestaetigen.
)
pause
 