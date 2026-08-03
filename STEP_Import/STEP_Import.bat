@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Arbeitsverzeichnis robust setzen - faengt UNC-Pfade ab
pushd "%~dp0" >nul 2>&1

:: ============================================================
:: STEP_Import.bat
:: Liegt in shell:sendto - wird per Rechtsklick > Senden an aufgerufen
:: %1 = Pfad der STEP-Datei
:: Benoetigt gawk.exe und STEP_Import.awk (gleicher Ordner wie diese .bat)
:: ============================================================

set "GAWK=N:\Sicherung_Maschinen\BACKUP_TOOLS\gawk.exe"
set "AWK_SCRIPT=%~dp0STEP_Import.awk"

set "BASE_WERSOMA=N:\00_Fertigungsdaten\Wersoma"
set "BASE_KUNDEN=N:\00_Fertigungsdaten\Kunden"

:: WENN _DEBUG=pause haelt das Skript nach jedem Schritt an
:: set _DEBUG=pause

set "STEP_PATH=%~1"

:: ANSI-Farben (ESC-Zeichen per cmd-Trick erzeugen)
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "YEL=%ESC%[93m"
set "GRN=%ESC%[92m"
set "CYN=%ESC%[96m"
set "WHT=%ESC%[97m"
set "RST=%ESC%[0m"

echo %CYN%============================================================%RST%
echo %CYN%  STEP Import%RST%
echo %CYN%============================================================%RST%

