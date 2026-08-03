#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Webcam-Viewer (wählt Backend: default | dshow | msmf)
Beispiel:
  python show_webcam_cli_dshow.py --device 0 --backend dshow --width 640 --height 480

Tasten:
  s -> Snapshot speichern (snapshots/)
  q / ESC -> Beenden
"""
import argparse
import os
from datetime import datetime
import cv2

def parse_args():
    p = argparse.ArgumentParser(description="Webcam Viewer mit Backend-Auswahl")
    p.add_argument("--device", "-d", type=int, default=0, help="Device-Index der Webcam")
    p.add_argument("--backend", "-b", choices=["default", "dshow", "msmf"], default="default",
                   help="Welches OpenCV-Backend verwenden (default, dshow, msmf)")
    p.add_argument("--width", "-W", type=int, default=640, help="Gewünschte Breite (px)")
    p.add_argument("--height", "-H", type=int, default=480, help="Gewünschte Höhe (px)")
    p.add_argument("--snap-dir", "-s", default="snapshots", help="Ordner zum Speichern von Snapshots")
    return p.parse_args()

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)

def get_backend_flag(name):
    if name == "default":
        return 0
    if name == "dshow" and hasattr(cv2, "CAP_DSHOW"):
        return cv2.CAP_DSHOW
    if name == "msmf" and hasattr(cv2, "CAP_MSMF"):
        return cv2.CAP_MSMF
    return None

def open_camera(index, backend_flag):
    try:
        if backend_flag and backend_flag != 0:
            cap = cv2.VideoCapture(index, backend_flag)
        else:
            cap = cv2.VideoCapture(index)
    except Exception as e:
        print("Fehler beim Öffnen der Kamera:", e)
        return None
    if not cap.isOpened():
        return None
    return cap

def main():
    args = parse_args()
    ensure_dir(args.snap_dir)

    backend_flag = get_backend_flag(args.backend)
    if backend_flag is None and args.backend != "default":
        print(f"Requested backend '{args.backend}' is not available in this OpenCV build. Falling back to default.")
        backend_flag = 0

    cap = open_camera(args.device, backend_flag)
    if cap is None:
        print(f"Kamera index={args.device} konnte mit backend='{args.backend}' nicht geöffnet werden.")
        print("Versuche Default-Backend als Fallback...")
        cap = open_camera(args.device, 0)

    if cap is None or not cap.isOpened():
        print("Keine Kamera gefunden oder konnte nicht geöffnet werden. Prüfe Device-Index, Treiber und ob eine andere App die Kamera benutzt.")
        return

    # Versuche die gewünschte Auflösung zu setzen (kann ignoriert werden)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)

    # Testread
    ret, frame = cap.read()
    if not ret or frame is None:
        print("Kamera geöffnet, aber kein Frame erhalten. Möglicherweise ein Backend-Problem.")
        cap.release()
        return

    actual_h, actual_w = frame.shape[:2]
    print(f"Webcam geöffnet (index={args.device}, backend={args.backend}) -> tatsächliche Auflösung: {actual_w}x{actual_h}")
    print("Drücke 's' für Snapshot, 'q' oder ESC zum Beenden.")

    window_name = f"Webcam idx={args.device} ({args.backend})"
    cv2.namedWindow(window_name, cv2.WINDOW_AUTOSIZE)

    try:
        while True:
            ret, frame = cap.read()
            if not ret or frame is None:
                # Warte kurz und versuche weiter
                cv2.waitKey(100)
                continue

            cv2.imshow(window_name, frame)
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q') or key == 27:
                break
            elif key == ord('s'):
                ts = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = os.path.join(args.snap_dir, f"snapshot_{ts}.jpg")
                cv2.imwrite(filename, frame)
                print(f"Snapshot gespeichert: {filename}")
    finally:
        cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
