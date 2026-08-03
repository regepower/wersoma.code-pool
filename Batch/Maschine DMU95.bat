@echo off
chcp 1252 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: Arbeitsverzeichnis robust setzen
pushd "%~dp0" >nul 2>&1

:: ============================================================
::  WERSOMA GmbH - CNC Dateiuebertragung
::  Maschine : DMU95
::  IP       : 10.4.2.83
::  TNCcmd   : N:\Sicherung_Maschinen\BACKUP_TOOLS\tnccmd.exe
:: ============================================================
::  Erlaubte Endungen: .h .bmp .png .jpg .jpeg .stl
:: ============================================================
::  DEBUG: Zeile aktiv = haelt nach jedem Schritt an
::  Zum Abschalten :: vor "set" setzen
set "_DEBUG=pause"
:: ============================================================

set "MACHINE_LABEL=DMU95"
set "MACHINE_IP=10.4.2.83"
set "TNCCMD=N:\Sicherung_Maschinen\BACKUP_TOOLS\tnccmd.exe"
set "WERSOMA_BASIS=N:\00_Fertigungsdaten\Wersoma"

echo ============================================================
echo   WERSOMA Dateiuebertragung - Maschine %MACHINE_LABEL% (%MACHINE_IP%)
echo ============================================================
echo.

:: ============================================================
::  Schritt 1: Eingabe pruefen
:: ============================================================
echo [Schritt 1] Eingabe pruefen...
if "%~1"=="" goto :err_noarg
set "QUELLE=%~1"
echo          QUELLE (Basis-Referenz) = %QUELLE%
%_DEBUG%

:: ============================================================
::  Schritt 2: Wersoma-Basispfad pruefen
:: ============================================================
echo [Schritt 2] Basispfad-Pruefung...
echo(%QUELLE%| findstr /I /C:"%WERSOMA_BASIS%" >nul
if errorlevel 1 goto :err_basis
echo [OK]      Wersoma-Pfad erkannt.
%_DEBUG%

:: ============================================================
::  Schritt 3: Ordner oder Datei(en)?
:: ============================================================
echo [Schritt 3] Typ- und Endungspruefung...
set "IS_FOLDER=0"
pushd "%QUELLE%" 2>nul
if not errorlevel 1 popd & set "IS_FOLDER=1"
echo          IS_FOLDER = !IS_FOLDER!

if "!IS_FOLDER!"=="1" goto :step3_done

:: --- Dateiendung(en) aller uebergebenen Dateien pruefen ---
for %%A in (%*) do (
    set "_EXT=%%~xA"
    call :UC _EXT
    set "EXT_OK=0"
    if /i "!_EXT!"==".H"    set "EXT_OK=1"
    if /i "!_EXT!"==".BMP"  set "EXT_OK=1"
    if /i "!_EXT!"==".PNG"  set "EXT_OK=1"
    if /i "!_EXT!"==".JPG"  set "EXT_OK=1"
    if /i "!_EXT!"==".JPEG" set "EXT_OK=1"
    if /i "!_EXT!"==".STL"  set "EXT_OK=1"

    if "!EXT_OK!"=="0" (
        echo [FEHLER] Ungueltige Datei gefunden: %%~nxA ^(!_EXT!^)
        goto :err_ext
    )
)
echo [OK]      Alle Dateiendungen erlaubt.

:step3_done
%_DEBUG%

:: ============================================================
::  Schritt 4: Pfad-Zerlegung (nutzt Referenz-Pfad %1)
:: ============================================================
echo [Schritt 4] Pfad-Zerlegung...

set "BASIS_LEN=0"
set "_TMP=%WERSOMA_BASIS%"
:LEN_LOOP
if "!_TMP!"=="" goto :LEN_DONE
set "_TMP=!_TMP:~1!"
set /a BASIS_LEN+=1
goto :LEN_LOOP
:LEN_DONE
set /a REST_START=BASIS_LEN+1
set "REST=!QUELLE:~%REST_START%!"
echo          REST (nach Basis) = !REST!

set "T1=" & set "T2=" & set "T3=" & set "T4=" & set "T5="
set "T6=" & set "T7=" & set "T8=" & set "T9="
set "_IDX=0"
set "_R=!REST!"
:SPLIT_LOOP
if "!_R!"=="" goto :SPLIT_DONE
for /f "tokens=1* delims=\" %%A in ("!_R!") do (
    set /a _IDX+=1
    set "T!_IDX!=%%A"
    set "_R=%%B"
)
goto :SPLIT_LOOP
:SPLIT_DONE

set "ARCHIV_NR="
for /f "tokens=2 delims=_" %%A in ("!T1!") do set "ARCHIV_NR=%%A"
if not defined ARCHIV_NR set "ARCHIV_NR=!T1!"
set "BEREICH=!T2!"
set "AUFTRAG=!T3!"

set "OPTORD="
set "TEIL_RAW="
if /i "!T4!"=="CAM" (
    set "TEIL_RAW=!T5!"
) else (
    set "OPTORD=!T4!"
    set "TEIL_RAW=!T6!"
)

