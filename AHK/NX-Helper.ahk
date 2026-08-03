; ** Skript um ein Menu bei NX im Operationsmenu anzuzeigen
; ** Bei Countersinking Fenster Kegelsenken werden die Schniitwerte errechnet
; ** Basierend auf dem Senkdurchmesser

;#Requires AutoHotkey v2.0
TrayTip "Starte im Hintergrund...", "Wersoma NX-Helper"
#HotIf WinActive("ahk_class NX_SURFACE_WND_DIALOG") 
    && ((title := WinGetTitle("A")) && (InStr(title, "Kegelsenken") || InStr(title, "Hss Drilling")))
    && (MouseGetPos(,, &winUnderMouse), WinActive(winUnderMouse))

; Menüeinträge und Labels für verschiedene Fenster
menuItems := Map(
    "Kegelsenken", [
        ["Setze: Vc150 / fz0.1  Stahl/Guss", KegelMenuHandler],
        ["Setze: Vc80  / fz0.06 Stahl vergütet", KegelMenuHandler],
        ["Setze: Vc180 / fz0.1  Alu", KegelMenuHandler],
        ["Setze: Vc65  / fz0.04 Inox", KegelMenuHandler]
    ],
    "Hss Drilling", [
        ["HSS Pilot 30", HssMenuHandler],
        ["HSS Pilot 25", HssMenuHandler]
    ]
)

getMenuForTitle(title) {
    for k, v in menuItems
        if InStr(title, k)
            return v
    return []
}

RButton::
{
    SetTitleMatchMode 2 ; Teilweise Übereinstimmung
    MouseGetPos(,, &foundHwnd, &control)
    showMenu := false
    if (control != "") {
        ControlGetClassNN(control, foundHwnd)
        classNN := ControlGetClassNN(control, foundHwnd)
        if (InStr(classNN, "Edit") = 0 && InStr(classNN, "Afx:") = 0) {
            showMenu := true
        } else {
            Send "{RButton}"
        }
    } else {
        showMenu := true
    }
    if (showMenu) {
        WinTitle := WinGetTitle(foundHwnd)
        items := getMenuForTitle(WinTitle)
        if items.Length {
            MyContext := Menu()
            for entry in items
                MyContext.Add(entry[1], entry[2])
            MyContext.Show()
        }
    }
}
#HotIf

