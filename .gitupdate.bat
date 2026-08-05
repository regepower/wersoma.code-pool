@echo off
cd /d "C:\Users\trolldenier\Documents\Makrosammlung.git"

echo ==========================================
echo  Hole zuerst Updates von GitHub...
echo ==========================================
git pull

echo.
echo ==========================================
echo  Pruefe nun auf lokale Aenderungen...
echo ==========================================
git add .

REM Prüft, ob durch 'git add' wirklich etwas im Staging-Bereich gelandet ist
git diff --staged --quiet
if %errorlevel% == 0 (
    echo Keine neuen Aenderungen gefunden. Alles ist aktuell!
    timeout /t 3
    exit /b
)

echo.
echo Es gibt Aenderungen!
set /p msg="Bitte kurze Beschreibung eingeben (oder Enter fuer Auto-Text): "

if "%msg%"=="" set msg=Auto-Update am %date% um %time%

echo.
echo Erstelle Commit und lade hoch...
git commit -m "%msg%"
git push

echo.
echo ==========================================
echo  Erfolgreich auf GitHub hochgeladen!
echo ==========================================
timeout /t 5
