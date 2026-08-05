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

REM ---------- Zeit im Format HH:MM:SS (ohne Millisekunden) erzeugen ----------
set "hh=%time:~0,2%"
if "%hh:~0,1%"==" " set "hh=0%hh:~1%"
set "mm=%time:~3,2%"
set "ss=%time:~6,2%"
set "zeit=%hh%:%mm%:%ss%"

REM ---------- TInput mit Prompt, Default (inkl. Zeit) und Timeout 10 Sek. ----------
for /f "tokens=*" %%a in ('N:\Download\PortableApps\TInput.exe "Bitte kurze Beschreibung eingeben (oder Enter fuer Auto-Text): " "Auto-Update am %date% um %zeit%"') do set msg=%%a

echo.
echo Erstelle Commit und lade hoch...
git commit -m "%msg%"
git push

echo.
echo ==========================================
echo  Erfolgreich auf GitHub hochgeladen!
echo ==========================================
timeout /t 5
