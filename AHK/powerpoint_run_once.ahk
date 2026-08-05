#Requires AutoHotkey v2.0

ppt := ComObject("PowerPoint.Application")
ppt.Visible := true

presentation := ppt.Presentations.Open("N:\\05_Präsentationen_TV\\Wersoma_TV_20250917.pptx", False, False, False)


presentation.SlideShowSettings.Run()  ; Starte die Slideshow

; Polling-Loop: Warte, bis die Slideshow endet (State == 5)
while (presentation.SlideShowWindow.View.State != 5) {  ; 5 = ppSlideShowEnded
    Sleep 500  ; Prüfe alle 0,5 Sekunden
}

MsgBox "Die Präsentation ist durchgelaufen!"  ; Oder deine Aktion hier (z.B. ppt.Quit())

presentation.Close()
ppt.Quit()
Return