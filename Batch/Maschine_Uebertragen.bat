@echo off & setlocal
:Name für die Verknüpfung generieren: die Bezugsdatei finden, ihre Dateierweiterung filtern und nur ihren Namen in der  Variable setzen.
for /f "delims=" %%d in ('dir  /b ^| findstr /C:"%File%"') do set LinkName=%%~nd   

echo %LinkName%

pause

goto :EOF


@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  WERSOMA GmbH - CNC Dateiuebertragung via TNCcmd
:: ============================================================
::  EINRICHTUNG (einmalig):
::  1. Diese .bat Datei in einen festen Ordner legen,
::     z.B. C:\Tools\Wersoma\
::  2. Im SendTo-Ordner (%APPDATA%\Microsoft\Windows\SendTo)
::     fuer jede Maschine eine Verknuepfung auf diese .bat anlegen.
::  3. Den Namen der Verknuepfung MUSS so aufgebaut sein:
::       "Maschine DMU50"
::       "Maschine DMU60"
::       "Maschine DMU95"
::       "Maschine DMU100"
::       "Maschine REIDEN"
::       "Maschine IXION"
::     Das letzte Wort im Verknuepfungsnamen bestimmt die Maschine.
:: ============================================================

:: --- Pfad zur TNCcmd.exe ---
set "TNCCMD=N:\Sicherung_Maschinen\BACKUP_TOOLS\tnccmd.exe"

:: --- Wersoma Basispfad (Quellpfad muss damit beginnen) ---
set "WERSOMA_BASIS=N:\00_Fertigungsdaten\Wersoma"

:: ============================================================
::  Maschinenkennung aus dem eigenen Dateinamen lesen
::  Erwartet: letztes Wort im Dateinamen = Maschinenkennung
::  Beispiel: "Maschine DMU60" -> MK = DMU60
:: ============================================================
set "SELF=%~n0"
set "MK="
for %%W in (%SELF%) do set "MK=%%W"

:: IP je Maschine
set "IP_DMU50=10.4.2.73"
set "IP_DMU60=10.4.2.71"
set "IP_DMU95=10.4.2.83"
set "IP_DMU100=10.4.2.70"
set "IP_REIDEN=10.4.2.72"
set "IP_IXION=10.4.2.74"

set "MACHINE_IP="
set "MACHINE_LABEL="
if /i "%MK%"=="DMU50"  ( set "MACHINE_IP=%IP_DMU50%"  & set "MACHINE_LABEL=DMU50"  )
if /i "%MK%"=="DMU60"  ( set "MACHINE_IP=%IP_DMU60%"  & set "MACHINE_LABEL=DMU60"  )
if /i "%MK%"=="DMU95"  ( set "MACHINE_IP=%IP_DMU95%"  & set "MACHINE_LABEL=DMU95"  )
if /i "%MK%"=="DMU100" ( set "MACHINE_IP=%IP_DMU100%" & set "MACHINE_LABEL=DMU100" )
if /i "%MK%"=="REIDEN" ( set "MACHINE_IP=%IP_REIDEN%" & set "MACHINE_LABEL=REIDEN" )
if /i "%MK%"=="IXION"  ( set "MACHINE_IP=%IP_IXION%"  & set "MACHINE_LABEL=IXION"  )

if "%MACHINE_IP%"=="" (
    msg * "Unbekannte Maschine: [%MK%]^
^
Bitte den Namen der SendTo-Verknuepfung pruefen.^
Erlaubt: Maschine DMU50 / DMU60 / DMU95 / DMU100 / REIDEN / IXION"
    goto :EOF
)

:: ============================================================
::  Eingabe pruefen
:: ============================================================
set "QUELLE=%~1"
if "%QUELLE%"=="" (
    msg * "Keine Datei oder Ordner uebergeben. Bitte per 'Senden an' verwenden."
    goto :EOF
)

