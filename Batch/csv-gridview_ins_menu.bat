@echo off
chcp 65001 >nul

fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo Keine Admin-Rechte - starte Skript als Administrator neu...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [INFO] Admin-Rechte vorhanden. Registriere CSV-Kontextmenue...

reg add "HKLM\SOFTWARE\Classes\SystemFileAssociations\.csv\Shell\PowerShellView" /ve /t REG_SZ /d "Mit PowerShell GridView anzeigen" /f
reg add "HKLM\SOFTWARE\Classes\SystemFileAssociations\.csv\Shell\PowerShellView" /v "Icon" /t REG_SZ /d "shell32.dll,152" /f

:: Inline-Befehl mit Fehlerabfang
reg add "HKLM\SOFTWARE\Classes\SystemFileAssociations\.csv\Shell\PowerShellView\command" /ve /t REG_SZ /d "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""try { Import-Csv -LiteralPath '%%1' -ErrorAction Stop | Out-GridView } catch { Write-Host 'Fehler:' $_.Exception.Message; Read-Host 'Druecke Enter' }""" /f

echo.
echo [OK] Eintrag gesetzt. Teste es jetzt mit Rechtsklick auf eine CSV.
pause
