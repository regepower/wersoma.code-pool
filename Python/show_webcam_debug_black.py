#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Webcam Debug: versucht MJPG/Convert-RGB/Warmup, liest mehrere Frames und speichert Beispiele.
Usage:
  python show_webcam_debug_black.py --device 0 --backend dshow --width 1280 --height 720

Erzeugt Ausgaben im Ordner diag_debug/.
"""
import argparse
import os
import time
import cv2
import numpy as np

def parse_args():
    p = argparse.ArgumentParser(description="Webcam Debug (MJPG/convert RGB/warmup)")
    p.add_argument("--device", "-d", type=int, default=0, help="Device-Index")
    p.add_argument("--backend", "-b", choices=["dshow","msmf","default"], default="dshow")
    p.add_argument("--width", "-W", type=int, default=1280)
    p.add_argument("--height", "-H", type=int, default=720)
    p.add_argument("--out-dir", "-o", default="diag_debug")
    p.add_argument("--frames", type=int, default=60, help="Frames zum Einlesen/Warmup")
    return p.parse_args()

def ensure_dir(p):
    if not os.path.exists(p):
        os.makedirs(p, exist_ok=True)

def backend_flag(name):
    if name == "default":
        return 0
    if name == "dshow" and hasattr(cv2, "CAP_DSHOW"):
        return cv2.CAP_DSHOW
    if name == "msmf" and hasattr(cv2, "CAP_MSMF"):
        return cv2.CAP_MSMF
    return None

def fourcc_int(s):
    return cv2.VideoWriter_fourcc(*s)

def open_cap(source, flag):
    try:
        if flag and flag != 0:
            return cv2.VideoCapture(source, flag)
        return cv2.VideoCapture(source)
    except Exception as e:
        print("Exception beim Öffnen:", e)
        return None

def print_props(cap):
    keys = [
        ("CAP_PROP_FRAME_WIDTH", cv2.CAP_PROP_FRAME_WIDTH),
        ("CAP_PROP_FRAME_HEIGHT", cv2.CAP_PROP_FRAME_HEIGHT),
        ("CAP_PROP_FPS", cv2.CAP_PROP_FPS),
        ("CAP_PROP_FOURCC", cv2.CAP_PROP_FOURCC),
        ("CAP_PROP_BRIGHTNESS", cv2.CAP_PROP_BRIGHTNESS),
        ("CAP_PROP_CONTRAST", cv2.CAP_PROP_CONTRAST),
        ("CAP_PROP_SATURATION", cv2.CAP_PROP_SATURATION),
        ("CAP_PROP_GAIN", cv2.CAP_PROP_GAIN),
        ("CAP_PROP_EXPOSURE", cv2.CAP_PROP_EXPOSURE),
    ]
    for name, code in keys:
        try:
            print(f"  {name}: {cap.get(code)}")
        except:
            print(f"  {name}: (n/a)")

def frame_stats(img):
    if img is None:
        return None
    if img.ndim == 3:
        ch_means = list(map(float, img.mean(axis=(0,1))))
        ch_mins = list(map(int, img.min(axis=(0,1))))
        ch_maxs = list(map(int, img.max(axis=(0,1))))
        overall = float(img.mean())
        return {"shape": img.shape, "ch_means": ch_means, "ch_mins": ch_mins, "ch_maxs": ch_maxs, "overall": overall}
    else:
        return {"shape": img.shape, "ch_means":[float(img.mean())], "ch_mins":[int(img.min())], "ch_maxs":[int(img.max())], "overall": float(img.mean())}

def attempt(name, source, flag, width, height, frames, outdir, set_fourcc=None, set_convert_rgb=None):
    print(f"\n=== Versuch: {name} set_fourcc={set_fourcc} convert_rgb={set_convert_rgb} ===")
    cap = open_cap(source, flag)
    if not cap or not cap.isOpened():
        print("  konnte nicht geöffnet werden.")
        return
    # set resolution
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
    # optionally set FOURCC (e.g. MJPG)
    if set_fourcc:
        try:
            code = fourcc_int(set_fourcc)
            cap.set(cv2.CAP_PROP_FOURCC, code)
            print(f"  gesetzter FOURCC: {set_fourcc} -> {code}")
        except Exception as e:
            print("  FOURCC set Fehler:", e)
    # optional convert rgb flag (if supported)
    if set_convert_rgb is not None and hasattr(cv2, "CAP_PROP_CONVERT_RGB"):
        try:
            cap.set(cv2.CAP_PROP_CONVERT_RGB, 1 if set_convert_rgb else 0)
            print(f"  CAP_PROP_CONVERT_RGB gesetzt auf {set_convert_rgb}")
        except Exception as e:
            print("  CAP_PROP_CONVERT_RGB set Fehler:", e)

    # kurzer warmup
    print("  Warte kurz zum Warmup (0.8s)...")
    time.sleep(0.8)

    last = None
    got = False
    for i in range(frames):
        ret, frame = cap.read()
        if not ret or frame is None:
            # try again
            if i % 10 == 0:
                print(f"  Frame {i}: kein Frame (ret={ret})")
            time.sleep(0.02)
            continue
        last = frame
        got = True
        if i % 10 == 0:
            st = frame_stats(frame)
            print(f"  Frame {i} stats overall={st['overall']:.2f} shape={st['shape']}")
        # continue reading to let camera auto adjustments settle
    print("  Ende Einlese-Schleife.")
    print("  Properties nach Lesen:")
    print_props(cap)

    out_path = os.path.join(outdir, f"result_{name}.jpg")
    if last is not None:
        cv2.imwrite(out_path, last)
        st = frame_stats(last)
        print(f"  Letzter Frame stats overall={st['overall']:.2f} ch_means={st['ch_means']} ch_maxs={st['ch_maxs']}")
        print(f"  Bild gespeichert: {out_path}")
    else:
        print("  Kein Frame erhalten, nichts gespeichert.")
    cap.release()

def main():
    args = parse_args()
    ensure_dir(args.out_dir)
    flag = backend_flag(args.backend)
    if flag is None and args.backend != "default":
        print("Requested backend nicht verfügbar, benutze default.")
        flag = 0

    source = args.device

    # Versuchsreihen: baseline, MJPG, convert rgb ON/OFF
    attempts = [
        ("baseline", None, None),
        ("mjpg", "MJPG", None),
        ("mjpg_convertON", "MJPG", True),
        ("convertON", None, True),
        ("convertOFF", None, False),
    ]

    for name, fourcc, convert_rgb in attempts:
        attempt(name, source, flag, args.width, args.height, args.frames, args.out_dir, set_fourcc=fourcc, set_convert_rgb=convert_rgb)

    print("\nFERTIG. Öffne die Dateien im Ordner", args.out_dir, "und prüfe overall-Werte und Bilder.")
    print("Wenn alle Bilder schwarz (overall ~0), versuche bitte:")
    print(" - in der Windows Kamera-App die Kameraeinstellungen (Belichtung/Gain) erhöhen oder Auto-Belichtung erlauben")
    print(" - testweise andere Auflösungen (640x480) oder setze FOURCC auf MJPG in Treiber/Software")
    print(" - wenn möglich: installiere OpenCV mit ffmpeg-Unterstützung oder probiere ein anderes Tool (ffmpeg/dshow) zur Prüfung")
    print("Schick mir die komplette Konsolenausgabe dieses Scripts und sag, welche result_*.jpg schwarz sind.")

if __name__ == "__main__":
    main()