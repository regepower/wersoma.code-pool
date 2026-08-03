# Pfad zu Poppler hinzufügen
$env:PATH = "$env:PATH;N:\Download\PortableApps\poppler-24.08.0\Library\bin"

# Pfad zur PDF-Datei und Ziel-Textdatei
$pdfPath = "R:\Kunden\Heidelberger Druckmaschinen\20250326 BV.015.0006 BAZ-Vorrichtung\BV_015_0006\DRW-BV.015.0006-000-00.pdf"
$outputPath = Join-Path -Path $env:TEMP -ChildPath "PDFextract.txt"

# pdftotext ausführen
pdftotext -layout $pdfPath $outputPath
break
###################################################
# Pfad zur Textdatei
$textFilePath = $outputPath

# Dateiinhalt einlesen
$fileContent = Get-Content -Path $textFilePath

# Variable für die gefundene Nummer
$foundNumber = $null

# Algorithmus: Suche nach "Mat.-Nr." und der ersten 7-stelligen Nummer danach
for ($i = 0; $i -lt $fileContent.Length; $i++) {
    if ($fileContent[$i] -match "Mat\.-Nr\.") {
        # Gefundene Zeile nach "Mat.-Nr."
        $lineAfterMatch = $fileContent[$i]

        # Suche nach der ersten 7-stelligen Nummer in derselben Zeile
        if ($lineAfterMatch -match "\b\d{7}\b") {
            $foundNumber = $matches[0]
            break
        }

        # Wenn keine Nummer in derselben Zeile ist, prüfe die folgenden Zeilen
        for ($j = $i + 1; $j -lt $fileContent.Length; $j++) {
            if ($fileContent[$j] -match "\b\d{7}\b") {
                $foundNumber = $matches[0]
                break
            }
        }
        break # Verlasse die Schleife nach dem ersten Fund
    }
}

# Wenn eine Nummer gefunden wurde, ausgeben
if ($foundNumber) {
    Write-Output "Gefundene Nummer: $foundNumber"
} else {
    Write-Host "Es wurde keine 7-stellige Nummer nach 'Mat.-Nr.' gefunden."
}

# Temporäre Datei löschen (am Ende des Skripts)
if (Test-Path $outputPath) {
    Remove-Item -Path $outputPath -Force
    Write-Host "Die temporäre Datei wurde gelöscht: $outputPath"
}
