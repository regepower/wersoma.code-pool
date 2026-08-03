# WebView Bildschirmschoner

Ein Windows-Bildschirmschoner, der einfach eine konfigurierbare Webseite via WebView2 anzeigt.

## Voraussetzungen

- .NET 8 SDK: https://dotnet.microsoft.com/download
- WebView2 Runtime (auf aktuellen Windows 10/11-Systemen normalerweise bereits vorinstalliert;
  falls nicht: https://developer.microsoft.com/microsoft-edge/webview2/)

## Build

Im Projektordner (dort, wo `WebViewScreensaver.csproj` liegt):

```
dotnet publish -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true
```

Die fertige Datei liegt danach unter:
```
bin\Release\net8.0-windows\win-x64\publish\WebViewScreensaver.exe
```

## Als Bildschirmschoner installieren

1. `WebViewScreensaver.exe` in `WebViewScreensaver.scr` umbenennen.
2. Die `.scr`-Datei nach `C:\Windows\System32` kopieren (Administratorrechte erforderlich),
   ODER einfach per Rechtsklick auf die `.scr`-Datei → **„Installieren“** wählen
   (Windows übernimmt das Kopieren automatisch).
3. Windows-Einstellungen → Personalisierung → Sperrbildschirm → Bildschirmschoner-Einstellungen
   → **WebViewScreensaver** auswählen.
4. Über den Button **„Einstellungen“** dort lässt sich die URL konfigurieren
   (landet in der Registry unter `HKCU\Software\WebViewScreensaver`).

## Funktionsweise / Parameter

Windows startet Bildschirmschoner-.scr-Dateien mit bestimmten Kommandozeilenparametern:

- kein Parameter oder `/c` → Konfigurationsdialog (`ConfigForm`)
- `/s` → Vollbild-Anzeige starten (`ScreensaverApplicationContext`, ein Fenster pro Monitor)
- `/p:<hwnd>` → Miniaturvorschau in den Windows-Einstellungen (hier bewusst leer gelassen)

Der Screensaver beendet sich automatisch bei Mausbewegung, Mausklick oder Tastendruck.

## Lokale Dateien / Netzlaufwerke

Im Feld „Webseite / Datei“ kann sowohl eine `http(s)://`-URL als auch ein lokaler
oder UNC-Pfad eingetragen werden, z.B.:

```
\\File01\Fertigung\05_Präsentationen_TV\InfoViewer\index.html
```

Die Umwandlung in eine korrekt kodierte URI (inkl. Umlaute etc.) übernimmt
`UrlHelper.cs` automatisch – manuelles Prozent-Encoding ist nicht nötig.

**Wichtig:** Gemappte Laufwerksbuchstaben (`N:\...`) sind in manchen
Sitzungskontexten (z.B. wenn der Bildschirmschoner über den Sperrbildschirm
ausgelöst wird) nicht verfügbar. UNC-Pfade (`\\Server\Share\...`) sind daher
zuverlässiger als Laufwerksbuchstaben.

Über den „…“-Button im Konfigurationsdialog lässt sich die HTML-Datei bequem
per Dateiauswahl-Dialog auswählen, statt den Pfad von Hand einzutippen.

## Fehlerdiagnose

Kann die Seite/Datei nicht geladen werden (falscher Pfad, Share nicht
erreichbar etc.), zeigt der Bildschirmschoner eine Fehlermeldung im Vollbild
an, statt abzustürzen oder einfach schwarz zu bleiben.

## Anpassungsideen

- Mehrere URLs mit Rotation
- Konfiguration per JSON-Datei statt Registry
- Kiosk-typische Fehlerseite anzeigen, falls die URL nicht erreichbar ist
- Eigenes Icon für die .scr-Datei setzen (`ApplicationIcon` im .csproj)
