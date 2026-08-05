@echo off
cd /d "C:\Users\trolldenier\Documents\Makrosammlung.git"

echo Pruefe auf Aenderungen...
git add .

REM Prüft, ob durch 'git add' wirklich etwas im Staging-Bereich gelandet ist
git diff --staged --quiet
if %errorlevel% == 0 (
    echo Keine neuen Aenderungen gefunden. Alles ist aktuell.
    timeout /t 5
    exit /b
)

echo Es gibt Aenderungen!
set /p msg="Bitte kurze Beschreibung eingeben (oder Enter fuer Auto-Text): "

if "%msg%"=="" set msg=Auto-Update am %date% um %time%

echo Erstelle Commit und lade hoch...
git commit -m "%msg%"
git push

echo.
echo Erfolgreich auf GitHub hochgeladen!
timeout /t 5