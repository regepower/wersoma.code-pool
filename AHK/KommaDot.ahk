#Requires AutoHotkey v2.0
TrayTip "Starte im Hintergrund...", "Komma und Sonderzeichen ersetzen in NX."
SetTitleMatchMode 1 ; Genaue Übereinstimmung

#HotIf WinActive("ahk_exe ugraf.exe")
ä::Send("{Text}ae")
ü::Send("{Text}ue")
ö::Send("{Text}oe")
ß::Send("{Text}ss")
Ä::Send("{Text}Ae")
Ü::Send("{Text}Ue")
Ö::Send("{Text}Oe")
NumPadDot::Send(".")
#HotIf
