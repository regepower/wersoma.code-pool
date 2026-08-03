###############################################
#
# Wersoma Tool für die Erstellung von Projektordnern
# für die Arbeitsvorbereitung und die Fertigung.
#
# V0.1 Stand 24.21.2025 Trolle
# V0.2                          Abfragen für Dateinamen hinzu und Hidewindow.
# Todo einbinden https://smsagent.blog/2017/08/24/a-customisable-wpf-messagebox-for-powershell/
###############################################
# Aufruf mit Verknüpfung: powershell.exe -noprofile  -ExecutionPolicy Bypass -command "& {N:\Download\PortableApps\Projekthelfer_AV.ps1 ($args -join ' ')}"
# WIN-R shell:sendto und Verknüpfung reinkopieren



# Parameterblock: Erwartet die Eingabe als Zeichenkette von Dateipfaden
param (
    [string]$Paths  # Übergebene Dateipfade als String
)

function Activate-Window {
    param (
        [string]$windowTitle
    )

    Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

    # Fensterhandle finden
    $hWnd = [User32]::FindWindow([NullString]::Value, $windowTitle)

    if ($hWnd -ne [IntPtr]::Zero) {
        # Fenster in den Vordergrund bringen
        [User32]::SetForegroundWindow($hWnd)
        Write-Host "Fenster '$windowTitle' wurde aktiviert."
    } else {
        Write-Host "Fenster '$windowTitle' nicht gefunden."
    }
}


function Minimize-Console {
    # VBScript als PowerShell-String definieren
    $vbScript = @"
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.SendKeys "% "  ' Alt + Space
WshShell.SendKeys "n"   ' N zum Minimieren
"@

    # Temporäre Datei für das VBScript erstellen
    $tempFile = "$env:Temp\SendKeys_Minimize.vbs"
    $vbScript | Set-Content -Path $tempFile

    # VBScript ausführen, um die Konsole zu minimieren
    Start-Process -FilePath "wscript.exe" -ArgumentList $tempFile -NoNewWindow -Wait

    # Temporäre Datei löschen
    Remove-Item -Path $tempFile -Force
}


# DPI Helper hinzu
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DPIHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@
[DPIHelper]::SetProcessDPIAware()



# Beispiel-Eingabe ($Paths) für Test
#Paths = "\\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0005_100122298nxz001_a.dxf \\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0006_100122298nxz001_a.pdf \\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0007_100122298nxm000_01.stp"
#$Paths = ""R:\Kunden\Licon\20250121 6000032995 div. Teile\1070028\0045_100122332nxz001_-.pdf"
#$Paths = "R:\Kunden\Licon\20250121 6000032995 div. Teile\1070028\0045_100122332nxz001_-.pdf R:\Kunden\Licon\20250121 6000032995 div. Teile\1070028\0046_100122332nxm000_00.stp"

