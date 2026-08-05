; Reihenfolge so ungefähr
; 1. Prüfen ob das Aktive Fenster "ahk_class NX_SURFACE_WND_DIALOG" und der Fenstertitel "Kegelsenken" ist sonst raus
; 2. ClassNN:	Edit1 Text:	"Haupt : Anzeige{Enter}" eingeben
; 3. ClassNN:	Button5 Text  "Formelementgeometrie" prüfen und wenn ja Klicken sonst abbrechen
; 4. Warten auf fenster "ahk_class NX_SURFACE_WND_DIALOG" und den Fenstertitel "Formelementgeometrie"
; 5. den Text aus ClassNN:	Edit24 holen und in Variable Fas_D schreiben
; 6. ClassNN:	Button123 klicken
; 7. Warten auf Fenster mit Fenstertitel "Kegelsenken"
; 8. ClassNN:	Edit1 Text:	"Vorschübe und Drehzahlen : Vorschübe und Drehzahlen{Enter}" eingeben
; 9. Intern variable rechnen: Fas_vc = 150000 / Fas_D / PI()
; 10. Fass_vc in ClassNN:	Edit8 eintragen
; 11. ClassNN:	Button13 klicken
; 12. den wert 0.1 in ClassNN:	Edit4 eintragen.
; 13. ClassNN:	Button7 klicken
#Requires AutoHotkey v2.0
SetTitleMatchMode 2
SetKeyDelay 1, 10

;^!ä:: ; Strg + Alt + ä
{

    ; === Schritt 1: Fenster Kegelsenken prüfen ===


    WinTitle := "Kegelsenken"

    foundHwnd := WinExist(WinTitle)
    if !foundHwnd {  ;
        MsgBox "Fenster Kegelsenken nicht gefunden. Skript wird beendet."
        Return
    }

    WinActivate(foundHwnd)
    sleep 100


    ; === Schritt 2: Edit1 Text eingeben um auf Haupt zu switchen ===
    ControlClick "Edit1", WinTitle
    if (WaitForControl("Edit1", foundHwnd, 5)== false) {
        MsgBox "Edit1 (Haupt : Anzeige) nicht gefunden. Skript wird beendet."
        Return
    }
    ControlSetText "Haupt : Anzeige", "Edit1", WinTitle
    ControlSend  "{Enter}", "Edit1",WinTitle
    sleep 500
    ControlSetText "", "Edit1", WinTitle
    ControlSend  "{Enter}", "Edit1",WinTitle
    sleep 100

    ; === Schritt 3: Formelementgeometrie Button klicken ===
    ControlName := GetControlByText("Formelementgeometrie auswählen oder bearbeiten",foundHwnd ,0 ,5)
   if (ControlName = "") {
        MsgBox "Kein Control mit Text <Formelementgeometrie auswählen...> gefunden."
        Return
    }

    ControlClick ControlName, WinTitle


    ; === Schritt 4: Warten auf Fenster mit Teilstring im Titel ===
    foundFormelHwnd := Winwait("Formelementgeometrie",,5)
    if !foundFormelHwnd {  ;
        MsgBox "Fenster Formelementgeometrie nicht gefunden. Skript wird beendet."
        ExitApp
    }

    sleep 100

    ; === Schritt 5: Text aus dem Control nach dem mit dem Text "Senkungsdurchm."" holen ===
    ControlName := GetControlByText("Senkungsdurchm.",foundHwnd,1 ,5)
   if (ControlName = "") {
        MsgBox "Kein Control mit <Senkungsd.> gefunden."
        Return
    }

    Fas_D := ControlGetText(ControlName, foundFormelHwnd, 1)
    if (Fas_D = "") {
        MsgBox "Fasdurchmesser nicht gefunden. Skript wird beendet."
        Return 
    }

    ; === Schritt 6: den Abbrechen Button klicken
    ControlName := GetControlByText("Abbrechen",foundFormelHwnd,0 ,5, true) ; Suche rückwärts nach dem Abbrechen Button
    if (ControlName = "") {
        MsgBox "Kein Control mit <Abbrechen> gefunden."
    Return
    }
    ControlClick ControlName,  foundFormelHwnd

    ; === Schritt 7: Warten auf Fenster mit Kegelsenkenl ===
    foundHwnd := Winwait(WinTitle,,5)
    if !foundHwnd {
        MsgBox "Fenster 'Kegelsenken' nicht gefunden. Skript wird beendet."
        ExitApp
    }

    ; === Schritt 8: Edit1 neuen Text eingeben ===
    ControlSetText "Vorschübe und Drehzahlen : Vorschübe und Drehzahlen", "Edit1", foundHwnd
    ControlSend  "{Enter}", "Edit1",foundHwnd
    sleep 500
    ControlSetText "", "Edit1", WinTitle
    ControlSend  "{Enter}", "Edit1",WinTitle
    
    ; === Schritt 9: Fas_vc berechnen ===
    Fas_D_num := Fas_D + 0
    if (Fas_D_num = 0) {
        MsgBox "Fas_D ist ungültig. Skript wird beendet."
        ExitApp
    }
    Fas_n := round(150000 / Fas_D_num / 3.141592653589793,0)

    ; === Schritt 10: Spindeldrehzahl +1 Edit control finden und Text eintragen ===
    sleep 300
    ControlName := GetControlByText("Spindeldrehzahl (U/min)",foundHwnd,1 ,5)
    if (ControlName = "") {
        MsgBox "Kein Control mit <Spindeldrehzahl (U/min.> gefunden."
        Return
    }

    ; === Schritt 11: Fas_n in Spindeldrehzahl eintragen ===
    SetKeyDelay 10, 10  ; ; Setze die Tastaturverzögerung auf 10ms wegen buggy Eingabe
    ControlFocus ControlName, foundHwnd
    ControlSetText "", ControlName, foundHwnd
    ControlSend Fas_n, ControlName,  foundHwnd
    ControlSend "{ENTER}", ControlName,  foundHwnd
    sleep 300

    ; === Schritt 12: Berechnen hinter Drehzahl (offset+12) klicken ===
    ControlName := GetControlByText("Spindeldrehzahl (U/min)",foundHwnd,12 ,5)
    ControlClick ControlName, foundHwnd
    sleep 300

    ; === Schritt 13: fz Wert 0.1 in Vorschub pro Zahn eintragen ===
    ControlName := GetControlByText("Vorschub pro Zahn",foundHwnd,1 ,5)
    if (ControlName = "") {
        MsgBox "Kein Control mit <Vorschub pro Zahn.> gefunden."
        Return
    }
    sleep 300
    ControlFocus ControlName, foundHwnd
    ;ControlSetText "0.0", ControlName, foundHwnd
    ControlSend "0.1{ENTER}",ControlName,  foundHwnd

    ; === Schritt 13: Berechnen  (offset+12) klicken ===
    sleep 300
    ControlName := GetControlByText("Vorschub pro Zahn",foundHwnd ,12 ,5)
    ControlClick ControlName, foundHwnd


   TrayTip "Vc150 für D" Round(Fas_D,3) " eingetragen."
    sleep 3000
    return 

}

