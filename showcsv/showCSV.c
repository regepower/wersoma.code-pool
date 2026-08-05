#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <Pfad_zur_CSV-Datei>\n", argv[0]);
        return 1;
    }

    // Pfad für PowerShell escapen (einfache Anführungszeichen verdoppeln)
    const char *original = argv[1];
    char escaped[4096] = {0};
    char *dest = escaped;
    const char *src = original;

    while (*src && (dest - escaped) < (int)sizeof(escaped) - 3) {
        if (*src == '\'') {
            *dest++ = '\'';
            *dest++ = '\'';
        } else {
            *dest++ = *src;
        }
        src++;
    }
    *dest = '\0';

    // PowerShell-Befehl: -PassThru sorgt dafür, dass das GridView-Fenster blockiert
    char cmd[8192];
    snprintf(cmd, sizeof(cmd),
             "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"Import-Csv -Path '%s' | Out-GridView -Title 'CSV-Anzeige' -PassThru | Out-Null\"",
             escaped);

    // Ausführen – system() wartet, bis PowerShell beendet ist (erst nach Schließen des GridView)
    int result = system(cmd);
    if (result == -1) {
        perror("Fehler beim Starten von PowerShell");
        return 1;
    }

    return 0;
}
