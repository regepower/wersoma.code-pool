; Neue Version
#Requires AutoHotkey v2.0
;#Persistent
SetTitleMatchMode("2")
CoordMode("Pixel", "Client")
CoordMode("Mouse", "Client")



MsgBox A_Args[1]


; Schritt 1: RDP-Verbindung starten
Run('"' A_Desktop '\GFU.rdp"')


; Schritt 2: Warten auf Abmeldefenster und Passwort eingeben
WinWaitActive("Windows-Sicherheit", ,5) ; Fenstername ggf. anpassen


;ControlSend "wersoma94_1{Enter}",, "Windows-Sicherheit"
; Funktioniert nicht mehr 25H2

;Send("{wersoma94_2{Enter}") ; Passwort eingeben

;Sleep(1000)
;
;SendEvent("wersoma94{Enter}")

;Send "{Tab}{Tab}ende"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   old_clip := ClipboardAll()  ; Zwischenablage speichern
    A_Clipboard := "wersoma94"
    ;Send "^v"
    Sleep 500  ; Kurz warten, bis Strg+V verarbeitet wurde
    A_Clipboard := old_clip  ; Vorherige Zwischenablage wiederherstellen


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




WinWaitActive("GFU - 10.4.2.54 - Remotedesktopverbindung") ; Warten auf RDP Fenster
; Schritt 3: Auf Pixel-Farbe warten
PixelWait(160, 80, 0xFFFF80)

; Schritt 4: Daten im RDP-Fenster eingeben
Send("250771{Enter}")

ExitApp

PixelWait(x, y, farbe, timeoutSekunden := 30) {
    ; Hinweisfenster anzeigen
    hwnd := WinExist("A")
    infoGui := Gui("-SysMenu +AlwaysOnTop +Owner" hwnd, "Bitte warten")
    infoGui.Add("Text",, "Warte auf Remote...")
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