;// Helper functions

; ** FUER NX SURFACE WND DIALOG -> Da die Controls dynamisch gebaut werden müssen wir teilweise warten bis die Buttons da sind
; ** Warten auf Control, das in einem bestimmten Fenster existiert 
WaitForControl(ControlName, hwnd, Timeout := 5) {
    StartTime := A_TickCount
    while (A_TickCount - StartTime < Timeout * 1000) {
        try {
            if ControlGetHwnd(ControlName, hwnd) {
                Sleep(100)
                return true
            }
        } catch Error as e {
            ; Fehler beim Zugriff auf das Control, ignoriere und versuche weiter
        }
        Sleep(100)
    }
    return false
}

; ** Sucht ein Control mit einem bestimmten Text in einem bestimmten Fenster
; ** Gibt den ClassNN-Namen des Controls bei Index 0 bezw. den Namen des gesuchten Controls mit offset zurück,
; ** wenn gefunden, sonst leer. REverse sucht Rückwärts durch die Controls.
; ** Hwnd ist das Fenster, in dem gesucht wird.
GetControlByText(text, Hwnd, Offset := 0, timeout := 5000, reverse := false) {
    startTime := A_TickCount

    Loop {
        controls := WinGetControls(Hwnd)

        foundIndex := 0

        if reverse {
            ; Rückwärts durchlaufen
            for index, controlName in controls.Length ? controls : [] {
                realIndex := controls.Length - index + 1
                ctrlText := ControlGetText(controls[realIndex], Hwnd)
                if InStr(ctrlText, text) {
                    foundIndex := realIndex
                    break
                }
            }
        } else {
            ; Vorwärts durchlaufen
            for index, controlName in controls {
                ctrlText := ControlGetText(controlName, Hwnd)
                if InStr(ctrlText, text) {
                    foundIndex := index
                    break
                }
            }
        }

        if (foundIndex) {
            targetIndex := foundIndex + Offset
            if (targetIndex >= 1 && targetIndex <= controls.Length)
                return controls[targetIndex] ; <-- gibt den ControlNamen zurück
            else
                return "" ; Offset außerhalb des Bereichs
        }

        if (A_TickCount - startTime > timeout * 1000)
            return ""

        Sleep 100
    }
}