KegelMenuHandler(MenuText,MenuNummer,*) {

    if (MenuNummer = 1) { ; Stahl/Gus
        Fas_vc := 150 
        Fas_fz := 0.1
    } else if (MenuNummer = 2) { ; Stahl vergütet
        Fas_vc := 80 
        Fas_fz := 0.06
    } else if (MenuNummer = 3) { ; Alu
        Fas_vc := 180 
        Fas_fz := 0.1
    } else if (MenuNummer = 4) { ; Inox
        Fas_vc := 65 
        Fas_fz := 0.04
    } else {
        MsgBox("Unbekannte Option: " MenuText)
        return
    }

    { ;// Hauptfunktion T3 T3_Schnittwerte
    ; === Schritt 2: Edit1 Text eingeben um auf Haupt zu switchen ===
    ; === Schritt 1: Fenster Kegelsenken prüfen ===

        SetTitleMatchMode 2 ; Teilweise Übereinstimmung
        WinTitle := "Kegelsenken"
        WinTitle2 := "Formelementgeometrie"
        foundHwnd := WinExist(WinTitle)

        if !foundHwnd {  ;
            MsgBox "Fenster Kegelsenken nicht gefunden. Skript wird beendet."
            Return
        }
        ; === Schritt 1a: Bitte warten Fenster anzeigen ===
        BitteWartenGui := Gui("+Owner" foundHwnd " +Disabled -SysMenu -MinimizeBox -MaximizeBox", "Bitte warten")
        BitteWartenGui.SetFont("s12", "Segoe UI")
        BitteWartenGui.AddText("w200 h40 Center", "Bitte warten ...")
        BitteWartenGui.Show("NoActivate Center")

        WinActivate(foundHwnd)
        
        ControlClick "Edit1", WinTitle
        if (WaitForControl("Edit1", foundHwnd, 5)== false) {
            MsgBox "Edit1 (Haupt : Anzeige) nicht gefunden. Skript wird beendet."
            goto Beenden
        }
        ControlSetText "Haupt : Anzeige", "Edit1", WinTitle
        ControlSend  "{Enter}", "Edit1",WinTitle
        sleep 500
        ControlSetText "", "Edit1", WinTitle
        ControlSend  "{Enter}", "Edit1",WinTitle
        sleep 400

        ; === Schritt 3: Formelementgeometrie Button klicken ===
        ControlName := GetControlByText("Formelementgeometrie auswählen oder bearbeiten",foundHwnd ,0 ,5)
        if (ControlName = "") {
            MsgBox "Kein Control mit Text <Formelementgeometrie auswählen...> gefunden."
            goto Beenden
        }
        sleep 200
        WaitForControlEnabled(ControlName, foundHwnd, 5)
        if (ControlName = "") {
            MsgBox "Kein aktives Control mit Text <Formelementgeometrie auswählen...> gefunden."
            Return
        }
        sleep 200
        SetControlDelay -1 ; notfalls testweise aktivieren
        ControlClick ControlName, WinTitle


        ; === Schritt 4: Warten auf Fenster mit Teilstring im Titel ===
        foundFormelHwnd := Winwait(WinTitle2,,5)
        ;WinActivate(WinTitle2)
        if !foundFormelHwnd {  ;
            MsgBox "Fenster Formelementgeometrie nicht gefunden. Skript wird beendet."
            goto Beenden
        }

        sleep 100

        ; === Schritt 5: Text aus dem Control nach dem mit dem Text "Senkungsdurchm."" holen ===
        ControlName := GetControlByText("Senkungsdurchm.",foundHwnd,1 ,5)
        if (ControlName = "") {
            MsgBox "Kein Control mit <Senkungsd.> gefunden."
            goto Beenden
        }

        Fas_D := ControlGetText(ControlName, foundFormelHwnd, 1)
        if (Fas_D = "") {
            MsgBox "Fasdurchmesser nicht gefunden. Skript wird beendet."
            goto Beenden
        }

        ; === Schritt 6: den Abbrechen Button klicken
        sleep 200
        ControlName := GetControlByText("Abbrechen",foundFormelHwnd,0 ,5, true) ; Suche rückwärts nach dem Abbrechen Button
        if (ControlName = "") {
            MsgBox "Kein Control mit <Abbrechen> gefunden."
            goto Beenden
        }
        SetControlDelay -1 ; notfalls testweise aktivieren
        ControlClick ControlName,  foundFormelHwnd

        ; === Schritt 7: Warten auf Fenster mit Kegelsenkenl ===
        foundHwnd := Winwait(WinTitle,,5)
        if !foundHwnd {
            MsgBox "Fenster 'Kegelsenken' nicht gefunden. Skript wird beendet."
            goto Beenden
        }

        ; === Schritt 8: Edit1 neuen Text eingeben ===
        ControlClick "Edit1", WinTitle
        ControlSetText "Vorschübe und Drehzahlen : Vorschübe und Drehzahlen", "Edit1", foundHwnd
        ControlSend  "{Enter}", "Edit1",foundHwnd
        sleep 800
        ControlSetText "", "Edit1", WinTitle
        ControlSend  "{Enter}", "Edit1",WinTitle
        sleep 300

        ; === Schritt 9: Fas_vc berechnen ===
        Fas_D_num := Fas_D + 0
        if (Fas_D_num = 0) {
            MsgBox "Fas_D ist ungültig. Skript wird beendet."
            goto Beenden
        }
        Fas_n := round(Fas_vc*1000 / Fas_D_num / 3.141592653589793,0)

        ; === Schritt 10: Spindeldrehzahl +1 Edit control finden und Text eintragen ===
        ControlName := GetControlByText("Spindeldrehzahl (U/min)",foundHwnd,1 ,5)
        if (ControlName = "") {
            MsgBox "Kein Control mit <Spindeldrehzahl (U/min.> gefunden."
            goto Beenden
        }

        ; === Schritt 11: Fas_n in Spindeldrehzahl eintragen ===
        SetKeyDelay 10, 10  ; ; Setze die Tastaturverzögerung auf 10ms wegen buggy Eingabe
        ControlFocus ControlName, foundHwnd
        ControlSetText "", ControlName, foundHwnd
        ControlSetText Round(Fas_n), ControlName,  foundHwnd
        ControlSend "{ENTER}", ControlName,  foundHwnd
        sleep 300

        ;goto ohneBerechnung ; Wenn keine Berechnung gewünscht ist, überspringe die nächsten Schritte
        ; === Schritt 12: Berechnen hinter Drehzahl (offset+12) klicken ===
        ControlName := GetControlByText("Spindeldrehzahl (U/min)",foundHwnd,12 ,5)
        WaitForControlEnabled(ControlName, foundHwnd, 5)
        if (ControlName = "") {
            MsgBox "Kein Control mit <Berechne hinter Spindeldrehzahl (U/min.> gefunden."
           Return
        }
        ControlClick ControlName, foundHwnd
        sleep 100
        ;ohneBerechnung:

        ; === Schritt 13: fz Wert 0.1 in Vorschub pro Zahn eintragen ===
        ControlName := GetControlByText("Vorschub pro Zahn",foundHwnd,1 ,5)
        if (ControlName = "") {
            MsgBox "Kein Control mit <Vorschub pro Zahn.> gefunden."
            goto Beenden
        }
        sleep 100
        ControlFocus ControlName, foundHwnd
        ControlSend "0{ENTER}",ControlName,  foundHwnd
        sleep 300
        ControlSetText Round(Fas_fz,2), ControlName, foundHwnd
        sleep 100
        ControlSend "{ENTER}",ControlName,  foundHwnd

        ; === Schritt 13: Berechnen  (offset+12) klicken ===
        sleep 300
        ControlName := GetControlByText("Vorschub pro Zahn",foundHwnd ,12 ,5)
        WaitForControlEnabled(ControlName, foundHwnd, 5)
        if (ControlName = "") {
            MsgBox "Kein Control mit <Berechne hinter Vorschub pro Zahn.> gefunden."
            goto Beenden
        }
        sleep 600
        SetControlDelay -1 ; notfalls testweise aktivieren
        ControlClick ControlName, foundHwnd



        TrayTip "Vc" Round(Fas_vc) " / fz" Round(Fas_fz,2) " für D" Round(Fas_D,3) " eingetragen."
            ;sleep 3000

        ; Fehlerbehandlungssprungmarke
        Beenden:
        try {
        global BitteWartenGui
        if IsSet(BitteWartenGui)
            BitteWartenGui.Destroy()
        }
    return 
    }



}
; ** HSS Bohren Handler
HssMenuHandler(*) {
    MsgBox("HSS Bohren noch nicht unterstützt!")
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
                continue ; Offset außerhalb des Bereichs, weiter versuchen
        }

        if (A_TickCount - startTime > timeout * 1000)
            return ""

        Sleep 100
    }
}
; Wartet das ein bestimmtes Control Enabled wird 
WaitForControlEnabled(ControlName, hwnd, Timeout := 5) {
    StartTime := A_TickCount
    while (A_TickCount - StartTime < Timeout * 1000) {
        try {
            if ControlGetEnabled(ControlName, hwnd) {
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