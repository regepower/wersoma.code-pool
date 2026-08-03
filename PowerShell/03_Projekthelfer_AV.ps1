###############################################
#
# Wersoma Tool für die Erstellung von Projektordnern
# für die Arbeitsvorbereitung und die Fertigung.
#
# V0.1 Stand 24.21.2025 Trolle
###############################################
# Aufruf mit Verknüpfung: powershell.exe -noprofile  -ExecutionPolicy Bypass  -WindowStyle Hidden -command "& {N:\Download\PortableApps\Projekthelfer_AV.ps1 ($args -join ' ')}"




# Parameterblock: Erwartet die Eingabe als Zeichenkette von Dateipfaden
param (
    [string]$Paths  # Übergebene Dateipfade als String
)



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
#$Paths = "\\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0005_100122298nxz001_a.dxf \\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0006_100122298nxz001_a.pdf \\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0007_100122298nxm000_01.stp"
#$Paths = "R:\Kunden\JD_Norman\20180524_VW Phönix\03c_103_021_aj_anlief-roh m Erstschn-step(2).stp R:\Kunden\JD_Norman\20180524_VW_Phönix\03C_103_021_BK-vorbearb_roh_20180515 info.pdf R:\Kunden\JD_Norman\20180524_VW_Phönix\03c_103_021_rohteil step.stp"

