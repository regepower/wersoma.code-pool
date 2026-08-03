#Requires AutoHotkey v2.0

filePath := "N:\Sicherung_Maschinen\BACKUP_TOOLS\StammWkzSatz_Ermitteln.xlsm"
macroName := "Aktualisiere"

try {
    xl := ComObject("Excel.Application")
    xl.Visible := true
    wb := xl.Workbooks.Open(filePath)

    Sleep 1000  ; Wartezeit zum Laden der Datei

    xl.Run(macroName)

    ; Optional: Datei schließen ohne zu speichern
    ; wb.Close(false)
    ; xl.Quit()
}
catch {
    MsgBox "Es ist ein Fehler beim Zugriff auf Excel oder das Makro aufgetreten."
}
