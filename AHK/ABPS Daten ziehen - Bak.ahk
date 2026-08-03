#Requires AutoHotkey v2.0
SetTitleMatchMode("2")
CoordMode("Pixel", "Client")
CoordMode("Mouse", "Client")

; Prüfen, ob der Prozess ABPS.exe läuft
if (ProcessExist("ABPS.exe")) {
    ;MsgBox "Der Prozess ABPS.exe läuft."

    ; Prüfen, ob ein Fenster mit dem Teiltitel "ABPS" existiert
    if (WinExist(" ABPS  -  Nutzer: ")) {  ; Leerzeichen vor "ABPS" um Teiltitel zu suchen


        ; Temporäre dateien löschen
        FileDelete "N:\99_Temporaeres_Zeug\gfu_*.xlsx"

        ; Fenster aktivieren
        WinActivate " ABPS  -  Nutzer: "
        Sleep 300  ; Wartezeit, um sicherzustellen, dass das Fenster aktiviert ist

	; Fenter Schließen
	Send "^{F4}"		; Ctrl F4
        Sleep 300

        ; Tastenkombination Alt + E senden
        Send "!e"		; Alt E
        Sleep 300

        ; Einmal Cursor nach unten und Enter drücken
        Send "{Down}"
        Sleep 100
        Send "{Enter}"
        Sleep 300  ; Kurz warten
        Send "{Enter}"
        Sleep 500  ; Kurz warten

        ; Tastenkombination Alt + F senden
        Send "!f"		; Alt F
        Sleep 500

        ; Einmal Cursor nach unten und Enter drücken
        ;Send "{Down}"
        ;Sleep 500
        Send "{Enter}"
        Sleep 300  ; Kurz warten

        ; Auf ein bestimmtes Pixel warten, bis es schwarz wird
        PixelSearchWait(0, 170, 64, 190, 0x000000, 0)
	; Mausklick auf die gleiche Position
	Click 10, 150
        Sleep 300  ; Kurz warten
        ; Alt + Backspace drücken
        Send "!{Backspace}"		; ALt Backspace
        WindowWait("Speichern unter",1)
        ; Dateinamen in fensterschreiben
	Send "N:\99_Temporaeres_Zeug\gfu_Abarbeitungsstand.xlsx{Enter}"

; AUF EXCEL WARTEN
	WindowWait("gfu_Abarbeitungsstand(\.xlsx)? - Excel", "RegEx")
        ;Sleep 1000  ; Kurz warten
	;WinClose " gfu_Abarbeitungsstand"
        Sleep 1000  ; Kurz warten
	Send "{ALT}{F4}"		; ALt F4

; WEITER IN ABPS
        ; Fenster wieder aktivieren
        WinActivate " ABPS  -  Nutzer: "
        Sleep 300  ; Wartezeit, um sicherzustellen, dass das Fenster aktiviert ist
	Send "^{F4}"		; Ctrl F4
	Sleep 300  ; Kurz warten
	Send "!u"
	Sleep 300  ; Kurz warten
	Send "{Down}"
	Sleep 100  ; Kurz warten
	Send "{Right}"
	Sleep 300  ; Kurz warten
        Send "{Enter}"
	;
	Sleep 300  ; Kurz warten
        PixelSearchWait(0, 135, 16, 145, 0x000000, 9)
	; Mausklick auf die gleiche Position
	Click 0, 140
        Sleep 500  ; Kurz warten
        ; Alt + Backspace drücken
        Send "!{Backspace}"		; ALt Backspace
        WindowWait("Speichern unter",1)
	Send "N:\99_Temporaeres_Zeug\gfu_Fertigungsauftrag.xlsx{Enter}"

; AUF EXCEL WARTEN
	WindowWait("gfu_Fertigungsauftrag(\.xlsx)? - Excel", "RegEx")
	WinActivate " gfu_Fertigungsauftrag"
	Sleep 1000  ; Kurz warten
	Send "!{F4}"		; ALt F4

    } else {
        MsgBox("Kein Fenster mit dem Teiltitel 'ABPS' gefunden.", "Fehler", "Iconx")
    }
} else {
    MsgBox("ABPS muss laufen!!!", "Fehler", "Iconx")
}


ExitApp

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