# Funktion: Verarbeitet Eingabezeichenkette und erstellt Dateiliste
function ProcessPaths {
#    param (
#        [string]$Paths
#    )

    $Dateiliste = @()

    if ($Paths -like "\\*") {  # Verarbeitung von UNC-Pfaden
        $currentPath = ""
        $isInPath = $false

        for ($i = 0; $i -lt $Paths.Length; $i++) {
            $char = $Paths[$i]

            if ($i -lt $Paths.Length - 1 -and $char -eq '\' -and $Paths[$i + 1] -eq '\') {
                if ($isInPath) {
                    $Dateiliste += $currentPath.Trim()
                    $currentPath = ""
                }
                $isInPath = $true
                $currentPath += "\\"
                $i++
            } else {
                if ($isInPath) {
                    $currentPath += $char
                }
            }
        }

        if ($currentPath.Trim()) {
            $Dateiliste += $currentPath.Trim()
        }

    } else {
        # Verarbeitung für normale Pfade
        $pattern = '([a-zA-Z]:\\(((?![<>:""/\\|?*]).)+((?<![ .])\\)?)*)(\s|$)'
        $matches = [regex]::Matches($Paths, $pattern)
        foreach ($match in $matches) {
            $Dateiliste += $match.Groups[1].Value.Trim()
        }
    }

    $Dateiliste = $Dateiliste | Sort-Object -Unique

    # Überprüfung, ob Ordner in der Liste sind
    $removedFolders = @()  # Liste der entfernten Ordner
    $finalList = @()

    foreach ($item in $Dateiliste) {
        if (Test-Path -Path $item -PathType Leaf) {  # Überprüfen, ob es sich um eine Datei handelt
            $finalList += $item
        } elseif (Test-Path -Path $item -PathType Container) {  # Überprüfen, ob es ein Ordner ist
            $removedFolders += $item
        }
    }

    # Hinweisfenster anzeigen, wenn Ordner entfernt wurden
    if ($removedFolders.Count -gt 0) {
         [void][System.Windows.Forms.MessageBox]::Show("Nur Dateien gültig!!!!Die folgenden Ordner wurden aus der Liste entfernt:`n`n$($removedFolders -join "`n")", "AV Projekthelfer", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }

    $Dateiliste = $finallist

    return $Dateiliste
}

# Funktion: Extrahiert Dateinamen, Kundenordner und Projektordner
function ExtractFolderInfo {
    param (
        [string[]]$Dateiliste
    )

    $DateiNamesListe = @()
    $KundenOrdner = $null
    $ProjektOrdner = $null

    if ($Dateiliste.Count -gt 0) {
        foreach ($path in $Dateiliste) {
            $DateiNamesListe += [System.IO.Path]::GetFileName($path)

             if (-not $KundenOrdner -and $path -match '\\Kunden\\([^\\]+)') {
                $KundenOrdner = $matches[1]
            }

             if (-not $ProjektOrdner) {
                $parentPath = [System.IO.Path]::GetDirectoryName($path)
                $folderName = [System.IO.Path]::GetFileName($parentPath)

                if ($folderName -match '^\d{8}_(.+)$') {
                    $ProjektOrdner = $matches[1]
                } else {
                    $ProjektOrdner = $folderName
                }
            }
        }
    }

    return [PSCustomObject]@{
        DateiNamesListe = $DateiNamesListe
        KundenOrdner    = $KundenOrdner
        ProjektOrdner   = $ProjektOrdner
    }
}

# Installiere die erforderliche Assembly für Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Funktion zur Erstellung des Fensters
function CreateWindow {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $global:OK_Pressed = $false  # Abbruch wenn das nicht true ist also OK gedrückt wurde


    # Fenster erstellen
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Projekthelfer AV"
    $form.Size = New-Object System.Drawing.Size(640, 480)
    $form.StartPosition = "CenterScreen"
    #$form.BackColor = [System.Drawing.Color]::White  # Hintergrund weiß
    # Fensterrahmen fixieren, damit die Größe nicht verändert werden kann
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    # Fenster im Vordergrund halten
    $form.TopMost = $true


    # Eingabefeld 1: KundenPfad
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "KundenPfad:"
    $label1.Location = New-Object System.Drawing.Point(50, 50)
    $label1.Size = New-Object System.Drawing.Size(100, 20)

    $input1 = New-Object System.Windows.Forms.TextBox
    $input1.Text = $global:KundenOrdner
    $input1.Location = New-Object System.Drawing.Point(150, 50)
    $input1.Size = New-Object System.Drawing.Size(300, 30)

    # ToolTip-Objekt erstellen und mit dem Button verbinden
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.SetToolTip($input1, "Dieser Ordner wird unter N:\00_Fertigungsdaten\Kunden\ angelegt...")  # Hinweistext setzen

    # Event für die Eingabe-Felder: Überprüfe, ob Enter gedrückt wurde
    $input1.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $global:KundenOrdner = $input1.Text
            $global:OK_pressed = $true  # Setze das Flag auf true
            $form.Close()  # Schließe das Fenster
        }
    })

    # Eingabefeld 2: ProjektPfad
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "ProjektPfad:"
    $label2.Location = New-Object System.Drawing.Point(50, 80)
    $label2.Size = New-Object System.Drawing.Size(100, 20)

    $input2 = New-Object System.Windows.Forms.TextBox
    $input2.Text = $global:ProjektOrdner
    $input2.Location = New-Object System.Drawing.Point(150, 80)
    $input2.Size = New-Object System.Drawing.Size(300, 30)

    # ToolTip-Objekt erstellen und mit dem Button verbinden
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.SetToolTip($input2, "Dieser Ordner wird unter N:\00_Fertigungsdaten\Kunden\'Kundenpfad' angelegt...")  # Hinweistext setzen

    $input2.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $global:ProjektOrdner = $input2.Text # Update der Variablen
            $global:OK_pressed = $true  # Setze das Flag auf true
            $form.Close()  # Schließe das Fenster
        }
    })

    # Ausgabe der Dateiliste
    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = "Dateiliste:"
    $label3.Location = New-Object System.Drawing.Point(50, 140)
    $label3.Size = New-Object System.Drawing.Size(100, 20)

    $outputBox = New-Object System.Windows.Forms.TextBox
    $outputBox.Multiline = $true
    $outputBox.WordWrap = $false
    $outputBox.ScrollBars = "Both"
    $outputBox.ReadOnly = $true
    $outputBox.BackColor = [System.Drawing.Color]::White
    $outputBox.Location = New-Object System.Drawing.Point(50, 160)
    $outputBox.Size = New-Object System.Drawing.Size(550, 200)

    # Dateinamen in die TextBox schreiben
    $Dateiliste | ForEach-Object {
        $outputBox.AppendText("$_`r`n")
    }

    # Button: Dateien auswählen
    $iconButton = New-Object System.Windows.Forms.Button
    $iconButton.Location = New-Object System.Drawing.Point(510, 30)
    $iconButton.Size = New-Object System.Drawing.Size(64, 64)
    $iconButton.Text = ""

    # ToolTip-Objekt erstellen und mit dem Button verbinden
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.SetToolTip($iconButton, "Dateien (neu) auswählen...")  # Hinweistext setzen

    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\explorer.exe")
    $iconButton.Image = $icon.ToBitmap()

    # Button-Click-Ereignis: Datei-Auswahl
    $iconButton.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.InitialDirectory = "R:\Kunden\"
        $fileDialog.Filter = "Alle Dateien (*.*)|*.*"
        $fileDialog.Multiselect = $true

        if ($fileDialog.ShowDialog() -eq "OK") {
            $global:Dateiliste = $fileDialog.FileNames
            $result = ExtractFolderInfo -Dateiliste $global:Dateiliste
            $global:DateiNamesListe = $result.DateiNamesListe
            $global:KundenOrdner = $result.KundenOrdner
            $global:ProjektOrdner = $result.ProjektOrdner

            # Update der Fensterinhalte
            $input1.Text = $global:KundenOrdner
            $input2.Text = $global:ProjektOrdner

            # Dateinamen in die TextBox schreiben
            $global:Dateiliste | ForEach-Object {
                $outputBox.AppendText("$_`r`n")
            }
        }
    })

    # Abbruch-Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Abbruch"
    $cancelButton.Location = New-Object System.Drawing.Point(220, 380)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Add_Click({
        $form.Close()   # Schließe das Fenster
    })

    # OK-Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(350, 380)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Add_Click({
        $global:KundenOrdner = $input1.Text # Update der Variablen
        $global:ProjektOrdner = $input2.Text # Update der Variablen
        $global:OK_pressed= $true
        $form.Close() # Schließe das Fenster
    })

    # Elemente hinzufügen
    $form.Controls.AddRange(@($label1, $input1, $label2, $input2, $label3, $outputBox, $iconButton, $cancelButton, $okButton))

    # Fenster anzeigen
    $form.Activate()
    $form.ShowDialog()
}

# Verarbeitung der Pfade und Initialisierung
$Dateiliste = ProcessPaths -Paths $Paths
$result = ExtractFolderInfo -Dateiliste $Dateiliste

# Globale Variablen setzen
$global:Dateiliste = $Dateiliste
$global:DateiNamesListe = $result.DateiNamesListe
$global:KundenOrdner = $result.KundenOrdner
$global:ProjektOrdner = $result.ProjektOrdner

# Fenster starten
Minimize-Console
CreateWindow

# Überprüfe den Rückgabewert
if ($global:OK_Pressed -eq $false -or [string]::IsNullOrEmpty($global:KundenOrdner) -or [string]::IsNullOrEmpty($global:ProjektOrdner)) {
    [System.Windows.Forms.MessageBox]::Show("Kundenordner oder Projektordner leer oder Abbruch betätigt!", "Projekthelfer AV", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}



# Hauptroutine:
# Ordner erstellen und Dateien Kopieren.
#
Write-host "OK=$global:OK_Pressed"
Write-host "K=$global:KundenOrdner"
Write-host "P=$global:ProjektOrdner"
Write-host "D=$global:Dateiliste ende"

# Basisverzeichnis, in dem der Kundenordner und Projektordner erstellt werden
$basePath = "N:\00_Fertigungsdaten\Kunden"

# Funktion zum Erstellen eines Verzeichnisses, falls es noch nicht existiert
function Create-DirectoryIfNotExists {
    param (
        [string]$directoryPath
    )

    if (-not (Test-Path -Path $directoryPath)) {
        New-Item -ItemType Directory -Path $directoryPath | Out-Null
        Write-Host "Verzeichnis '$directoryPath' wurde erstellt."
    }
}

# 1. Erstelle den Kundenordner, falls er noch nicht existiert
$KundenOrdnerPath = Join-Path -Path $basePath -ChildPath $global:KundenOrdner
Create-DirectoryIfNotExists -directoryPath $KundenOrdnerPath

# 2. Erstelle den Projektordner, falls er noch nicht existiert
$ProjektOrdnerPath = Join-Path -Path $KundenOrdnerPath -ChildPath $global:ProjektOrdner
Create-DirectoryIfNotExists -directoryPath $ProjektOrdnerPath

# 3. Erstelle die Unterordner CAD, CAM und QS im Projektordner, falls sie noch nicht existieren
$cadPath = Join-Path -Path $ProjektOrdnerPath -ChildPath "CAD"
$camPath = Join-Path -Path $ProjektOrdnerPath -ChildPath "CAM"
$qsPath = Join-Path -Path $ProjektOrdnerPath -ChildPath "QS"

Create-DirectoryIfNotExists -directoryPath $cadPath
Create-DirectoryIfNotExists -directoryPath $camPath
Create-DirectoryIfNotExists -directoryPath $qsPath

# 4. Kopiere die Dateien aus der Dateiliste in den Unterordner CAD
foreach ($file in $global:Dateiliste) {
    $destinationPath = Join-Path -Path $cadPath -ChildPath (Split-Path -Leaf $file)

    if (-not (Test-Path -Path $destinationPath)) {
        Copy-Item -Path $file -Destination $destinationPath
        Write-Host "Datei '$file' wurde nach '$destinationPath' kopiert."
    } else {
        Write-Host "Datei '$file' existiert bereits in '$destinationPath'."
    }
}

# 5. Abschlussmeldung anzeigen
$message = "Kundenordner erstellt:`t'$global:KundenOrdner'`nProjektordner erstellt:`t'$global:ProjektOrdner'`nUnterordner CAD CAM QS erstellt`n (nur falls nicht vorhanden).`n`n"
$message += "Die folgenden Dateien wurden in den Ordner 'CAD' kopiert:`n`n"
foreach ($file in $global:Dateiliste) {
    $message += "$file`n"
}

[System.Windows.Forms.MessageBox]::Show($message, "Projekthelfer AV", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)


# Explorer-Fenster mit dem Pfad N:...Kunden öffnen
# Start-Process -FilePath explorer.exe -ArgumentList $cadPath