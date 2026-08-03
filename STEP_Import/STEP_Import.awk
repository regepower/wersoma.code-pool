BEGIN {
    # --- Benennung / STEP-Encoding ---
    schema_ok  = 0
    benennung  = ""

    # --- Konverter-Ausgabe Filter ---
    warn_input  = 0
    err_input   = 0
    warn_rose   = 0
    last_warn_input_msg = ""
    last_err_input_msg  = ""
    in_step_summary     = 0
    in_ug_summary       = 0
    step_total          = ""
    ug_total            = ""
    solids_ok           = ""
    solids_fault        = ""
    solids_sheet        = ""
    # filter_mode wird NICHT hier gesetzt! Sonst ueberschreibt das
    # jede per -v filter_mode=1 uebergebene Kommandozeilen-Variable,
    # da -v-Zuweisungen VOR dem BEGIN-Block ausgefuehrt werden.
}

# ============================================================
# Erste Regel fuer JEDEN Datensatz: alle \r-Zeichen entfernen.
# step214ug.exe schreibt teils ein zusaetzliches \r VOR manchen
# Zeilen (z.B. "...V2412.9140\r\n\rINFO-  Start..."), wodurch der
# ^INFO-/^STATUS-Anker sonst nicht mehr am Zeilenanfang greift.
# ============================================================
{ gsub(/\r/, "") }

# ============================================================
# BENENNUNG aus STEP-Datei lesen (nur vor Konverter-Output)
# ============================================================
/^FILE_SCHEMA/ {
    if ($0 ~ /10303 214/) schema_ok = 1
}

/DESCRIPTIVE_REPRESENTATION_ITEM\(.BENENNUNG.,/ {
    if (match($0, /'BENENNUNG','[^']*'/)) {
        s = substr($0, RSTART, RLENGTH)
        n = split(s, a, "'")
        benennung = a[4]
        # STEP X2-Encoding -> CP850
        gsub(/\\X2\\00DC\\X0\\/, "\232", benennung)
        gsub(/\\X2\\00FC\\X0\\/, "\201", benennung)
        gsub(/\\X2\\00C4\\X0\\/, "\216", benennung)
        gsub(/\\X2\\00E4\\X0\\/, "\204", benennung)
        gsub(/\\X2\\00D6\\X0\\/, "\231", benennung)
        gsub(/\\X2\\00F6\\X0\\/, "\366", benennung)
        gsub(/\\X2\\00DF\\X0\\/, "\341", benennung)
    }
}

# ============================================================
# Ab hier: Konverter-Output filtern
# Wird nur aktiv wenn filter_mode=1 (per -v filter_mode=1)
# ============================================================

filter_mode == 0 { next }

# --- STATUS-Zeilen: einzeilig ausgeben, leere ueberspringen ---
/^STATUS-[ ]*$/ { next }
/^STATUS-/ {
    sub(/^STATUS-[ ]*/, "")
    if ($0 != "") print "\033[37m[STATUS] " $0 "\033[0m"
    next
}

# --- INFO-Zeilen: nur relevante ---
/^INFO-[ ]*$/ { next }
/^INFO-.*Renaming Log/ { next }
/^INFO-.*NX STEP AP214/ { next }
/^INFO-.*Start of Translation/ { next }
/^INFO-.*Filing Part/ { next }

/^INFO-.*Total number of solids input/ {
    match($0, /: *([0-9]+)/, a); solids_input = a[1]; next
}
/^INFO-.*without body validation/ {
    match($0, /: *([0-9]+)/, a); solids_ok = a[1]; next
}
/^INFO-.*with body validation fault/ {
    match($0, /: *([0-9]+)/, a); solids_fault = a[1]; next
}
/^INFO-.*as sheet bodies/ {
    match($0, /: *([0-9]+)/, a); solids_sheet = a[1]; next
}
/^INFO-.*End of Translation/ {
    # Solid-Zusammenfassung ausgeben
    print "\033[37m[SOLIDS] Input: " solids_input \
          "  |  OK: " solids_ok \
          "  |  Fehler: " solids_fault \
          "  |  Sheet: " solids_sheet "\033[0m"
    # Jetzt Endmeldung
    match($0, /[0-9]{2}-[A-Z]+-[0-9]{4}.*/, t)
    print "\033[32m[FERTIG] Konvertierung abgeschlossen: " t[0] "\033[0m"
    next
}
/^INFO-/ { next }

# --- SUMMARY-Zeilen ---
/^SUMMARY-[ ]*$/ { next }
/^SUMMARY-.*STEP Header/ { next }
/^SUMMARY-.*Summary of STEP/ { in_step_summary = 1; in_ug_summary = 0; next }
/^SUMMARY-.*Summary of Unigraphics/ { in_ug_summary = 1; in_step_summary = 0; next }
/^SUMMARY-.*-----------/ { next }
/^SUMMARY-.*Entity Type/ { next }
/^SUMMARY-.*Entities Processed/ { next }

/^SUMMARY-.*File_Name/ {
    match($0, /File_Name[ ]+([^ ].*)/, a)
    fname = a[1]; sub(/[ \t]+$/, "", fname)
    print "\033[90m[DATEI ] " fname "\033[0m"
    next
}
/^SUMMARY-.*Author[ ]/ {
    match($0, /Author[ ]+([^ ].*)/, a)
    auth = a[1]; sub(/[ \t]+$/, "", auth)
    print "\033[90m[AUTOR ] " auth "\033[0m"
    next
}
/^SUMMARY-.*Pre_Version/ {
    match($0, /Pre_Version[ ]+([^ ].*)/, a)
    pv = a[1]; sub(/[ \t]+$/, "", pv)
    print "\033[90m[CAD   ] " pv "\033[0m"
    next
}

/^SUMMARY-.*Total/ {
    match($0, /([0-9]+)[ ]*$/, a)
    if (in_step_summary) {
        print "\033[32m[STEP  ] Entities gesamt: " a[1] "\033[0m"
        in_step_summary = 0
    } else if (in_ug_summary) {
        print "\033[32m[NX    ] Entities gesamt: " a[1] "\033[0m"
        in_ug_summary = 0
    }
    next
}
/^SUMMARY-/ {
    # Einzelne Entity-Zeilen unterdruecken
    if (in_step_summary || in_ug_summary) next
    next
}

# --- Input-Warnungen zaehlen ---
/^[^()]+\([0-9]+\): warning:/ {
    warn_input++
    match($0, /warning: (.*)/, a); last_warn_input_msg = a[1]
    next
}

# --- Input-Fehler zaehlen ---
/^[^()]+\([0-9]+\): error:/ {
    err_input++
    match($0, /error: (.*)/, a); last_err_input_msg = a[1]
    next
}

# --- ROSE-Warnungen zaehlen ---
/^ROSE: warning:/ {
    warn_rose++
    next
}

# --- Alles andere (Copyright, Leerzeilen etc.) unterdruecken ---
{ next }

END {
    if (filter_mode == 0) {
        # Normaler AWK-Lauf: Benennung ausgeben
        print "SCHEMA_OK=" schema_ok
        print "BENENNUNG=" benennung
    } else {
        # Zusammenfassung Warnungen/Fehler
        if (warn_input > 0)
            print "\033[33m[WARN  ] " warn_input " Input-Warnung(en): " last_warn_input_msg "\033[0m"
        if (warn_rose > 0)
            print "\033[33m[WARN  ] " warn_rose " ROSE-Warnung(en): Cannot typecast shape_aspect\033[0m"
        if (err_input > 0)
            print "\033[31m[FEHLER] " err_input " Input-Fehler: " last_err_input_msg "\033[0m"
    }
}
