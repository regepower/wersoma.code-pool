; Zieht die Stammdaten Personal aus ABPS in Excel
; Daten liegen under Temporäres Zeug
; Skript immmer!!! als UTF 8 mit BOM speichern !!!

#Requires AutoHotkey v2.0
SetTitleMatchMode("2")
CoordMode("Pixel", "Client")
CoordMode("Mouse", "Client")
SetKeyDelay 0, 1

; Prüfen, ob der Prozess ABPS.exe läuft
if (ProcessExist("ABPS.exe")) {

    ; Prüfen, ob ein Fenster mit dem Teiltitel "ABPS" existiert
    if (WinExist(" ABPS  -  Nutzer: ")) {  ; Leerzeichen vor "ABPS" um Teiltitel zu suchen

	WinMaximize " ABPS  -  Nutzer: "	; Fenter maximieren um die Positionen der Pixel zu finden

        ; Temporäre dateien löschen
        FileDelete "N:\99_Temporäres_Zeug\gfu_*.xlsx"	; Temporäre Dateien löschen damit keine Warnungen kommen

        ; Fenster aktivieren
        WinActivate " ABPS  -  Nutzer: "
        Sleep 300  ; Wartezeit, um sicherzustellen, dass das Fenster aktiviert ist


	; Oberes Fenster Fenter Schließen nur zur Sicherheit falls
    	MenuSelect "ABPS  -  Nutzer: ",, "Fenster", "2&"        ; 2& steht für "Fenster schließen"
        Sleep 300
    	Send "{Enter}"		; Enter drücken um das Popupfenster zu schließen
        Sleep 600  ; Kurz warten
     	MenuSelect "ABPS  -  Nutzer: ",, "Stammdaten", "8&", "1&"  ; Stammdaten -> Zeiterfassung -> Personal


	ControlWait("TDBGrid1")
	ControlGetPos &AusX, &AusY,,, "TDBGrid1"	; Position des Rasters suchen falls Fenster Abarbeitungsstand nicht im Vollbild
        ; Auf ein bestimmten Pixelnereich  warten, bis schwarz wird
        PixelSearchWait(AusX, AusY+30, AusX+16, AusY+46 , 0x000000, 0)
	; Grid aktivieren damit Tastenkombi gesendet werden kann
	ControlFocus "TDBGrid1"
        Sleep 300  ; Kurz warten
        ; Alt + Backspace drücken
        Send "!{Backspace}"		; ALt Backspace
        WindowWait("Speichern unter",1)
        ; Dateinamen in fenster schreiben
	SendText "N:\99_Temporäres_Zeug\gfu_Export.xlsx"
	Send "{Enter}"

; AUF EXCEL WARTEN
	WindowWait("gfu_Export(\.xlsx)? - Excel", "RegEx")
	SetTitleMatchMode "RegEx"  	; REGEX
        Sleep 300  ; Kurz warten
	Send "!{F4}"		; ALt F4
	;Winclose("gfu_Export(\.xlsx)? - Excel")
	SetTitleMatchMode 2  	; Teilstring
        Sleep 300  ; Kurz warten

    } else {
        MsgBox("Kein Fenster mit dem Teiltitel 'ABPS' gefunden.", "Fehler", "Iconx")
    }
} else {
    MsgBox("ABPS muss laufen!!!", "Fehler", "Iconx")
}

; --- Excel-Instanz holen ---
xl := ComObjActive("Excel.Application")
if !IsObject(xl) {
    MsgBox("Fehler: Keine laufende Excel-Instanz gefunden.")
    ExitApp
}

ExitApp
; --- Durch alle offenen Workbooks gehen ---
wb := ""
for workbook in xl.Workbooks {
    if (workbook.Name = "Abarbeitung Planung" || workbook.Name = "Abarbeitung Planung.xlsm") {
        wb := workbook
        break
    }
}

; --- Wenn Mappe gefunden: VBA-Makro aufrufen ---
if (IsObject(wb)) {
        ; Makro aufrufen
        wb.Activate
        wb.Application.Run("ImportiereDaten_Fortsetzung")
}
ExitApp

; ----------------------------------------------------------------------------
PixelWait(x, y, farbe, timeoutSekunden := 30) {
    ; Hinweisfenster anzeigen
    hwnd := WinExist("A")
    infoGui := Gui("-SysMenu +AlwaysOnTop +Owner" hwnd, "Bitte warten")
    infoGui.Add("Text",, "Warte auf Daten...")
    infoGui.Show("w300 h100 NoActivate")

    start := A_TickCount
    while (A_TickCount - start < timeoutSekunden * 1000) {
        color := PixelGetColor(x, y)
        if (color = farbe) {
            infoGui.Destroy()
            return true
        }
        Sleep(500)
    }

    infoGui.Destroy()
    MsgBox("Fenster nicht gefunden.", "Fehler", "Iconx")
    ExitApp()
}

PixelSearchWait(x1, y1, x2, y2, farbe, toleranz, timeoutSekunden := 30) {
    ; Hinweisfenster anzeigen
    hwnd := WinExist("A")
    infoGui := Gui("-SysMenu +AlwaysOnTop +Owner" hwnd, "Bitte warten")
    infoGui.Add("Text",, "Warte auf Daten...")
    infoGui.Show("w300 h100 NoActivate")

    start := A_TickCount
    while (A_TickCount - start < timeoutSekunden * 1000) {
        if PixelSearch(&Px, &Py,x1, y1, x2, y2, farbe, toleranz) {
            infoGui.Destroy()
            return true
        }
        Sleep(500)
    }

    infoGui.Destroy()
    MsgBox("Pixel nicht gefunden.", "Fehler", "Iconx")
    ExitApp()
}


WindowWait(fensterTitel, MatchMode , timeoutSekunden := 30) {
    ; Hinweisfenster anzeigen
    hwnd := WinExist("A")
    infoGui := Gui("-SysMenu +AlwaysOnTop +Owner" hwnd, "Bitte warten")
    infoGui.Add("Text",, "Warte auf Fenster '" fensterTitel "'...")
    infoGui.Show("w300 h100 NoActivate")

    SetTitleMatchMode MatchMode
    start := A_TickCount
    while (A_TickCount - start < timeoutSekunden * 1000) {
        if (WinExist(fensterTitel)) {
            infoGui.Destroy()
            WinActivate fensterTitel
            SetTitleMatchMode 2
            return true
        }
        Sleep(500)
    }

    infoGui.Destroy()
    MsgBox("Fenster '" fensterTitel "' nicht gefunden.", "Fehler", "Iconx")
    ExitApp()
}


ControlWait(Item, timeoutSekunden := 5) {
    hwnd := WinExist("A")
    start := A_TickCount
    while (A_TickCount - start < timeoutSekunden * 1000) {
        try {
            if ControlGetHwnd(Item,hwnd) {
                return true
            }
        }
        Sleep(500)
    }
    MsgBox("Control nicht gefunden.", "Fehler", "Iconx")
    ExitApp()
}