if "%STEP_PATH%"=="" (
    echo %RED%[FEHLER] Keine Datei uebergeben.%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 1. Dateiendung pruefen ---%RST%
set "EXT=%~x1"
if /I not "%EXT%"==".stp" if /I not "%EXT%"==".step" (
    echo %RED%[FEHLER] Keine STEP-Datei (.stp/.step^): %STEP_PATH%%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 2. Existenz pruefen ---%RST%
if not exist "%STEP_PATH%" (
    echo %RED%[FEHLER] Datei nicht gefunden: %STEP_PATH%%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 3. Letzter Ordner muss CAD sein ---%RST%
for %%F in ("%STEP_PATH%") do set "PARENT_DIR=%%~dpF"
set "PARENT_DIR=%PARENT_DIR:~0,-1%"
for %%D in ("%PARENT_DIR%") do set "PARENT_NAME=%%~nxD"

if /I not "%PARENT_NAME%"=="CAD" (
    echo %RED%[FEHLER] Datei liegt nicht im Ordner 'CAD': %PARENT_NAME%%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 4. Wersoma oder Kunden? ---%RST%
set "BEREICH="
echo %STEP_PATH% | findstr /I /C:"%BASE_WERSOMA%" >nul
if %ERRORLEVEL%==0 set "BEREICH=WERSOMA"

echo %STEP_PATH% | findstr /I /C:"%BASE_KUNDEN%" >nul
if %ERRORLEVEL%==0 set "BEREICH=KUNDEN"

if not defined BEREICH (
    echo %RED%[FEHLER] Datei liegt weder unter Wersoma noch unter Kunden.%RST%
    goto :end
)

if "%BEREICH%"=="KUNDEN" (
    echo %YEL%[HINWEIS] Kunden-Dateien werden noch nicht unterstuetzt.%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 5. STEP parsen (Schema-Check + Benennung) ---%RST%
if not exist "%GAWK%" (
    echo %RED%[FEHLER] gawk.exe nicht gefunden: %GAWK%%RST%
    goto :end
)
if not exist "%AWK_SCRIPT%" (
    echo %RED%[FEHLER] STEP_Import.awk nicht gefunden: %AWK_SCRIPT%%RST%
    goto :end
)

echo %WHT%[INFO  ] Lese STEP-Datei: %STEP_PATH%%RST%

set "TMP_OUT=%TEMP%\step_import_%RANDOM%.tmp"

"%GAWK%" -f "%AWK_SCRIPT%" "%STEP_PATH%" > "%TMP_OUT%" 2>&1
set "GAWK_RC=%ERRORLEVEL%"

if not "%GAWK_RC%"=="0" (
    echo %RED%[FEHLER] gawk Fehler (Code %GAWK_RC%^). Siehe: %TMP_OUT%%RST%
    goto :end
)

for /f "usebackq tokens=1,* delims==" %%A in ("%TMP_OUT%") do set "%%A=%%B"
del "%TMP_OUT%" >nul 2>&1

if not "%SCHEMA_OK%"=="1" (
    echo %RED%[FEHLER] Nur STEP AP214-Dateien werden unterstuetzt.%RST%
    goto :end
)

if "%BENENNUNG%"=="" (
    echo %RED%[FEHLER] BENENNUNG konnte nicht ausgelesen werden.%RST%
    goto :end
)

echo %GRN%[OK    ] STEP AP214 erkannt. Benennung: %BENENNUNG%%RST%
%_DEBUG%

::echo %CYN%--- 6. CAM-Ordner neben CAD muss existieren ---%RST%
for %%G in ("%PARENT_DIR%") do set "GRANDPARENT=%%~dpG"
set "GRANDPARENT=%GRANDPARENT:~0,-1%"
set "CAM_DIR=%GRANDPARENT%\CAM"

if not exist "%CAM_DIR%\" (
    echo %RED%[FEHLER] Kein CAM-Ordner gefunden: %CAM_DIR%%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 7. Zielordnername bilden ---%RST%
for %%N in ("%STEP_PATH%") do set "BASENAME=%%~nN"

:: Letzten Teil nach dem letzten Unterstrich extrahieren und grossschreiben per PowerShell
:: BASENAME als Umgebungsvariable uebergeben - sicher gegen Sonderzeichen
for /f "delims=" %%U in ('powershell -NoProfile -Command "[System.Environment]::GetEnvironmentVariable(\"BASENAME\").Split(\"_\")[-1].ToUpper()"') do set "LAST_PART=%%U"

set "TARGET_NAME=Teil %LAST_PART% (%BENENNUNG%)"
set "TARGET_PATH=%CAM_DIR%\%TARGET_NAME%"

if exist "%TARGET_PATH%\" (
    echo !YEL![INFO  ] Zielordner existiert bereits: !TARGET_NAME!!RST!
) else (
    mkdir "%TARGET_PATH%"
    if exist "%TARGET_PATH%\" (
        echo !GRN![OK    ] Zielordner angelegt: !TARGET_NAME!!RST!
    ) else (
        echo !RED![FEHLER] Zielordner konnte nicht angelegt werden.!RST!
        goto :end
    )
)
%_DEBUG%

::echo %CYN%--- 8. Rechnername pruefen ---%RST%
if /I "%COMPUTERNAME%"=="WRSM60" (
    echo %YEL%[INFO  ] Konvertierung auf WRSM60 deaktiviert.%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 9. NX-Umgebung bereitstellen ---%RST%
set "PATH=%PATH%;%UGII_BASE_DIR%\NXBIN;%UGII_BASE_DIR%\UGII"

set SPLM_LICENSE_SERVER=CLOUD
if /i "%COMPUTERNAME%"=="wrsm57" set SPLM_LICENSE_SERVER=29000@fileserver
if /i "%COMPUTERNAME%"=="wrsm57" set UGS_LICENSE_BUNDLE=NX10101;NX11460
if /i "%COMPUTERNAME%"=="wrsm60" set SPLM_LICENSE_SERVER=29000@fileserver
if /i "%COMPUTERNAME%"=="wrsm60" set UGS_LICENSE_BUNDLE=NX10101;NX11460
%_DEBUG%

set "STEP214UG=C:\Siemens\NX2412\STEP214UG\step214ug.exe"
set "STEP214UG_DEF=C:\Siemens\NX2412\STEP214UG\step214ug.def"
set "OUT_PRT=%PARENT_DIR%\%BASENAME%.prt"

if not exist "%STEP214UG%" (
    echo %RED%[FEHLER] step214ug.exe nicht gefunden: %STEP214UG%%RST%
    goto :end
)
if not exist "%STEP214UG_DEF%" (
    echo %RED%[FEHLER] step214ug.def nicht gefunden: %STEP214UG_DEF%%RST%
    goto :end
)
%_DEBUG%

::echo %CYN%--- 10. Konvertierung (Output direkt durch gawk filtern) ---%RST%
echo %WHT%[INFO  ] Starte STEP-Konvertierung...%RST%
echo %CYN%-------------------------------------------------------------%RST%

set "CONV_RC_FILE=%TEMP%\step214_rc_%RANDOM%.tmp"

(
    "%STEP214UG%" "%STEP_PATH%" "o=%OUT_PRT%" "d=%STEP214UG_DEF%"
    echo !ERRORLEVEL!>"%CONV_RC_FILE%"
) 2>&1 | "%GAWK%" -v filter_mode=1 -f "%AWK_SCRIPT%"

echo %CYN%-------------------------------------------------------------%RST%
set /p CONV_RC=<"%CONV_RC_FILE%"
del "%CONV_RC_FILE%" >nul 2>&1
set "CONV_RC=%CONV_RC: =%"

if %CONV_RC% NEQ 0 (
    echo %RED%[FEHLER] Konvertierung fehlgeschlagen (Code %CONV_RC%^).%RST%
    goto :end
)

if not exist "%OUT_PRT%" (
    echo %RED%[FEHLER] PRT-Datei wurde nicht erzeugt: %OUT_PRT%%RST%
    goto :end
)

echo %GRN%[OK    ] PRT erstellt: %OUT_PRT%%RST%
%_DEBUG%

::echo %CYN%--- 11. ugraf.exe pruefen und PRT in NX oeffnen ---%RST%
tasklist /FI "IMAGENAME eq ugraf.exe" 2>nul | findstr /I "ugraf.exe" >nul
if %ERRORLEVEL%==0 (
    echo %GRN%[OK    ] NX laeuft - Datei wird geoeffnet...%RST%
    start "" "%OUT_PRT%"
) else (
    echo %YEL%[INFO  ] NX nicht aktiv - Datei liegt bereit: %OUT_PRT%%RST%
)
%_DEBUG%

goto :end

:end
echo %CYN%============================================================%RST%
timeout /t 10
popd >nul 2>&1
endlocal
