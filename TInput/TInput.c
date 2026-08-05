/* TInput.c - MS-DOS/Windows Input-Befehl mit Prompt, Timeout und Default-Wert
 * Kompilieren mit: gcc -O2 -s TInput.c -o TInput.exe   (MinGW)
 *                  tcc -mt TInput.c                     (Turbo C Tiny-Modell)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#include <conio.h>

/* Prueft ob ein String rein numerisch ist */
int is_number(const char *s) {
    if (*s == '\0') return 0;
    while (*s) {
        if (!isdigit((unsigned char)*s)) return 0;
        s++;
    }
    return 1;
}

int main(int argc, char *argv[])
{
    char prompt_text[256] = "";
    char default_text[256] = "";
    int  timeout_sec = 0;
    char buffer[256] = "";
    int  pos = 0;
    int  typing = 0;
    time_t start;
    int  i, deflen;

    /* stderr sofort ausgeben (kein Puffer) */
    setbuf(stderr, NULL);

    /* --- Hilfe anzeigen wenn keine Parameter --- */
    if (argc < 2) {
        fprintf(stderr,
            "TInput - Input-Befehl mit Prompt, Timeout und Vorgabetext\n"
            "===========================================================\n"
            "\n"
            "Aufruf:   TInput [Prompt] [Vorgabetext] [Timeout]\n"
            "\n"
            "Beispiele:\n"
            "  TInput 5                    Timeout 5 Sek., leere Vorgabe\n"
            "  TInput \"Hans\"               Vorgabe 'Hans', kein Timeout\n"
            "  TInput \"Hans\" 5             Vorgabe 'Hans', 5 Sek.\n"
            "  TInput \"Name: \" \"Hans\"     Prompt + Vorgabe, kein Timeout\n"
            "  TInput \"Name: \" \"Hans\" 5   Prompt + Vorgabe + 5 Sek.\n"
            "  TInput \"Name: \" \"\" 5       Prompt + leere Vorgabe + 5 Sek.\n"
            "\n"
            "Batch-Nutzung (for /f):\n"
            "  for /f \"tokens=*\" %%a in ('TInput \"Name: \" \"Max\" 5') do set ERG=%%a\n"
            "  echo %ERG%\n"
            "\n"
            "Funktion:\n"
            "  - Prompt und Vorgabetext werden auf stderr angezeigt\n"
            "  - Ergebnis (nur der Wert) erscheint auf stdout\n"
            "  - Nach Timeout wird Vorgabetext automatisch uebernommen\n"
            "  - Sobald getippt wird: Timeout auf unendlich,\n"
            "    nur der Vorgabetext wird geloescht\n"
            "  - ENTER ohne Tippen -> Vorgabetext uebernehmen\n"
            "  - ESC -> Abbruch, Vorgabetext uebernehmen\n"
            "\n");
        return 1;
    }

    /* --- Parameter einlesen --- */
    if (argc == 2) {
        /* Ein Parameter */
        if (is_number(argv[1])) {
            /* Nur Timeout, leere Vorgabe */
            timeout_sec = atoi(argv[1]);
        } else {
            /* Nur Vorgabetext */
            strncpy(default_text, argv[1], 255);
            default_text[255] = '\0';
        }
    }
    else if (argc == 3) {
        /* Zwei Parameter */
        if (is_number(argv[2])) {
            /* Vorgabetext + Timeout */
            strncpy(default_text, argv[1], 255);
            default_text[255] = '\0';
            timeout_sec = atoi(argv[2]);
        } else {
            /* Prompt + Vorgabetext */
            strncpy(prompt_text, argv[1], 255);
            prompt_text[255] = '\0';
            strncpy(default_text, argv[2], 255);
            default_text[255] = '\0';
        }
    }
    else if (argc >= 4) {
        /* Drei Parameter: Prompt + Vorgabetext + Timeout */
        strncpy(prompt_text, argv[1], 255);
        prompt_text[255] = '\0';
        strncpy(default_text, argv[2], 255);
        default_text[255] = '\0';
        timeout_sec = atoi(argv[3]);
    }

    if (timeout_sec < 0) timeout_sec = 0;
    deflen = strlen(default_text);

    /* Prompt auf stderr ausgeben (wird nie geloescht) */
    fprintf(stderr, "%s", prompt_text);
    /* Vorgabetext auf stderr ausgeben (wird bei Tippen geloescht) */
    fprintf(stderr, "%s", default_text);

    start = time(NULL);

    /* --- Hauptschleife --- */
    while (1) {
        if (kbhit()) {
            int ch = getch();   /* liest OHNE Echo auf den Bildschirm */

            /* ENTER -> Eingabe beenden */
            if (ch == 13) {
                if (!typing && deflen > 0) {
                    strcpy(buffer, default_text);
                }
                break;
            }

            /* ESC -> Abbruch, Default-Wert uebernehmen */
            if (ch == 27) {
                strcpy(buffer, default_text);
                break;
            }

            /* Erstes Zeichen -> nur Default-Text loeschen, Timeout deaktivieren */
            if (!typing) {
                typing = 1;
                for (i = 0; i < deflen; i++) {
                    fprintf(stderr, "\b \b");   /* Cursor zurueck, loeschen, zurueck */
                }
            }

            /* Backspace */
            if (ch == 8) {
                if (pos > 0) {
                    pos--;
                    fprintf(stderr, "\b \b");
                }
            }
            /* Druckbare Zeichen */
            else if (ch >= 32 && ch < 127 && pos < 255) {
                buffer[pos++] = ch;
                fputc(ch, stderr);   /* Echo manuell auf stderr */
            }
        }

        /* Timeout pruefen (nur solange der User noch NICHT tippt) */
        if (!typing && timeout_sec > 0) {
            if ((int)(time(NULL) - start) >= timeout_sec) {
                strcpy(buffer, default_text);
                break;
            }
        }
    }

    if (typing) {
        buffer[pos] = '\0';
    }
    fprintf(stderr, "\n");

    /* --- Ergebnis auf stdout -> wird von Dateiumleitung / for /f eingefangen --- */
    printf("%s\n", buffer);

    return 0;
}