# Funktion: Verarbeitet Eingabezeichenkette und erstellt Dateiliste
function ProcessPaths {
    param (
        [string]$Paths
    )

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


    # Symbol erstellen
    # Base64-kodiertes Icon
    $base64Icon = "AAABAAEAICAAAAEAGACoDAAAFgAAACgAAAAgAAAAQAAAAAEAGAAAAAAAAAAAAJYAAACWAAAAAAAAAAAAAAD///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7///7///7///7////////////////////////////////////////////////////////////////////////////////////////////////////9/Pbm1brZvpPYvpPbvpTbvpTavpTZvpPgza/79/H+/v////////////7////////////////////////////////////////////////////////////////9+/fdxaDYvI/izKbZuYjMnFnDjj/27+P///7//v3z7d3ZwJjav5b69u7//v///v/////////////////////////////////////////////////////////////07N7UtIXkz6zJlk21chPJlk3Ll1GyagbavY7Hl1Ll07b///7//v348unVuIru4sz+/v/////////////////////////////////////////////////////////v5NDWvY/Ws361awe4aQPWr3rjzKvfxp3Wsn7ImVTSqnD07N7n1bfDkknz6Nn+//3fyabm1bn+//7////////////////////////////////////////////////y6NbZv5THmVLDjkHo1rjgxJvCijrp17q7finn1bm+gCrcv4/y6tu5fSnUrnbKn1/+/v7+//7j0bLn2L/+///////////////////////////////////////////9/PjTtIXTqm+1awjv48zFllPkz621chbx5tLp2bvHlE7UrnTIoWjauorOol+9gzHt4MjMn2HZt4f+//zYvZP48+n////////////////////////////////////////fyqfhyaOybgy0bArz6da4fCXJnV7Ys33AhC+2bw+1aAP0693///769u3UsX3OpWq6gi/ewpbGkkju4877+PHZvpP+///////////////////////////////////+/frWu43EjkDewpjLn1/Im1rx5s7n07O5dRm2aQG2aQG0aQP0693////////+//7s3sju4sziy6m6gDD38uj+///cxJ359ev////////////////////////////////o2b/dw5m1aQTcvpLizKnewZa1awi1aQK2aQG2aQG2agCzaQP0693////////////////q28PGmlbz6dbn1LXr3cj69ezdxqH////////////////////////////////awJbVs3zTqm748uXk0rD28OXChzS2aQG2aQG2aQG2aQG0aQP0693////////////////+//3ImVW/hDK7fSjm0rD///3XvZD///7////////////////////////////ZvpPKmFG3bw+3dxq6fCS7gSu0agO2aQG2aQG2aQG1aQG1aQP0693////////////////+///Rq3HWr3O+hjfBkEf+/vzYvpX//v7////////////////////////+///cwJPCiDrgxpvs3MHt38Xbuom1aQG2aQG2aQG2aQG1agC0aQP0693////////////////////48unQqW7bvZD07d///v3bv5b+/vz////////////////////////+///bv5LAhTK2diDTtono2L7IlEq2aQG2aQG2aQG2aQG1aQG1aAP0693////////////////////38ea9gjHQp2e7hDb8+fPcvpb///z////////////////////////+///bv5LAhTLJl0zt38fWtIK6dhm2aQG2aQG2aQG2aQG1agC0aALz6tz////////////////////m1rvVsnvfyJ/Oo2Tx5dTcvpb///z////////////////////////+///bv5LAhDPfxJno2r/18OXly6W2aQG2aQG2aQG2aQG1aQG0aALz6tz////////////////////7+PLdxJ7AjT/GlE3+/Pncvpb///z////////////////////////+///bv5LAhTK0bAu0bQ61bg61bQq2aQG2aQG2aQG2aQG1aQG0aALz6tz////////////////////////////48+n+/vv////bvpb///z////////////////////////+///bv5LBhTG2aQG2aQG1aQG2aAK1aQG2aQG2aQG1aQG1aQK1aAPz6tz////////////////////////////////////////bv5b///z////////////////////////+///bv5LBhTO2aQG2agTCiDTDhza2cA/XtH++fCG6dRTBhjG8eiHz6tv///7////////////69Ovv48/69uz///7+///+///cvpb///z////////////////////////+///bv5LBhTG2aQG2bw3+/Pf9/fe/iUD9/fjPo2POpWj////hxp/y6tz////////9/frOpmq9gzPbuYi7fSjTrHX//vz////av5b///z////////////////////////+///bv5LBhTG2aQG1bw7+/Pf9/fe0aw65dxi1agPOpWf+///hxp/y6tz+///+//7cv5W1aQLp2L7+///fxJuzaQLgx6P////bv5b///z////////////////////////+///bv5PBhTG2aQG3bw79/Pf9/fezbAy2aQG2aQHPpWf////v5NPSrHTVrHLn1bjGkEOyaAP17+P////48+ro1rnw5dP////cvpb///z////////////////////////+///bv5HBhTG2aQG3bw78/Pf9/fezbAy2aQG2aQHPpWb///7q2b7fxJvlzKbw5dPDjkGwaAT17+L///////////7///7////av5b///z////////////////////////+//7bv5HBhTG0aQO1bg/9/Pf+/fezbQy2aQG2aQHPpWf////hxqHz6tr////+//7ewpi1aAPn0rP////iyaa5dBniza7////cvpb///z////////////////////////+//7bwJHBhTHTpmnw48z9/fj9/fa0bQ22aQG2aQHPpWb///3y69vMomTLnF3jza7+/vvRrXa7fy7Xs3+7gC7VsHv//vv////cvpb///z////////////////////////+//7bv5PBhTG1aQK1bQu7fCLEiju2awW2aQG2aQG8eh7HkUnGkUrjyqbp07bx6dr+///+//7z69zp1br07d///v7////////cvpb///z////////////////////////+/v7cv5HAhTG2aQK2aQK2aQK2aQK2aQK2aQK2aQK2aQK2aQKzaAPz6tv////////////////////////////////////////cvpb///z////////////////////////+/v7avo7mzqrhxJnhxJnhxJnixJnhxJnixJnhxJnixJnhxJnhw5n58+f++/T++/T++/T++/T++/T++/T++/T++/T++/T/+/TbvZH//v3///////////////////////////7k0LHcw57cxJzcxJ7cw57cxJzcw57cxJzcxJzcxJ7cxJ3cxJ7dw57cxJ3dxJ3cw57dxJ3dxJ3cw57dw57cxJ3dxJ3cw57fx6L+/v7////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="

    # Dekodiere die Base64-Zeichenkette zu einem Byte-Array
    $iconBytes = [Convert]::FromBase64String($base64Icon)

    # Erstelle einen MemoryStream aus den Byte-Daten
    $memoryStream = New-Object System.IO.MemoryStream
    $memoryStream.Write($iconBytes, 0, $iconBytes.Length)
    $memoryStream.Position = 0  # Setze die Position des Streams auf den Anfang

    # Erstelle das Icon aus dem MemoryStream
    $icon = New-Object System.Drawing.Icon($memoryStream)

    # Verwende das Icon für das Form
    $form.Icon = $icon

    # Optional: Schließe den MemoryStream
    $memoryStream.Close()

    $form.TopMost = $true  # Fenster immer im Vordergrund halten
    $form.Activate()

    # Hinweistext über den Eingabefeldern
    $hintLabel = New-Object System.Windows.Forms.Label
    $hintLabel.Text = "Kundenordner und Projektordner müssen angegeben sein! Falls diese Ordner nicht vorhanden sind werden diese angelegt und die gewählten Datein dorthin in den Unterodner CAD kopiert."
    $hintLabel.Location = New-Object System.Drawing.Point(50, 10)
    $hintLabel.Size = New-Object System.Drawing.Size(550, 30)

    # Eingabefeld 1: KundenPfad
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "KundenOrdner:"
    $label1.Location = New-Object System.Drawing.Point(50, 60)
    $label1.Size = New-Object System.Drawing.Size(100, 20)

    $input1 = New-Object System.Windows.Forms.TextBox
    $input1.Text = $KundenOrdner
    $input1.Location = New-Object System.Drawing.Point(150, 60)
    $input1.Size = New-Object System.Drawing.Size(300, 30)

    # Event für die Eingabe-Felder: Überprüfe, ob Enter gedrückt wurde
    $input1.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $global:OK_pressed = $true  # Setze das Flag auf true
            $KundenOrdner = $input1.Text        
            $ProjektOrdner = $input2.Text
            $form.Close()  # Schließe das Fenster
        }
    })

    # Eingabefeld 2: ProjektPfad
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "ProjektOrdner:"
    $label2.Location = New-Object System.Drawing.Point(50, 100)
    $label2.Size = New-Object System.Drawing.Size(100, 20)

    $input2 = New-Object System.Windows.Forms.TextBox
    $input2.Text = $ProjektOrdner
    $input2.Location = New-Object System.Drawing.Point(150, 100)
    $input2.Size = New-Object System.Drawing.Size(300, 30)

    $input2.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $global:OK_pressed = $true  # Setze das Flag auf true
            $KundenOrdner = $input1.Text        
            $ProjektOrdner = $input2.Text
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
    $iconButton.Location = New-Object System.Drawing.Point(510, 60)
    $iconButton.Size = New-Object System.Drawing.Size(64, 64)
    $iconButton.Text = ""
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
            $KundenOrdner = $result.KundenOrdner
            $ProjektOrdner = $result.ProjektOrdner

            # Update der Fensterinhalte
            $input1.Text = $KundenOrdner
            $input2.Text = $ProjektOrdner

            # Dateinamen in die TextBox schreiben
            $Dateiliste | ForEach-Object {
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
        $global:KundenOrdner = $input1.Text        
        $global:ProjektOrdner = $input2.Text
        $form.Close() # Schließe das Fenster
        $global:OK_pressed= $true
    })

    # Elemente hinzufügen
    $form.Controls.AddRange(@($hintlabel, $label1, $input1, $label2, $input2, $label3, $outputBox, $iconButton, $cancelButton, $okButton))

    # Fenster anzeigen
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
CreateWindow