:: Pruefen ob Quellpfad mit Wersoma-Basis beginnt
set "BLEN=0"
set "_TMP=%WERSOMA_BASIS%"
:LEN_LOOP
if "!_TMP!"=="" goto LEN_DONE
set "_TMP=!_TMP:~1!"
set /a BLEN+=1
goto LEN_LOOP
:LEN_DONE

set "Q_START=!QUELLE:~0,%BLEN%!"
if /i not "%Q_START%"=="%WERSOMA_BASIS%" (
    msg * "Fehler: Es koennen zur Zeit nur Wersoma-Teile uebertragen werden.^
^
Erlaubter Basispfad: %WERSOMA_BASIS%^
^
Ihr Pfad: %QUELLE%"
    goto :EOF
)

:: ============================================================
::  Pfad-Zerlegung
::  Aufbau nach dem Basis-Prefix:
::  \Archiv_38\02050-02099\02051\[01\]CAM\Teil-01 (Grundplatte)\DMU 95[\Datei.h]
:: ============================================================
set /a BLEN_P=BLEN+1
set "REST=!QUELLE:~%BLEN_P%!"

set "T1=" & set "T2=" & set "T3=" & set "T4=" & set "T5="
set "T6=" & set "T7=" & set "T8=" & set "T9="
set "_IDX=0"
set "_R=%REST%"
:SPLIT_LOOP
if "!_R!"=="" goto SPLIT_DONE
for /f "tokens=1* delims=\" %%A in ("!_R!") do (
    set /a _IDX+=1
    set "T!_IDX!=%%A"
    set "_R=%%B"
)
goto SPLIT_LOOP
:SPLIT_DONE

:: Archiv-Nummer extrahieren (Archiv_38 -> 38)
set "ARCHIV_NR="
for /f "tokens=2 delims=_" %%A in ("%T1%") do set "ARCHIV_NR=%%A"
if "%ARCHIV_NR%"=="" set "ARCHIV_NR=%T1%"

set "BEREICH=%T2%"
set "AUFTRAG=%T3%"

:: Optionaler 2-stelliger Ordner pruefen
set "OPTORD="
echo %T4%| findstr /r /c:"^$" >nul 2>&1
if not errorlevel 1 set "OPTORD=%T4%"

:: Ordner oder Einzeldatei?
if exist "%QUELLE%\" (
    set "IS_FOLDER=1"
    if defined OPTORD ( set "TEIL_RAW=!T6!" ) else ( set "TEIL_RAW=!T5!" )
) else (
    set "IS_FOLDER=0"
    if defined OPTORD ( set "TEIL_RAW=!T6!" ) else ( set "TEIL_RAW=!T5!" )
)

:: Teil-Namen kuerzen (bis erstes Leerzeichen)
for /f "tokens=1" %%A in ("%TEIL_RAW%") do set "TEIL_KURZ=%%A"

:: Grossbuchstaben-Konvertierung
call :UC TEIL_KURZ
call :UC AUFTRAG
call :UC BEREICH
call :UC ARCHIV_NR
if defined OPTORD call :UC OPTORD

if defined OPTORD ( set "OPT=\%OPTORD%" ) else ( set "OPT=" )

:: ============================================================
::  TNC-Zielpfad je Maschine zusammenbauen
:: ============================================================
set "AM=ARCHIV-%ARCHIV_NR%"
set "AO=ARCHIV%ARCHIV_NR%"

if /i "%MACHINE_LABEL%"=="DMU50"  set "TNC_ZIEL=TNC:\PROGRAMME\WERSOMA\%AM%\%AUFTRAG%%OPT%\%TEIL_KURZ%"
if /i "%MACHINE_LABEL%"=="DMU60"  set "TNC_ZIEL=TNC:\WERSOMA\%AM%\%AUFTRAG%%OPT%\%TEIL_KURZ%"
if /i "%MACHINE_LABEL%"=="DMU95"  set "TNC_ZIEL=TNC:\PROGRAMME\WERSOMA\%ARCHIV_NR%\%BEREICH%\%AUFTRAG%%OPT%\%TEIL_KURZ%"
if /i "%MACHINE_LABEL%"=="DMU100" set "TNC_ZIEL=TNC:\WERSOMA\%AM%\%AUFTRAG%%OPT%\%TEIL_KURZ%"
if /i "%MACHINE_LABEL%"=="REIDEN" set "TNC_ZIEL=TNC:\WERSOMA\%AM%\%BEREICH%\%AUFTRAG%%OPT%\%TEIL_KURZ%"
if /i "%MACHINE_LABEL%"=="IXION"  set "TNC_ZIEL=TNC:\WERSOMA\%AO%\%AUFTRAG%%OPT%\%TEIL_KURZ%"

