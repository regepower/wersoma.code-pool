@echo off
set "vorgabe=Vorgefertigter Standardtext"
set "sekunden=5"

echo Bitte Text eingeben (Zeitlimit: %sekunden% Sekunden):

:: Fuehrt C# aus. Zeichnet Zeichen live und bricht nach Ablauf der Sekunden sofort ab.
for /f "delims=" %%i in ('powershell -Command "add-type -TypeDefinition 'using System; using System.Threading; public class Input { public static string Read(int sec) { DateTime end = DateTime.Now.AddSeconds(sec); string inp = \"\"; while (DateTime.Now < end) { if (Console.KeyAvailable) { ConsoleKeyInfo k = Console.ReadKey(true); if (k.Key == ConsoleKey.Enter) { Console.WriteLine(); return inp; } if (k.Key == ConsoleKey.Backspace) { if (inp.Length > 0) { inp = inp.Substring(0, inp.Length - 1); Console.Write(\"\b \b\"); } } else { inp += k.KeyChar; Console.Write(k.KeyChar); } } Thread.Sleep(10); } Console.WriteLine(); return \"\"; } }'; [Input]::Read(%sekunden%)"') do set "eingabe=%%i"

:: Falls der Timeout griff oder nichts eingetippt wurde, nimm die Vorgabe
if "%eingabe%"=="" (
    set "eingabe=%vorgabe%"
)

echo.
echo Ergebnis: %eingabe%
echo.
pause
