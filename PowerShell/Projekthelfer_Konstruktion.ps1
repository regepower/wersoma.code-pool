###############################################
#
# Wersoma Tool für die Erstellung von Projektordnern
# für die Konstruktion und die Fertigung.
#
# V0.1 Stand 21.21.2025 Trolle
# V0.2 Stand 21.21.2025 Trolle - unnötige Abfragen entfernt & Bei vorhandenen Ordnern werden keine Ordner erstellt
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


[string]$Trennzeichen = "_"

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
        [string]$SourcePath,       # Quellordner, von dem kopiert werden soll
        [string]$DestinationPath   # Zielordner, in den kopiert werden soll
    )

    # Überprüfen, ob der Zielordner leer ist
    if (Test-Path -Path $DestinationPath) {
        # Wenn der Zielordner existiert, prüfen, ob er leer ist
        $destinationItems = Get-ChildItem -Path $DestinationPath
        if ($destinationItems.Count -gt 0) {
            Write-Host "Der Zielordner '$DestinationPath' ist nicht leer. Kopieren wird übersprungen." -ForegroundColor Yellow
            return
        }
    } else {
        # Wenn der Zielordner nicht existiert, erstelle ihn
        New-Item -Path $DestinationPath -ItemType Directory | Out-Null
    }

    # Kopiere den Inhalt des Quellordners in den Zielordner
    Write-Host "Kopiere Inhalte von '$SourcePath' nach '$DestinationPath'..."
    Copy-Item -Path $SourcePath\* -Destination $DestinationPath -Recurse -Force
    Write-Host "Inhalte erfolgreich kopiert."
}


# Funktion zum Umbenennen der Ordner
function Rename-Folder {
    param (
        [string]$BaseFolderPath,   # Der Pfad, wo der Ordner umbenannt werden soll
        [string]$OldFolderName,    # Der alte Ordnername (z.B. "xx_xxxxx_Dokumentationen")
        [string]$ArchivNr,         # Archivnummer (z.B. "11")
        [string]$ProjektNr         # Projektnummer (z.B. "12345")
    )

    # Ersetze die Platzhalter im Ordnernamen durch ArchivNr und ProjektNr
    $NewFolderBaseName = $OldFolderName -replace "xx_xxxxx", "$ArchivNr`_$ProjektNr"

    # Pfad des bestehenden Ordners
    $OriginalPath = Join-Path -Path $BaseFolderPath -ChildPath $OldFolderName
    if (-not (Test-Path -Path $OriginalPath)) {
        Write-Host "Das Verzeichnis $OldFolderName existiert nicht. Umbenennen übersprungen..." -ForegroundColor Yellow
        return
    }

    # Neuen Ordnernamen direkt verwenden
    $NewPath = Join-Path -Path $BaseFolderPath -ChildPath $NewFolderBaseName

    # Überprüfen, ob der Ordner mit dem gewünschten Namen bereits existiert
    if (Test-Path -Path $NewPath) {
        Write-Host "Der Ordner '$NewFolderBaseName' existiert bereits. Das Umbenennen wird übersprungen." -ForegroundColor Yellow
        return
    }

    # Umbenennen des Ordners
    Rename-Item -Path $OriginalPath -NewName $NewFolderBaseName
    Write-Host "Verzeichnis umbenannt in: $NewPath"

    # Rückgabe des neuen Pfads
    return $NewPath
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
$FullPfadKonstruktion = "$PfadKonstruktion\Archiv$ArchivNr\$Projektgruppe\$ArchivNr$Trennzeichen$ProjektNr\"
Check-And-Create-Folder -Path "$PfadKonstruktion\Archiv$ArchivNr"
Check-And-Create-Folder -Path "$PfadKonstruktion\Archiv$ArchivNr\$Projektgruppe"
Check-And-Create-Folder -Path $FullPfadKonstruktion

# Kopieren des Inhalts von $PfadKonstruktion/A_Vorlage in den vollständigen Konstruktionspfad
$QuelleVorlage = Join-Path -Path $PfadKonstruktion -ChildPath "A_Ordnervorlage"
Copy-FolderContent -SourcePath $QuelleVorlage -DestinationPath $FullPfadKonstruktion

# Umbenennen der Ordner
Rename-Folder -BaseFolderPath $FullPfadKonstruktion -OldFolderName "xx_xxxxx_Dokumentationen" -ArchivNr $ArchivNr -ProjektNr $ProjektNr
Rename-Folder -BaseFolderPath $FullPfadKonstruktion -OldFolderName "xx_xxxxx_Konstruktionsdaten" -ArchivNr $ArchivNr -ProjektNr $ProjektNr


[System.Windows.Forms.MessageBox]::Show(
    "Verzeichnisstruktur wurde erstellt falls nicht schon vorhanden:

Konstruktionsdaten: $FullPfadKonstruktion

Fertigungsdaten: $FullPfadFertigung",
    $Fenstertitel,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)


# Explorer-Fenster mit dem Pfad $FullPfadKonstruktion öffnen
Start-Process -FilePath explorer.exe -ArgumentList $FullPfadKonstruktion