:: ============================================================
::  Dateiliste aufbauen (alle zu uebertragenden Dateien)
:: ============================================================
set "TMPLIST=%TEMP%\wersoma_filelist_%RANDOM%.tmp"
if exist "%TMPLIST%" del "%TMPLIST%"

if "%IS_FOLDER%"=="1" (
    for /r "%QUELLE%" %%F in (*.h *.H *.bmp *.BMP *.png *.PNG *.jpg *.JPG *.jpeg *.JPEG) do (
        echo %%F>> "%TMPLIST%"
    )
) else (
    set "_EXT=%~x1"
    call :UC _EXT
    if "!_EXT!"==".H"     echo %QUELLE%>> "%TMPLIST%"
    if "!_EXT!"==".BMP"   echo %QUELLE%>> "%TMPLIST%"
    if "!_EXT!"==".PNG"   echo %QUELLE%>> "%TMPLIST%"
    if "!_EXT!"==".JPG"   echo %QUELLE%>> "%TMPLIST%"
    if "!_EXT!"==".JPEG"  echo %QUELLE%>> "%TMPLIST%"
)

if not exist "%TMPLIST%" (
    msg * "Keine uebertragbaren Dateien gefunden.^
Erlaubte Formate: .h .bmp .png .jpg .jpeg"
    goto :EOF
)

:: Dateien zaehlen
set "FILE_COUNT=0"
for /f "usebackq" %%L in ("%TMPLIST%") do set /a FILE_COUNT+=1

:: ============================================================
::  Info-Anzeige vor der Uebertragung
:: ============================================================
cls
echo.
echo  ============================================================
echo   WERSOMA - Dateiuebertragung zur CNC-Maschine
echo  ============================================================
echo.
echo   Maschine  : %MACHINE_LABEL%   (%MACHINE_IP%)
echo   Quelle    : %QUELLE%
echo   Ziel TNC  : %TNC_ZIEL%
echo   Dateien   : %FILE_COUNT% Datei(en) gefunden
echo.
echo  ============================================================
echo.

:: ============================================================
::  Vorab-Pruefung: Existieren Dateien bereits auf der TNC?
:: ============================================================
echo  Pruefe ob Dateien bereits auf der Maschine vorhanden sind...
echo.

set "EXIST_LIST="
set "EXIST_COUNT=0"

for /f "usebackq delims=" %%F in ("%TMPLIST%") do (
    set "_NAME=%%~nxF"
    set "_TNC_FILE=%TNC_ZIEL%\%%~nxF"

    :: FILEINFO gibt Exit-Code 0 wenn Datei existiert, 1 wenn nicht
    "%TNCCMD%" -i%MACHINE_IP% -LD "FILEINFO !_TNC_FILE!" >nul 2>&1
    if not errorlevel 1 (
        set /a EXIST_COUNT+=1
        echo   [!] Bereits vorhanden: !_NAME!
        set "EXIST_LIST=!EXIST_LIST! !_NAME!"
    ) else (
        echo   [_] Neu:               !_NAME!
    )
)

echo.

