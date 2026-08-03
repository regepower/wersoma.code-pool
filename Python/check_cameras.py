#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Prüft mehrere Kamera-Device-Indices und verschiedene OpenCV-Backends (Windows).
Usage:
  python check_cameras.py
"""
import cv2
import sys

BACKENDS = []
# cv2.CAP_DSHOW, cv2.CAP_MSMF und cv2.CAP_VFW sind auf Windows verfügbar, ggf. nicht alle in jeder OpenCV-Build
for name, val in [
    ("DEFAULT", 0),
    ("DSHOW", getattr(cv2, "CAP_DSHOW", 0)),
    ("MSMF", getattr(cv2, "CAP_MSMF", 0)),
    ("VFW", getattr(cv2, "CAP_VFW", 0)),
]:
    BACKENDS.append((name, val))

max_index = 8

def try_open(index, backend):
    try:
        cap = cv2.VideoCapture(index, backend) if backend != 0 else cv2.VideoCapture(index)
    except Exception as e:
        return False, f"Exception: {e}"
    if not cap.isOpened():
        return False, ""
    # try to grab one frame
    ret, frame = cap.read()
    cap.release()
    if not ret or frame is None:
        return True, "opened but no frame read"
    h, w = frame.shape[:2]
    return True, f"opened, frame {w}x{h}"

def main():
    print("OpenCV version:", cv2.__version__)
    for idx in range(0, max_index):
        for name, backend in BACKENDS:
            ok, msg = try_open(idx, backend)
            status = "OK" if ok else "FAIL"
            print(f"Index {idx:>2} Backend {name:<7} -> {status} {('- ' + msg) if msg else ''}")
    print("\nHinweise:")
    print("- Falls \"opened but no frame read\" erscheint, kann die Kamera zwar geöffnet, aber kein Bild geliefert werden.")
    print("- Schließe andere Anwendungen, die die Kamera nutzen (Teams, Zoom, Browser-Tabs).")
    print("- Prüfe Windows → Einstellungen → Datenschutz → Kamera: Apps erlauben Zugriff.")
    print("- Falls nichts gefunden wird, poste die obige Ausgabe hier.")

if __name__ == "__main__":
    main()
