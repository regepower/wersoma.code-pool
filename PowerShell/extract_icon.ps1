# Windows API-Funktion einbinden, um Icons aus DLLs zu extrahieren
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class ExtractIconHelper {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern int ExtractIconExW(string lpszFile, int nIconIndex, out IntPtr phiconLarge, out IntPtr phiconSmall, uint nIcons);
}
"@

# Funktion, um das Icon zu extrahieren
function Get-IconFromDLL {
    param (
        [string]$dllPath,
        [int]$iconIndex
    )

    # Zeiger für das große und kleine Icon
    $largeIconPtr = [IntPtr]::Zero
    $smallIconPtr = [IntPtr]::Zero

    # Extrahiert das Icon mit dem angegebenen Index
    [ExtractIconHelper]::ExtractIconExW($dllPath, $iconIndex, [ref]$largeIconPtr, [ref]$smallIconPtr, 1)

    # Wenn das große Icon extrahiert wurde, erstellen wir ein Icon-Objekt
    if ($largeIconPtr -ne [IntPtr]::Zero) {
        return [System.Drawing.Icon]::FromHandle($largeIconPtr)
    }
    return $null
}

# Funktion, um das Fenster zu erstellen
function Create-Window {
    # Fenster erstellen
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Projekthelver AV"
    $form.Size = New-Object System.Drawing.Size(640, 480)  # Fenstergröße auf 640x480 setzen
    $form.StartPosition = "CenterScreen"

    # Eingabefelder für KundenPfad und KundenProjekt
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "Eingabe 1 (KundenPfad):"
    $label1.Location = New-Object System.Drawing.Point(50, 30)
    $label1.Size = New-Object System.Drawing.Size(150, 20)

    $input1 = New-Object System.Windows.Forms.TextBox
    $input1.Location = New-Object System.Drawing.Point(200, 30)
    $input1.Size = New-Object System.Drawing.Size(300, 30)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "Eingabe 2 (KundenProjekt):"
    $label2.Location = New-Object System.Drawing.Point(50, 70)
    $label2.Size = New-Object System.Drawing.Size(150, 20)

    $input2 = New-Object System.Windows.Forms.TextBox
    $input2.Location = New-Object System.Drawing.Point(200, 70)
    $input2.Size = New-Object System.Drawing.Size(300, 30)

    # TextBox für den Textoutput
    $outputBox = New-Object System.Windows.Forms.TextBox
    $outputBox.Location = New-Object System.Drawing.Point(50, 150)
    $outputBox.Size = New-Object System.Drawing.Size(550, 200)
    $outputBox.Multiline = $true
    $outputBox.ScrollBars = "Both"  # Beide Scrollbalken
    $outputBox.ReadOnly = $true

    # OK-Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(150, 380)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Add_Click({
        $form.Close()  # Schließt das Fenster
    })

    # Abbruch-Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Abbruch"
    $cancelButton.Location = New-Object System.Drawing.Point(300, 380)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Add_Click({
        $form.Close()  # Schließt das Fenster
    })

    # Button mit Icon (Extrahieren des 5. Icons aus der wiashext.dll)
    $icon = Get-IconFromDLL "C:\Windows\System32\wiashext.dll" 4
    if ($icon) {
        $iconButton = New-Object System.Windows.Forms.Button
        $iconButton.Location = New-Object System.Drawing.Point(470, 30)  # Button rechts von den Eingabefeldern
        $iconButton.Size = New-Object System.Drawing.Size(128, 128)  # Größe des Buttons auf 128x128 ändern
        $iconButton.Text = ""  # Text im Button entfernen
        $iconButton.Image = $icon.ToBitmap()

        # ToolTip-Objekt erstellen und mit dem Button verbinden
        $toolTip = New-Object System.Windows.Forms.ToolTip
        $toolTip.SetToolTip($iconButton, "Dateien neu auswählen")  # Hinweistext setzen

        # Button-Click-Ereignis hinzufügen
        $iconButton.Add_Click({
            [System.Windows.Forms.MessageBox]::Show("Neuen Pfad auswählen", "Info")
        })

        # Button zum Fenster hinzufügen
        $form.Controls.Add($iconButton)
    } else {
        Write-Host "Das Icon konnte nicht geladen werden."
    }

    # Elemente zum Fenster hinzufügen
    $form.Controls.Add($label1)
    $form.Controls.Add($input1)
    $form.Controls.Add($label2)
    $form.Controls.Add($input2)
    $form.Controls.Add($outputBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    # Fenster anzeigen
    $form.ShowDialog()
}

# Fenster erstellen
Create-Window
