#Requires AutoHotkey v2.0

ppt := ComObject("PowerPoint.Application")
ppt.WindowState := 2  ; minimiert

presentation := ppt.Presentations.Open("N:\\05_Präsentationen_TV\\Wersoma_TV_20250917.pptx", False, False, False)

outputDir := "N:\\05_Präsentationen_TV\\Export\\"
DirCreate outputDir

loop presentation.Slides.Count {
    slideNumber := A_Index
    slide := presentation.Slides.Item(slideNumber)

    ; ausgeblendete Folien überspringen
    if (slide.SlideShowTransition.Hidden) {
        continue
    }

    filePath := Format("{1}Slide_{2}.png", outputDir, slideNumber)
    slide.Export(filePath, "PNG", 1920, 1080)
}


presentation.Close()
ppt.Quit()
ppt := ""          ; COM-Objekte freigeben
presentation := ""
slide := ""