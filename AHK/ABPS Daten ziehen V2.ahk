; Zieht die Daten Abarbeitungsstand und Fertigungsauftrag aus ABPS in Excel
; Daten liegen under Temporäres Zeug
; Skript immmer!!! als UTF 8 mit BOM speichern !!!

#Requires AutoHotkey v2.0
SetTitleMatchMode("2")
CoordMode("Pixel", "Client")
CoordMode("Mouse", "Client")

; Prüfen, ob der Prozess ABPS.exe läuft
if (ProcessExist("ABPS.exe")) {

    ; Prüfen, ob ein Fenster mit dem Teiltitel "ABPS" existiert
    if (WinExist("ABPS  -  Nutzer: ")) {  ; Leerzeichen vor "ABPS" um Teiltitel zu suchen

	WinMaximize "ABPS  -  Nutzer: "	; Fenter maximieren um die Positionen der Pixel zu finden

        ; Temporäre dateien löschen
        FileDelete "N:\99_Temporäres_Zeug\gfu_*.xlsx"	; Temporäre Dateien löschen damit keine Warnungen kommen



        ; Fenster aktivieren
        WinActivate "ABPS  -  Nutzer: "
        Sleep 300  ; Wartezeit, um sicherzustellen, dass das Fenster aktiviert ist


	; Oberes Fenster Fenter Schließen nur zur Sicherheit falls
    MenuSelect "ABPS  -  Nutzer: ",, "Fenster", "2&"        ; 2& steht für "Fenster schließen"
        Sleep 300
    Send "{Enter}"		; Enter drücken um das Popupfenster zu schließen
        Sleep 300  ; Kurz warten
     MenuSelect "ABPS  -  Nutzer: ",, "Fertigung", "1&"  ; Fertigung -> Abarbeitungsstand



     ; Auf ein bestimmten Pixelnereich  warten, bis schwarz wird
        PixelSearchWait(0, 170, 64, 190, 0x000000, 0)
	Send "^{F4}"		; Ctrl F4
        Sleep 300

        ; -> Menu Fenster
        Send "!e"		; Alt E
        Sleep 300

        ; -> Alle Fenster Schließen
        Send "{Down}"
        Sleep 100
        Send "{Enter}"
        Sleep 300  ; Kurz warten

	; -> Falls Warnung existiert "Ja" drücken
        Send "{Enter}"
        Sleep 500  ; Kurz warten

        ; -> Menu Fertigung
        Send "!f"		; Alt F
        Sleep 500

        ; -> Abarbeitungsstand
        ;Send "{Down}"
        ;Sleep 500
        Send "{Enter}"
        Sleep 300  ; Kurz warten

        ; Auf ein bestimmten Pixelnereich  warten, bis schwarz wird
        PixelSearchWait(0, 170, 64, 190, 0x000000, 0)
	; Mausklick auf die gleiche Position
	Click 10, 150
        Sleep 300  ; Kurz warten
        ; Alt + Backspace drücken
        Send "!{Backspace}"		; ALt Backspace
        WindowWait("Speichern unter",1)
        ; Dateinamen in fenster schreiben
	SendInput "N:\99_Temporäres_Zeug\gfu_Abarbeitungsstand.xlsx{Enter}"

; AUF EXCEL WARTEN
	WindowWait("gfu_Abarbeitungsstand(\.xlsx)? - Excel", "RegEx")
    Send "!{F4}"  ; Alt+F4
    Sleep 500
; WEITER IN ABPS
        ; Fenster wieder aktivieren
        WinActivate " ABPS  -  Nutzer: "
        Sleep 300  ; Wartezeit, um sicherzustellen, dass das Fenster aktiviert ist

	; Fenster Abarbeitungsstand schließen
	Send "^{F4}"		; Ctrl F4
	Sleep 300  ; Kurz warten

	; -> Menu Auftragsbearbeitung
	Send "!u"
	Sleep 300  ; Kurz warten

 	; -> Fertigungsauftrag
	Send "{Down}"
	Sleep 100  ; Kurz warten
	Send "{Right}"
	Sleep 300  ; Kurz warten
        Send "{Enter}"
	Sleep 300  ; Kurz warten


        ; Auf ein bestimmten Pixelnereich  warten, bis schwarz wird
        PixelSearchWait(0, 135, 16, 145, 0x000000, 9)
	; Mausklick auf die gleiche Position
	Click 0, 140
        Sleep 500  ; Kurz warten
        ; Alt + Backspace drücken
        Send "!{Backspace}"		; ALt Backspace
        WindowWait("Speichern unter",1)
	SendInput "N:\99_Temporäres_Zeug\gfu_Fertigungsauftrag.xlsx{Enter}"

; AUF EXCEL WARTEN
	WindowWait("gfu_Fertigungsauftrag(\.xlsx)? - Excel", "RegEx")
    Send "!{F4}"  ; Alt+F4
    Sleep 500




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
