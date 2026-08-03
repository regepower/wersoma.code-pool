# Syntax der Verknüpfung zum Aufrufen:
# powershell.exe -noprofile  -ExecutionPolicy Bypass -command "& {N:\Download\PortableApps\Projekthelfer_AV.ps1 ($args -join ' ')}"
# Parameterblock: Erwartet die Eingabe als Zeichenkette von Dateipfaden
param (
    [string]$Paths  # Übergebene Dateipfade als String
)

# Beispiel-Eingabe ($Paths) für Test
#$Paths = "\\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0005_100122298nxz001_a.dxf \\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0006_100122298nxz001_a.pdf \\File01\Auslagerung\Kunden\Licon\20250121 Platte 1070035 Klotz 1070032\1070032\0007_100122298nxm000_01.stp"
#$Paths = "R:\Kunden\JD_Norman\20180524_VW Phönix\03c_103_021_aj_anlief-roh m Erstschn-step(2).stp R:\Kunden\JD_Norman\20180524_VW_Phönix\03C_103_021_BK-vorbearb_roh_20180515 info.pdf R:\Kunden\JD_Norman\20180524_VW_Phönix\03c_103_021_rohteil step.stp"




# Funktion zur Verarbeitung von Pfaden
function ProcessPaths {
    # Ergebnisliste für gültige Pfade
    $global:Dateiliste = @()

    # Prüfen, ob die Eingabe mit '\\' beginnt, was auf UNC-Pfade hinweist
    if ($Paths -like "\\*") {
        # UNC-Pfade analysieren ohne Regex
        $currentPath = ""
        $isInPath = $false  # Zustandsvariable, ob gerade ein Pfad gelesen wird

        # Eingabezeichenkette durchlaufen
        for ($i = 0; $i -lt $Paths.Length; $i++) {
            $char = $Paths[$i]

            # UNC-Pfad-Trenner "\\" erkennen
            if ($i -lt $Paths.Length - 1 -and $char -eq '\' -and $Paths[$i + 1] -eq '\') {
                if ($isInPath) {
                    # Pfad abschließen und zur Liste hinzufügen
                    $global:Dateiliste += $currentPath.Trim()
                    $currentPath = ""
                }
                $isInPath = $true  # Neuer Pfad beginnt
                $currentPath += "\\"  # Ersten Backslash hinzufügen
                $i++  # Nächsten Backslash überspringen
            } else {
                # Zeichen zum aktuellen Pfad hinzufügen
                if ($isInPath) {
                    $currentPath += $char
                }
            }
        }

        # Letzten Pfad hinzufügen, falls vorhanden
        if ($currentPath.Trim()) {
            $global:Dateiliste += $currentPath.Trim()
        }

    } else {
        # Verarbeitung für normale Pfade (kein UNC)
        $pattern = '([a-zA-Z]:\\(((?![<>:""/\\|?*]).)+((?<![ .])\\)?)*)(\s|$)'

        # Matches mit Regex extrahieren
        $matches = [regex]::Matches($Paths, $pattern)
        foreach ($match in $matches) {
            $global:Dateiliste += $match.Groups[1].Value.Trim()
        }
    }

    # Duplikate aus der Liste entfernen
    $global:Dateiliste = $global:Dateiliste | Sort-Object -Unique

    # Extrahiere Dateinamen aus der Dateiliste
    $global:DateiNamesListe = $global:Dateiliste | ForEach-Object { [System.IO.Path]::GetFileName($_) }

    # Extrahiere KundenOrdner aus dem ersten Eintrag (zwischen "\Kunden\" und dem nächsten Backslash)
    $global:KundenOrdner = $null
    if ($global:Dateiliste.Count -gt 0) {
        $firstPath = $global:Dateiliste[0]
        $kundenMatch = $firstPath -match '\\Kunden\\([^\\]+)'
        if ($kundenMatch) {
            $global:KundenOrdner = $matches[1]  # Nimm den Teil nach "\Kunden\" bis zum nächsten Backslash
        }
    }

    # Extrahiere ProjektOrdner aus dem ersten Eintrag (nur der letzte Unterordner vor dem Dateinamen)
    $global:ProjektOrdner = $null
    if ($global:Dateiliste.Count -gt 0) {
        $firstPath = $global:Dateiliste[0]
        $directoryName = [System.IO.Path]::GetDirectoryName($firstPath)
        if ($directoryName) {
            $global:ProjektOrdner = $directoryName.Split('\')[-1]  # Nimm den letzten Teil des Verzeichnispfads

            # Entferne das Präfix "yyyymmdd_" falls vorhanden und gültig
            if ($global:ProjektOrdner.Length -ge 9 -and $global:ProjektOrdner -match '^\d{8}_(.+)') {
                $datePart = $global:ProjektOrdner.Substring(0, 8)
                $remainingPart = $global:ProjektOrdner.Substring(9)

                # Prüfen, ob die ersten acht Zeichen ein gültiges Datum sind
                try {
                    [datetime]::ParseExact($datePart, 'yyyyMMdd', $null) | Out-Null
                    $global:ProjektOrdner = $remainingPart  # Präfix entfernen, da es ein gültiges Datum ist
                } catch {
                    # Kein gültiges Datum, nichts ändern
                }
            }
        }
    }
}

# Hauptaufruf der Funktion mit den übergebenen Parametern
ProcessPaths $Paths

# Installiere die erforderliche Assembly für Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Funktion zur Erstellung des Fensters
function CreateWindow {
    param (
        [array]$Paths,            # Eingabepfade als Array
        [string]$KundenOrdner,    # KundenOrdner
        [string]$ProjektOrdner    # ProjektOrdner
    )

    # Fenster erstellen
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Projekthelfer AV"
    $form.Size = New-Object System.Drawing.Size(640, 480)
    $form.StartPosition = "CenterScreen"

    # Label für den KundenOrdner
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "KundenOrdner:"
    $label1.Location = New-Object System.Drawing.Point(50, 30)
    $label1.Size = New-Object System.Drawing.Size(100, 30)

    # TextBox für den KundenOrdner
    $inputKundenOrdner = New-Object System.Windows.Forms.TextBox
    $inputKundenOrdner.Text = $KundenOrdner
    $inputKundenOrdner.Location = New-Object System.Drawing.Point(150, 30)
    $inputKundenOrdner.Size = New-Object System.Drawing.Size(300, 30)

    # Label für den ProjektOrdner
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "ProjektOrdner:"
    $label2.Location = New-Object System.Drawing.Point(50, 80)
    $label2.Size = New-Object System.Drawing.Size(100, 30)

    # TextBox für den ProjektOrdner
    $inputProjektOrdner = New-Object System.Windows.Forms.TextBox
    $inputProjektOrdner.Text = $ProjektOrdner
    $inputProjektOrdner.Location = New-Object System.Drawing.Point(150, 80)
    $inputProjektOrdner.Size = New-Object System.Drawing.Size(300, 30)

    # Label für die Liste der Dateien/Ordner
    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = "Übergebene Dateien/Ordner:"
    $label3.Location = New-Object System.Drawing.Point(50, 130)
    $label3.Size = New-Object System.Drawing.Size(300, 30)

    # TextBox für die Anzeige der Dateien/Ordner (mit Scrollbalken)
    $outputBox = New-Object System.Windows.Forms.TextBox
    $outputBox.Location = New-Object System.Drawing.Point(50, 160)
    $outputBox.Size = New-Object System.Drawing.Size(550, 200)
    $outputBox.Multiline = $true
    $outputBox.ScrollBars = "Both"  # Beide Scrollbalken (horizontal und vertikal)
    $outputBox.ReadOnly = $true
    $outputBox.WordWrap = $false  # Zeilenumbruch deaktivieren
    $outputBox.BackColor = [System.Drawing.Color]::White  # Hintergrundfarbe auf Weiß setzen


    # Dateinamen in die TextBox schreiben
    $Paths | ForEach-Object {
        $outputBox.AppendText("$_`r`n")
    }

    # **Button mit Explorer-Symbol hinzufügen**
    $iconButton = New-Object System.Windows.Forms.Button
    $iconButton.Location = New-Object System.Drawing.Point(510, 30)  # Button rechts von den Eingabefeldern
    $iconButton.Size = New-Object System.Drawing.Size(48, 48)  # Größe des Buttons auf 64x64 ändern
    $iconButton.Text = ""  # Text im Button entfernen

    # ToolTip-Objekt erstellen und mit dem Button verbinden
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.SetToolTip($iconButton, "Dateien neu auswählen")  # Hinweistext setzen

    # Symbol aus der DLL laden und setzen (z.B. Explorer-Icon)
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\explorer.exe")
    $iconButton.Image = $icon.ToBitmap()

    # Button-Click-Ereignis hinzufügen
    $iconButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show("Neuen Pfad auswählen", "Info")
    })

    # OK-Button hinzufügen
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(350, 380)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Add_Click({
        # Speichern der Eingabewerte in den globalen Variablen
        $global:KundenOrdner = $inputKundenOrdner.Text
        $global:ProjektOrdner = $inputProjektOrdner.Text

        # Falls das ProjektOrdner-Format yyyymmdd_xxxx vorliegt, wird der yyyymmdd_-Teil entfernt
        if ($global:ProjektOrdner -match '^\d{8}_(.+)') {
            $global:ProjektOrdner = $global:ProjektOrdner.Substring(9)  # Entfernt die ersten 9 Zeichen
        }

        [System.Windows.Forms.MessageBox]::Show("Eingabe 1: $global:KundenOrdner`nEingabe 2: $global:ProjektOrdner", "Eingaben gespeichert")
    })

    # Abbruch-Button hinzufügen
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Abbruch"
    $cancelButton.Location = New-Object System.Drawing.Point(220, 380)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Add_Click({
        $form.Close()  # Schließt das Fenster
    })

    # Elemente dem Fenster hinzufügen
    $form.Controls.Add($label1)
    $form.Controls.Add($inputKundenOrdner)
    $form.Controls.Add($label2)
    $form.Controls.Add($inputProjektOrdner)
    $form.Controls.Add($label3)
    $form.Controls.Add($outputBox)
    $form.Controls.Add($iconButton)  # Hier wird der Explorer-Button hinzugefügt
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    # Fenster anzeigen
    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}

# Hauptlogik: Erzeuge das Fenster mit den übergebenen Werten
CreateWindow -Paths $DateiListe -KundenOrdner $KundenOrdner -ProjektOrdner $ProjektOrdner
