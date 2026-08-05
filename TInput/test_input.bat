@echo off
setlocal enabledelayedexpansion

echo === Test fÅr TInput.exe ===
echo.

REM PrÅfen, ob TInput.exe vorhanden ist
if not exist TInput.exe (
    echo TInput.exe nicht gefunden! Bitte kompiliere zuerst.
    exit /b 1
)

echo 1) Timeout 5 Sek., Prompt "Name: ", Vorgabe "Hans"
for /f "tokens=*" %%a in ('TInput "Name: " "Hans" 5') do set ERG1=%%a
echo Ergebnis: %ERG1%
echo.

echo 2) Kein Timeout, nur Vorgabe "Max" (ohne Prompt)
for /f "tokens=*" %%a in ('TInput "Max"') do set ERG2=%%a
echo Ergebnis: %ERG2%
echo.

echo 3) Nur Timeout 3 Sek. (kein Prompt, leere Vorgabe)
for /f "tokens=*" %%a in ('TInput 3') do set ERG3=%%a
echo Ergebnis: %ERG3%
echo.

echo 4) Prompt "Alter: ", Vorgabe "30", Timeout 10 Sek.
for /f "tokens=*" %%a in ('TInput "Alter: " "30" 10') do set ERG4=%%a
echo Ergebnis: %ERG4%
echo.

echo 5) Prompt "Eingabe: ", leere Vorgabe, Timeout 5 Sek.
for /f "tokens=*" %%a in ('TInput "Eingabe: " "" 5') do set ERG5=%%a
echo Ergebnis: %ERG5%
echo.

echo Alle Tests abgeschlossen.
pause
