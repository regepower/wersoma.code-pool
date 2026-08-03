#Requires AutoHotkey v2.0
TrayTip "Starte im Hintergrund...", "CapsLock und NumLock aus."
~*CapsLock:: {
	SetCapsLockState("AlwaysOff")
	TrayTip ,"CapsLock bleibt aus!", 0+16
	TrayTipVerstecken

}
~*NumLock:: {
	SetNumLockState("AlwaysOn")
	TrayTip ,"NumLock bleibt an!", 0+16
	TrayTipVerstecken
}

TrayTipVerstecken() {
   sleep 2000
    TrayTip  ; Versuchen, normal zu verstecken.
    if SubStr(A_OSVersion,1,3) = "10." {
        A_IconHidden := true
        Sleep 200  ; Ggf. muss dieser Sleep-Wert angepasst werden.
        A_IconHidden := false
    }
}
