###############################################
#
# Wersoma Tool für die Erstellung von Projektordnern
# für die Konstruktion und die Fertigung.
#
# V0.1 Stand 21.21.2025 Trolle
# V0.2 Stand 21.21.2025 Trolle - unnötige Abfragen entfernt & Bei vorhandenen Inhalt wird eine Version aus Vorlage kopiert
###############################################

# ---------------------------------------------
# Variablendeklaration
# ---------------------------------------------
Add-Type -AssemblyName Microsoft.VisualBasic

# Pfade für Fertigungs- und Konstruktionsdaten
$PfadFertigung = "N:\00_Fertigungsdaten\Wersoma"
$PfadKonstruktion = "K:\user\Archiv"

# Gültige Archivnummern
$validArchivNr = @("11", "12", "13", "14", "15", "16", "21", "22", "23", "24", "25", "31", "32", "33", "34", "35", "36", "37", "38", "39", "41", "42", "43", "44", "45", "46", "47", "49", "51", "52", "53", "54", "55", "56", "57", "58", "59", "81", "82", "83", "84", "85", "87", "88", "89", "91", "92", "93")

# Variablen für die ProjektNr und Projektgruppe
[string]$ProjektNr = ""
[string]$Projektgruppe = ""

# Fentertitel fix
[string]$Fenstertitel = "[W]ersoma Projekthelfer Konstruktion"

# ---------------------------------------------
# Funktionen
# ---------------------------------------------
# Funktion zur Zuordnung einer Zahl zu einem Bereich
function Get-Range {
    param (
        [int]$Number
    )

    # Bereich berechnen
    $Start = [math]::Floor($Number / 50) * 50
    $End = $Start + 49

    # Bereich formatieren (manuelle Formatierung mit PadLeft)
    $StartFormatted = $Start.ToString().PadLeft(5, '0')
    $EndFormatted = $End.ToString().PadLeft(5, '0')

    # Bereich zurückgeben
    return "$StartFormatted-$EndFormatted"
}

# Funktion: Verzeichnis prüfen und erstellen (ohne MessageBox)
function Check-And-Create-Folder {
    param (
        [string]$Path
    )

    # Prüfe, ob das Verzeichnis existiert
    if (-Not (Test-Path -Path $Path)) {
        Write-Host "Verzeichnis existiert nicht, wird erstellt: $Path"
        New-Item -ItemType Directory -Path $Path | Out-Null
    } else {
        Write-Host "Verzeichnis existiert bereits: $Path"
    }
}

# Funktion zum Erstellen der zusätzlichen Unterverzeichnisse im Fertigungspfad
function Create-SubFolders {
    param (
        [string]$BasePath,
        [string[]]$SubFolders
    )

    foreach ($folder in $SubFolders) {
        $FullPath = Join-Path -Path $BasePath -ChildPath $folder
        Check-And-Create-Folder -Path $FullPath
    }
}