set "_TEIL_T1="
set "_TEIL_T2="
for /f "tokens=1,2" %%A in ("!TEIL_RAW!") do (
    set "_TEIL_T1=%%A"
    set "_TEIL_T2=%%B"
)

echo.!_TEIL_T1!| findstr /c:"-" >nul 2>&1
if not errorlevel 1 (
    set "TEIL_KURZ=!_TEIL_T1!"
) else (
    if defined _TEIL_T2 (
        set "TEIL_KURZ=!_TEIL_T1!-!_TEIL_T2!"
    ) else (
        set "TEIL_KURZ=!_TEIL_T1!"
    )
)

call :UC ARCHIV_NR
call :UC BEREICH
call :UC AUFTRAG
call :UC TEIL_KURZ
if defined OPTORD call :UC OPTORD

set "OPT="
if defined OPTORD set "OPT=\!OPTORD!"

echo [Schritt 5] Pfad-Variablen nach Konvertierung...
echo          ARCHIV_NR = !ARCHIV_NR!
echo          BEREICH   = !BEREICH!
echo          AUFTRAG   = !AUFTRAG!
echo          OPTORD    = !OPTORD!
echo          TEIL_RAW  = !TEIL_RAW!
echo          TEIL_KURZ = !TEIL_KURZ!
%_DEBUG%

:: ============================================================
::  Schritt 6: TNC-Zielpfad aufbauen
:: ============================================================
set "TNC_ZIEL=TNC:\PROGRAMME\WERSOMA\!ARCHIV_NR!\!BEREICH!\!AUFTRAG!!OPT!\!TEIL_KURZ!"
echo [Schritt 6] TNC-Zielpfad...
echo          TNC_ZIEL = !TNC_ZIEL!
%_DEBUG%

:: ============================================================
::  Schritt 7: Quellordner aktivieren & Dateiliste aufbauen
:: ============================================================
echo [Schritt 7] Wechsel in Quellordner und erstelle Dateiliste...
set "TMPLIST=%TEMP%\wersoma_dmu95_%RANDOM%.tmp"
if exist "%TMPLIST%" del "%TMPLIST%" >nul 2>&1

:: Quellverzeichnis bestimmen
if "!IS_FOLDER!"=="1" (
    set "SRC_DIR=%~1"
) else (
    set "SRC_DIR=%~dp1"
)

:: In Quellordner wechseln
pushd "!SRC_DIR!" 2>nul
if errorlevel 1 goto :err_pushd

if "!IS_FOLDER!"=="1" (
    :: Ganzer Ordner: Alle zulaessigen Typen einsammeln
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$exts = @('.h','.bmp','.png','.jpg','.jpeg','.stl'); " ^
        "Get-ChildItem -File | " ^
        "Where-Object { $exts -contains $_.Extension.ToLower() } | " ^
        "Select-Object -ExpandProperty Name | " ^
        "Out-File -FilePath '%TMPLIST%' -Encoding ascii"
) else (
    :: Einzelne oder mehrere Dateien: Alle uebergebenen Parameter (%*) in Liste schreiben
    (for %%A in (%*) do @echo %%~nxA) > "%TMPLIST%"
)

if not exist "%TMPLIST%" goto :err_nofiles
for %%A in ("%TMPLIST%") do if %%~zA==0 goto :err_nofiles

set "FILE_COUNT=0"
for /f "usebackq delims=" %%L in ("%TMPLIST%") do set /a FILE_COUNT+=1
echo [OK]      !FILE_COUNT! Datei^(en^) in "!SRC_DIR!" erfasst.
%_DEBUG%

:: ============================================================
::  Uebersicht der zu uebertragenden Dateien
:: ============================================================
cls
echo.
echo ============================================================
echo   WERSOMA Dateiuebertragung - Maschine %MACHINE_LABEL% (%MACHINE_IP%)
echo ============================================================
echo.
echo   Quellordner : !SRC_DIR!
echo   Ziel TNC    : !TNC_ZIEL!
echo.
echo   -------------------------------------------------------------
echo   Folgende !FILE_COUNT! Datei^(en^) werden uebertragen:
echo   -------------------------------------------------------------
for /f "usebackq delims=" %%F in ("%TMPLIST%") do echo     %%F
echo.

:: ============================================================
::  Schritt 8: Existenzpruefung auf der TNC
:: ============================================================
echo [Schritt 8] Pruefe ob Dateien bereits auf !MACHINE_LABEL! vorhanden sind...
echo.

set "EXIST_COUNT=0"
for /f "usebackq delims=" %%F in ("%TMPLIST%") do (
    "!TNCCMD!" -i!MACHINE_IP! -LD "FILEINFO \"!TNC_ZIEL!\%%F\"" >nul 2>&1
    if not errorlevel 1 (
        set /a EXIST_COUNT+=1
        echo   [!] Bereits vorhanden: %%F
    ) else (
        echo   [ ] Neu:               %%F
    )
)
echo.
echo          !EXIST_COUNT! Datei^(en^) bereits vorhanden.
%_DEBUG%

