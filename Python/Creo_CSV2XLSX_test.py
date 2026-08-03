import sys

# sys.argv[0] ist immer der Name des Skripts selbst.
# sys.argv[1] ist das erste übergebene Argument (hier: %InvokedFrom%).
if len(sys.argv) > 1:
    invoked_from = sys.argv[1]
    print(f"[Python] Der Pfad aus der Batch-Datei lautet: {invoked_from}")
else:
    print("[Python] Es wurde kein Pfad übergeben.")
