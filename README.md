# Wersoma Code‑Pool — Sammlung nützlicher Skripte & kleine Tools

Kurze Sammlung von kleinen Tools, Skripten und Hilfsprogrammen für Windows‑ und Fertigungs‑Workflows. Enthält PowerShell-, Batch‑ und AutoHotkey‑Skripte, Python‑Skripte für Kamera/Video‑Hilfen sowie mehrere kleine C#/C++ Projekte (Launcher, QR‑Scanner, WebView‑Bildschirmschoner).

## Stack
- **Language(s):** PowerShell, Batch (.bat), AutoHotkey (AHK), Python, C#, C++
- **Framework / runtime:** .NET (C# Projekte), native Windows‑Tools, Python 3

## Top‑Level Übersicht
```
.gitattributes            Git attributes
.gitignore               Dateien/Patterns, die ausgeschlossen sind
.reg Dateien/            Registry‑Export(e) / .reg Dateien
AHK/                     AutoHotkey‑Skripte (NX/Creo Helfer, Hotkeys)
Batch/                   Batch‑Skripte (.bat) für Maschinen/Windows‑Tasks
Creo_CSV2XLSX/           Python‑Tool: Creo CSV → strukturierte XLSX‑Arbeitsmappe
PowerShell/              Sammlung umfangreicher PowerShell‑Skripte (Projekthelfer etc.)
Python/                  Python‑Skripte — Kamera/Video‑Demos und Diagnostics
PythonLauncher/          Kleines C++‑Launcher‑Programm + build.bat
QrWedge/                 C# Projekt: Kamera/QR‑Scanner → Text/Key‑Wedge
STEP_Import/             Tools zum Erstellen von CAM‑Projektpfaden & PRT‑Konvertierung
WebViewScreenSaver/      .NET WebView2 Bildschirmschoner (ausführliche README im Ordner)
README.md                Diese Datei
```

## Kurzbeschreibung der Ordner / Dateien
- AHK/
  - AutoHotkey Skripte für Desktop‑Automatisierung und CAD/CAM‑Helfer.
  - Wichtig: `NX-Helper.ahk` erzeugt ein Custom‑Menü in einem Fenster und berechnet Drehzahlen und Vorschübe für Senkoperationen abhängig vom effektiven Bearbeitungsdurchmesser des Werkzeugs.
  - Weitere Skripte: `ABPS Daten ziehen.ahk` (Datenexport), `CapsNumAlwaysOff.ahk` (kleines Utility) u. v. m.

- Batch/
  - Windows .bat Hilfsskripte, z. B. `Maschine DMU95.bat`, `Maschine_Uebertragen.bat` (Maschinen/Übertragung), `Signieren.bat`.

- Creo_CSV2XLSX/
  - Python‑Skript `Creo_CSV2XLSX.py`: Konvertiert eine hierarchische Creo‑Stückliste (CSV) in eine strukturierte Excel‑Arbeitsmappe mit folgenden Blättern/Regeln:
    - Erstellt/aktualisiert GFU‑Liste und Schlosserliste und hängt einen neuen Stand‑Sheet an.
    - Schweißteil‑Erkennung (strukturell durch Prüfung der Kinder‑Teile) mit interaktivem Modus.
  - Aufruf (im Ordner mit der CSV):
    ```bash
    python Creo_CSV2XLSX.py "C:\Pfad\zum\Ordner" [--batch]
    ```
    - `--batch` setzt nicht‑interaktiven Modus (Schweißteil‑Kandidaten werden automatisch bestätigt).
    - Achtung: das Skript erwartet genau eine CSV im Ordner; vorhandene XLSX zum gleichen Stamm werden fortgeführt/aktualisiert.
  - Abhängigkeit: `openpyxl` wird benötigt (das Skript enthält einen Lazy‑Import und einen Zip‑Fallback).

- PowerShell/
  - Größere PowerShell‑Skripte und „Projekthelfer“ (`Projekthelfer_AV.ps1`, `Projekthelfer_Konstruktion.ps1` etc.).
  - Utilities: `extract_icon.ps1`, `pdf2text_poppler.ps1`.

- Python/
  - Kamera/Video Hilfsprogramme: `show_webcam_cli.py`, `webcam_diagnostic_short.py`, `check_and_save_frames.py`, `try_yuy2_opencv.py`.
  - `Creo_CSV2XLSX_test.py` scheint Tests/Beispiele für das Creo‑Tool zu enthalten.

- PythonLauncher/
  - Kleines C++‑Projekt mit `PythonLauncher.cpp`, `build.bat`, Ressourcen (.rc, Icon). `build.bat` enthält den Build‑Ablauf — benötigt passende Windows‑Compiler/Toolchain.

- QrWedge/
  - C#‑Projekt (Projektdatei `QrWedge.csproj`) mit Klassen: `UsbCamera.cs`, `CameraService.cs`, `MainForm.cs`, `KeyboardHook.cs`.
  - Funktion: liest Kamerabilder, erkennt vermutlich QR‑Codes und gibt Inhalte als Tastatureingabe (Wedge) aus. `publish.ps1` hilft beim Veröffentlichen.

- STEP_Import/
  - Zweck: Aus STEP‑Dateien automatisch den CAM‑Projektpfad erzeugen und die STEP direkt in eine PRT konvertieren (Nutzbarkeit in NX).
  - Enthalten: `STEP_Import.bat` (Aufruf/Workflow, setzt gawk und step214ug.exe voraus), `STEP_Import.awk` (parst STEP/Converter‑Output und extrahiert Benennung/schema‑Check) und `STEP_Import_ContextMenu.reg` (Context‑Menu Registration für "Senden an").
  - Ablauf (Kurz): Rechtsklick → Senden an → `STEP_Import.bat` ruft gawk für Parsing auf, prüft STEP AP214‑Schema, legt im CAM‑Verzeichnis einen Zielordner an, konvertiert mittels `step214ug.exe` nach PRT und öffnet die PRT in NX, falls NX läuft.

- WebViewScreenSaver/
  - Komplettes .NET‑Projekt, das mittels WebView2 eine konfigurierbare Webseite als Windows‑Bildschirmschoner anzeigt.
  - Build (im Projektordner):
    ```bash
    dotnet publish -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true
    ```
  - Ergebnis: `bin\Release\net8.0-windows\win-x64\publish\WebViewScreensaver.exe`
  - Installation: `.exe` in `.scr` umbenennen und nach `C:\Windows\System32` kopieren oder per Rechtsklick → Installieren. Einstellungen in Registry: `HKCU\Software\WebViewScreensaver`.

## Wie die Teile zusammenpassen
Dies ist eine persönliche Sammlung unabhängiger Tools, die sich thematisch auf Windows‑Automatisierung, Fertigungs‑/Konstruktions‑Workflows (Creo, NX, STEP, CAM) und kamerabasierte Hilfsmittel fokussiert. Die Ordner sind größtenteils eigenständige Werkzeuge; gemeinsame Schnittmenge sind Arbeitsabläufe rund um Fertigungsdaten und deren Automatisierung.

## Build / Ausführungs‑Kurzanleitungen
- WebViewScreenSaver
  - Siehe oben. Erfordert .NET 8 SDK und WebView2 Runtime.

- QrWedge (C#)
  - Projekt mit `QrWedge.csproj` — mit Visual Studio öffnen und bauen oder `dotnet build` prüfen (abhängig von Ziel‑Framework). `publish.ps1` automatisiert das Veröffentlichen.

- Python‑Skripte
  - Standard: `python3 <script>.py` (je nach Skript evtl. OpenCV/NumPy nötig — in diesem README sind keine zusätzlichen requirements aufgeführt).

- Creo_CSV2XLSX
  - Siehe oben: `python Creo_CSV2XLSX.py "C:\Pfad\zum\Ordner" [--batch]`.
  - Das Skript entfernt die Eingangs‑CSV am Ende (wenn erfolgreich) und legt/aktualisiert eine XLSX‑Datei mit GFU‑ und Schlosserlisten an.

- STEP_Import
  - Wird via Kontextmenü / Senden an aufgerufen; benötigt `gawk.exe`, `step214ug.exe` (NX‑Konverter) sowie passende Umgebungsvariablen/Paths für NX.

## Änderungen in dieser README
- Repo gescannt und Top‑Level‑Einträge beschrieben.
- STEP_Import, NX‑Helper und Creo_CSV2XLSX wurden mit den von dir gelieferten Details ergänzt.

---
Wenn du möchtest, passe ich die README noch an (z. B. ausführliche Build‑Schritte für QrWedge, genaue .NET‑Target‑Version, oder requirements.txt für Python‑Skripte). Ansonsten habe ich die Datei jetzt direkt in den Default‑Branch aktualisiert.