:: ============================================================
::  Bestaetigung / Rueckfrage
:: ============================================================
if !EXIST_COUNT! GTR 0 goto :confirm_overwrite
goto :confirm_new

:confirm_overwrite
echo ============================================================
echo   ACHTUNG: !EXIST_COUNT! Datei^(en^) existieren bereits auf !MACHINE_LABEL!
echo   Diese werden beim Fortfahren ueberschrieben.
echo ============================================================
echo.
choice /c JN /m "Trotzdem uebertragen und ueberschreiben? [J=Ja / N=Abbrechen] "
if errorlevel 2 goto :cancelled
goto :start_transfer

:confirm_new
echo   Alle Dateien sind neu - keine Konflikte.
echo.
choice /c JN /m "Uebertragung jetzt starten? [J=Ja / N=Abbrechen] "
if errorlevel 2 goto :cancelled
goto :start_transfer

:start_transfer
:: ============================================================
::  Schritt 9: Zielordner anlegen
:: ============================================================
echo.
echo [Schritt 9] Erstelle Zielordner auf TNC...
"!TNCCMD!" -i!MACHINE_IP! -LD "MKDIR \"!TNC_ZIEL!\"" >nul 2>&1
%_DEBUG%

:: ============================================================
::  Schritt 10: Uebertragung
:: ============================================================
echo.
echo [Schritt 10] Starte Uebertragung...
echo.
set "OK_COUNT=0"
set "ERR_COUNT=0"

for /f "usebackq delims=" %%F in ("%TMPLIST%") do (
    echo   Sende: %%F

    "!TNCCMD!" -i!MACHINE_IP! -LD "PUT \"%%F\" \"!TNC_ZIEL!\%%F\""

    if errorlevel 1 (
        echo   [FEHLER] Uebertragung fehlgeschlagen: %%F
        set /a ERR_COUNT+=1
    ) else (
        echo   [OK]
        set /a OK_COUNT+=1
    )
    %_DEBUG%
)

del "%TMPLIST%" >nul 2>&1

echo.
echo ============================================================
if !ERR_COUNT!==0 (
    echo   Fertig: Alle !OK_COUNT! Datei^(en^) erfolgreich uebertragen.
) else (
    echo   Fertig: !OK_COUNT! OK  /  !ERR_COUNT! FEHLER
    echo   Bitte die oben markierten Eintraege pruefen.
)
echo ============================================================
goto :end

:: ============================================================
::  Fehler- und Abbruch-Ziele
:: ============================================================
:err_noarg
echo.
echo [FEHLER] Keine Datei oder Ordner uebergeben.
goto :end

:err_basis
echo.
echo [FEHLER] Es koennen zur Zeit nur Wersoma-Teile uebertragen werden.
echo          Erlaubter Basispfad: %WERSOMA_BASIS%
echo          Ihr Pfad:            %QUELLE%
goto :end

:err_ext
echo.
echo [FEHLER] Nicht erlaubte Dateiendung festgestellt.
echo          Erlaubt: .h .bmp .png .jpg .jpeg .stl
goto :end

:err_pushd
echo.
echo [FEHLER] Konnte Quellordner nicht oeffnen.
echo          Quelle: %QUELLE%
goto :end

:err_nofiles
echo.
echo [FEHLER] Keine uebertragbaren Dateien gefunden.
echo          Erlaubt: .h .bmp .png .jpg .jpeg .stl
goto :end

:cancelled
echo.
echo [ABBRUCH] Keine Datei wurde veraendert.
del "%TMPLIST%" >nul 2>&1
goto :end

:: ============================================================
::  Ende
:: ============================================================
:end
echo.
popd >nul 2>&1
popd >nul 2>&1
timeout /t 10
endlocal
goto :EOF

:: ============================================================
::  Subroutine: String in Grossbuchstaben umwandeln
:: ============================================================
:UC
set "_UC=!%1!"
set "_UC=!_UC:a=A!" & set "_UC=!_UC:b=B!" & set "_UC=!_UC:c=C!"
set "_UC=!_UC:d=D!" & set "_UC=!_UC:e=E!" & set "_UC=!_UC:f=F!"
set "_UC=!_UC:g=G!" & set "_UC=!_UC:h=H!" & set "_UC=!_UC:i=I!"
set "_UC=!_UC:j=J!" & set "_UC=!_UC:k=K!" & set "_UC=!_UC:l=L!"
set "_UC=!_UC:m=M!" & set "_UC=!_UC:n=N!" & set "_UC=!_UC:o=O!"
set "_UC=!_UC:p=P!" & set "_UC=!_UC:q=Q!" & set "_UC=!_UC:r=R!"
set "_UC=!_UC:s=S!" & set "_UC=!_UC:t=T!" & set "_UC=!_UC:u=U!"
set "_UC=!_UC:v=V!" & set "_UC=!_UC:w=W!" & set "_UC=!_UC:x=X!"
set "_UC=!_UC:y=Y!" & set "_UC=!_UC:z=Z!"
set "%1=!_UC!"
goto :EOF