Write-host "OK=$OK_Pressed"
Write-host "K=$global:KundenOrdner"
Write-host "P=$global:ProjektOrdner"
Write-host "D=$global:Dateiliste ende"


# Überprüfe den Rückgabewert
if ($OK_Pressed -eq $false -or [string]::IsNullOrEmpty($global:KundenOrdner) -or [string]::IsNullOrEmpty($global:ProjektOrdner)) {
    [System.Windows.Forms.MessageBox]::Show("Kundenordner oder Projektordner leer oder Abbruch betätigt!", "Projekthelfer AV", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}


# Hauptroutine:
# Ordner erstellen und Dateien Kopieren.
#
#
# Beispiel: Der Kundenordner und der Projektordner aus den globalen Variablen
$KundenOrdner = $global:KundenOrdner
$ProjektOrdner = $global:ProjektOrdner
$Dateiliste = $global:Dateiliste

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
$KundenOrdnerPath = Join-Path -Path $basePath -ChildPath $KundenOrdner
Create-DirectoryIfNotExists -directoryPath $KundenOrdnerPath

# 2. Erstelle den Projektordner, falls er noch nicht existiert
$ProjektOrdnerPath = Join-Path -Path $KundenOrdnerPath -ChildPath $ProjektOrdner
Create-DirectoryIfNotExists -directoryPath $ProjektOrdnerPath

# 3. Erstelle die Unterordner CAD, CAM und QS im Projektordner, falls sie noch nicht existieren
$cadPath = Join-Path -Path $ProjektOrdnerPath -ChildPath "CAD"
$camPath = Join-Path -Path $ProjektOrdnerPath -ChildPath "CAM"
$qsPath = Join-Path -Path $ProjektOrdnerPath -ChildPath "QS"

Create-DirectoryIfNotExists -directoryPath $cadPath
Create-DirectoryIfNotExists -directoryPath $camPath
Create-DirectoryIfNotExists -directoryPath $qsPath

# 4. Kopiere die Dateien aus der Dateiliste in den Unterordner CAD
foreach ($file in $Dateiliste) {
    $destinationPath = Join-Path -Path $cadPath -ChildPath (Split-Path -Leaf $file)
    
    if (-not (Test-Path -Path $destinationPath)) {
        Copy-Item -Path $file -Destination $destinationPath
        Write-Host "Datei '$file' wurde nach '$destinationPath' kopiert."
    } else {
        Write-Host "Datei '$file' existiert bereits in '$destinationPath'."
    }
}

# 5. Abschlussmeldung anzeigen
$message = "Kundenordner: '$KundenOrdner & Projektordner: '$ProjektOrdner' inklusive Unterordner CAD CAM QS wurden erstellt (falls nicht vorhanden).`n`n"
$message += "Die folgenden Dateien wurden in den Ordner 'CAD' kopiert:`n`n"
foreach ($file in $Dateiliste) {
    $message += "`t$file`n"
}

[System.Windows.Forms.MessageBox]::Show($message, "Projekthelfer AV", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