# Funktion: Inhalte eines Ordners kopieren
function Copy-FolderContent {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )

    # Stelle sicher, dass die Pfade absolute Pfade sind
    $SourcePath = Resolve-Path -Path $SourcePath -ErrorAction Stop
    $DestinationPath = Resolve-Path -Path $DestinationPath -ErrorAction Stop

    # Prüfe, ob der Quellordner existiert
    if (-Not (Test-Path -Path $SourcePath)) {
        Write-Host "Quellordner existiert nicht: $SourcePath"
        return
    }

    # Prüfe, ob das Zielverzeichnis existiert, und erstelle es falls nötig
    if (-Not (Test-Path -Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath | Out-Null
    }

    # Kopiere Inhalte
    Get-ChildItem -Path $SourcePath -Recurse | ForEach-Object {
        $Destination = Join-Path -Path $DestinationPath -ChildPath $_.FullName.Substring($SourcePath.Length).TrimStart("\")
        if ($_.PSIsContainer) {
            if (-Not (Test-Path -Path $Destination)) {
                New-Item -ItemType Directory -Path $Destination | Out-Null
            }
        } else {
            Copy-Item -Path $_.FullName -Destination $Destination -Force
        }
    }

    Write-Host "Inhalt von '$SourcePath' wurde nach '$DestinationPath' kopiert."
}

# Funktion zum Umbenennen der Ordner
function Rename-Folder {
    param (
        [string]$BasePath,
        [string]$OldFolderName,
        [string]$NewFolderName
    )

    $OldPath = Join-Path -Path $BasePath -ChildPath $OldFolderName
    $NewPath = Join-Path -Path $BasePath -ChildPath $NewFolderName

    if (Test-Path -Path $OldPath) {
        Rename-Item -Path $OldPath -NewName $NewFolderName
        Write-Host "Ordner '$OldFolderName' wurde zu '$NewFolderName' umbenannt."
    } else {
        Write-Host "Ordner '$OldFolderName' wurde nicht gefunden."
    }
}

function Rename-To-UniqueFolder {
    param (
        [string]$BaseFolderPath,   # Der Pfad, wo der Ordner umbenannt werden soll
        [string]$OldFolderName,    # Der alte Ordnername mit Platzhaltern (z.B. "xx_xxxxx_00_Dokumentationen")
        [string]$ArchivNr,         # Archivnummer (z.B. "11")
        [string]$ProjektNr         # Projektnummer (z.B. "12345")
    )

    # Ersetze die Platzhalter im Ordnernamen durch ArchivNr und ProjektNr
    $NewFolderBaseName = $OldFolderName -replace "xx_xxxxx", "$ArchivNr`_$ProjektNr"

    # Extrahiere den Zähler aus dem alten Ordnernamen (z.B. "_00_")
    $regex = "^(.*)_(\d{2})_(.*)$"
    if ($NewFolderBaseName -notmatch $regex) {
        Write-Host "Ungültiges Format des Ordnernamens: $NewFolderBaseName" -ForegroundColor Red
        return
    }

    # Teile aus dem regulären Ausdruck extrahieren
    $Prefix = $matches[1]   # Der Teil vor "_XX_"
    $Suffix = $matches[3]   # Der Teil nach "_XX_"
    $Counter = [int]$matches[2]   # Initialer Zähler aus dem Ordnernamen

    # Pfad des bestehenden Ordners
    $OriginalPath = Join-Path -Path $BaseFolderPath -ChildPath $OldFolderName
    if (-not (Test-Path -Path $OriginalPath)) {
        Write-Host "Das Verzeichnis $OriginalPath existiert nicht." -ForegroundColor Red
        return
    }

    # Schleife zur Suche nach einem eindeutigen Namen
    $UniqueFolderName = $NewFolderBaseName
    do {
        # Generiere den neuen Ordnernamen mit Zähler
        $UniqueFolderName = "$Prefix" + "_{0:D2}_" -f $Counter + "$Suffix"
        $NewPath = Join-Path -Path $BaseFolderPath -ChildPath $UniqueFolderName

        # Zähler erhöhen, wenn der Name existiert
        $Counter++
    } while (Test-Path -Path $NewPath)

    # Umbenennen des Ordners
    Rename-Item -Path $OriginalPath -NewName $UniqueFolderName
    Write-Host "Verzeichnis umbenannt in: $NewPath"

    # Rückgabe des neuen Pfads
    return $Counter-1
}


# ---------------------------------------------
# Hauptcode
# ---------------------------------------------
do {
    $input = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Welches Archiv soll angelegt werden?

Format ist XX-XXXXX

Die ersten beiden Ziffern sind die ArchivNr.
Trennzeichen beliebig.
Die letzten Ziffern sind die ProjektNr.",
        $Fenstertitel,
        ""
    )

    # Abbrechen prüfen
    if ([string]::IsNullOrWhiteSpace($input)) {
        [System.Windows.Forms.MessageBox]::Show(
                "Operation abgebrochen! Bye bye!",
                $Fenstertitel,
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Stop)
        exit
    }

    # Validierung: 2 Ziffern, beliebiges Trennzeichen, 0-99999
    if ($input -match "^(?<ArchivNr>\d{2})[^\w\d](?<ProjektNr>\d{1,5})$") {
        # Extrahiere ArchivNr und ProjektNr
        $ArchivNr = $matches["ArchivNr"]
        $ProjektNr = $matches["ProjektNr"]

        # Prüfe, ob die ArchivNr gültig ist
        if ($validArchivNr -contains $ArchivNr) {
            # ProjektNr als 5-stellige Zahl formatieren
            $ProjektNr = $ProjektNr.PadLeft(5, '0')

            # Bereich (Projektgruppe) berechnen
            $Projektgruppe = Get-Range -Number ([int]$ProjektNr)

            Write-Host "Eingabe akzeptiert: ArchivNr: $ArchivNr, ProjektNr: $ProjektNr"
            Write-Host "Projektgruppe: $Projektgruppe"
            break
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "Die ArchivNr ($ArchivNr) ist ungültig",
                $Fenstertitel,
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Eingabefehler! (2 Ziffern, beliebiges Trennzeichen, 0-99999).",
            $Fenstertitel,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
} while ($true)


# Erstellung der Verzeichnisstruktur
Write-Host "Verzeichnisstruktur wird überprüft und bei Bedarf erstellt..."

# Fertigungspfad
$FullPfadFertigung = "$PfadFertigung\Archiv_$ArchivNr\$Projektgruppe\$ProjektNr\"
Check-And-Create-Folder -Path "$PfadFertigung\Archiv_$ArchivNr"
Check-And-Create-Folder -Path "$PfadFertigung\Archiv_$ArchivNr\$Projektgruppe"
Check-And-Create-Folder -Path $FullPfadFertigung

# Zusätzliche Unterverzeichnisse im Fertigungspfad erstellen
Create-SubFolders -BasePath $FullPfadFertigung -SubFolders @("CAD", "CAM", "QS")

# Konstruktion
$FullPfadKonstruktion = "$PfadKonstruktion\Archiv$ArchivNr\$Projektgruppe\$ProjektNr\"
Check-And-Create-Folder -Path "$PfadKonstruktion\Archiv$ArchivNr"
Check-And-Create-Folder -Path "$PfadKonstruktion\Archiv$ArchivNr\$Projektgruppe"
Check-And-Create-Folder -Path $FullPfadKonstruktion

# Kopieren des Inhalts von $PfadKonstruktion/A_Vorlage in den vollständigen Konstruktionspfad
$QuelleVorlage = Join-Path -Path $PfadKonstruktion -ChildPath "A_Ordnervorlage"
Copy-FolderContent -SourcePath $QuelleVorlage -DestinationPath $FullPfadKonstruktion

# Umbenennen der Ordner
Rename-To-UniqueFolder -BaseFolderPath $FullPfadKonstruktion -OldFolderName "xx_xxxxx_00_Dokumentationen" -ArchivNr $ArchivNr -ProjektNr $ProjektNr
$Version = Rename-To-UniqueFolder -BaseFolderPath $FullPfadKonstruktion -OldFolderName "xx_xxxxx_00_Konstruktionsdaten" -ArchivNr $ArchivNr -ProjektNr $ProjektNr


[System.Windows.Forms.MessageBox]::Show(
    "Verzeichnisstruktur wurde erstellt:

Konstruktionsdaten: $FullPfadKonstruktion

Version: $Version

Fertigungsdaten: $FullPfadFertigung",
    $Fenstertitel,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)


# Explorer-Fenster mit dem Pfad $FullPfadKonstruktion öffnen
Start-Process -FilePath explorer.exe -ArgumentList $FullPfadKonstruktion