:: ============================================================
::  Rueckfrage wenn Dateien bereits existieren
:: ============================================================
if %EXIST_COUNT% GTR 0 (
    echo  ============================================================
    echo   ACHTUNG: %EXIST_COUNT% Datei(en) existieren bereits auf %MACHINE_LABEL%!
    echo  ============================================================
    echo.
    echo   Diese Dateien werden ueberschrieben:
    for %%X in (%EXIST_LIST%) do echo     - %%X
    echo.
    choice /c JN /m "Trotzdem ueberschreiben? [J=Ja, alle uebertragen / N=Abbrechen] "
    if errorlevel 2 (
        echo.
        echo  Uebertragung abgebrochen. Keine Datei wurde veraendert.
        del "%TMPLIST%" >nul 2>&1
        timeout /t 3 >nul
        goto :EOF
    )
) else (
    echo  Alle Dateien sind neu - keine Konflikte gefunden.
    echo.
    choice /c JN /m "Uebertragung starten? [J=Ja / N=Abbrechen] "
    if errorlevel 2 (
        echo.
        echo  Abgebrochen.
        del "%TMPLIST%" >nul 2>&1
        timeout /t 2 >nul
        goto :EOF
    )
)

:: ============================================================
::  Zielordner anlegen und Dateien uebertragen
:: ============================================================
echo.
echo  Erstelle Zielordner auf TNC (falls nicht vorhanden)...
"%TNCCMD%" -i%MACHINE_IP% -LD "MKDIR %TNC_ZIEL%"

echo.
echo  Starte Uebertragung...
echo.

set "OK_COUNT=0"
set "ERR_COUNT=0"

for /f "usebackq delims=" %%F in ("%TMPLIST%") do (
    set "_NAME=%%~nxF"
    echo   Sende: !_NAME!
    "%TNCCMD%" -i%MACHINE_IP% -LD "PUT ""%%F"" %TNC_ZIEL%\!_NAME!"
    if errorlevel 1 (
        echo   [FEHLER] Konnte nicht gesendet werden: !_NAME!
        set /a ERR_COUNT+=1
    ) else (
        echo   [OK]
        set /a OK_COUNT+=1
    )
)

del "%TMPLIST%" >nul 2>&1

echo.
echo  ============================================================
echo   Ergebnis: %OK_COUNT% Datei(en) erfolgreich,  %ERR_COUNT% Fehler
echo  ============================================================
echo.
pause
goto :EOF

:: ============================================================
::  Subroutine: String in Grossbuchstaben umwandeln
::  Aufruf: call :UC VariablenName   (ohne %-Zeichen)
:: ============================================================
:UC
set "_UC_IN=!%1!"
set "_UC_IN=!_UC_IN:a=A!"
set "_UC_IN=!_UC_IN:b=B!"
set "_UC_IN=!_UC_IN:c=C!"
set "_UC_IN=!_UC_IN:d=D!"
set "_UC_IN=!_UC_IN:e=E!"
set "_UC_IN=!_UC_IN:f=F!"
set "_UC_IN=!_UC_IN:g=G!"
set "_UC_IN=!_UC_IN:h=H!"
set "_UC_IN=!_UC_IN:i=I!"
set "_UC_IN=!_UC_IN:j=J!"
set "_UC_IN=!_UC_IN:k=K!"
set "_UC_IN=!_UC_IN:l=L!"
set "_UC_IN=!_UC_IN:m=M!"
set "_UC_IN=!_UC_IN:n=N!"
set "_UC_IN=!_UC_IN:o=O!"
set "_UC_IN=!_UC_IN:p=P!"
set "_UC_IN=!_UC_IN:q=Q!"
set "_UC_IN=!_UC_IN:r=R!"
set "_UC_IN=!_UC_IN:s=S!"
set "_UC_IN=!_UC_IN:t=T!"
set "_UC_IN=!_UC_IN:u=U!"
set "_UC_IN=!_UC_IN:v=V!"
set "_UC_IN=!_UC_IN:w=W!"
set "_UC_IN=!_UC_IN:x=X!"
set "_UC_IN=!_UC_IN:y=Y!"
set "_UC_IN=!_UC_IN:z=Z!"
set "%1=!_UC_IN!"
goto :EOF
