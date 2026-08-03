#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Diagnose-Skript für Webcam-Probleme unter Windows (oder andere OS).
Es probiert mehrere OpenCV-Backends, liest bis zu N Frames und speichert einen
Frame pro Versuch als result_{backend}.jpg. Zusätzlich werden einige Property-Werte
und Bildstatistiken ausgegeben (mean/min/max).

Usage:
  python check_and_save_frames.py --device 0 --width 640 --height 480
  python check_and_save_frames.py --device 0 --device-name "Integrated Camera" --backend dshow

Hinweis:
- Falls du den genauen DirectShow-Gerätenamen verwenden willst, liste Geräte mit:
  ffmpeg -list_devices true -f dshow -i dummy
  (falls ffmpeg installiert ist).
"""
import argparse
import os
import time
import cv2
import numpy as np

def parse_args():
    p = argparse.ArgumentParser(description="Webcam Diagnose: speichert Frames und zeigt Backend-Infos")
    p.add_argument("--device", "-d", type=int, default=0, help="Device-Index")
    p.add_argument("--device-name", type=str, default=None, help="Optional: Geräte-Name (z.B. 'Integrated Camera') für dshow")
    p.add_argument("--backend", "-b", choices=["dshow", "msmf", "default", "all"], default="all",
                   help="Welches Backend verwenden (oder 'all' zum Durchprobieren)")
    p.add_argument("--width", "-W", type=int, default=640)
    p.add_argument("--height", "-H", type=int, default=480)
    p.add_argument("--out-dir", "-o", default="diag_out", help="Ausgabeordner")
    p.add_argument("--tries", type=int, default=8, help="Max. Frames zum Lesen pro Versuch")
    return p.parse_args()

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)

def backend_flag(name):
    if name == "default":
        return 0
    if name == "dshow" and hasattr(cv2, "CAP_DSHOW"):
        return cv2.CAP_DSHOW
    if name == "msmf" and hasattr(cv2, "CAP_MSMF"):
        return cv2.CAP_MSMF
    return None

def try_capture(source, flag, width, height, tries, out_path):
    try:
        if flag and flag != 0:
            cap = cv2.VideoCapture(source, flag)
        else:
            cap = cv2.VideoCapture(source)
    except Exception as e:
        return {"ok": False, "error": f"Exception beim Öffnen: {e}"}

    if not cap or not cap.isOpened():
        return {"ok": False, "error": "nicht geöffnet"}

    # Versuche Auflösung zu setzen
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
    # kurze Pause damit das Backend initialisieren kann
    time.sleep(0.12)

    last_frame = None
    for i in range(tries):
        ret, frame = cap.read()
        if not ret or frame is None:
            # kurz warten und erneut versuchen
            time.sleep(0.05)
            continue
        last_frame = frame
        # wir brechen beim ersten gelesenen Frame ab; bei Bedarf kann man hier mehr lesen
        break

    # Lies ein paar Properties
    props = {
        "CAP_PROP_FRAME_WIDTH": cap.get(cv2.CAP_PROP_FRAME_WIDTH),
        "CAP_PROP_FRAME_HEIGHT": cap.get(cv2.CAP_PROP_FRAME_HEIGHT),
        "CAP_PROP_FOURCC": int(cap.get(cv2.CAP_PROP_FOURCC)),
        "CAP_PROP_FPS": cap.get(cv2.CAP_PROP_FPS),
        "CAP_PROP_BRIGHTNESS": cap.get(cv2.CAP_PROP_BRIGHTNESS),
        "CAP_PROP_CONTRAST": cap.get(cv2.CAP_PROP_CONTRAST),
        "CAP_PROP_SATURATION": cap.get(cv2.CAP_PROP_SATURATION),
        "CAP_PROP_GAIN": cap.get(cv2.CAP_PROP_GAIN),
        "CAP_PROP_EXPOSURE": cap.get(cv2.CAP_PROP_EXPOSURE),
    }

    result = {"ok": True, "props": props, "got_frame": False, "stats": None, "out_path": None}

    if last_frame is not None:
        # Save frame and compute stats
        # convert BGR->RGB for human viewing if needed, but saving BGR is fine
        save_path = out_path
        cv2.imwrite(save_path, last_frame)
        result["got_frame"] = True
        result["out_path"] = save_path

        # compute mean/min/max per channel and overall
        if last_frame.ndim == 3:
            ch_means = list(map(float, last_frame.mean(axis=(0,1))))
            ch_mins = list(map(int, last_frame.min(axis=(0,1))))
            ch_maxs = list(map(int, last_frame.max(axis=(0,1))))
            overall_mean = float(last_frame.mean())
        else:
            ch_means = [float(last_frame.mean())]
            ch_mins = [int(last_frame.min())]
            ch_maxs = [int(last_frame.max())]
            overall_mean = float(last_frame.mean())

        result["stats"] = {
            "channel_means": ch_means,
            "channel_mins": ch_mins,
            "channel_maxs": ch_maxs,
            "overall_mean": overall_mean,
            "shape": last_frame.shape
        }

    cap.release()
    return result

def main():
    args = parse_args()
    ensure_dir(args.out_dir)

    backends = []
    if args.backend == "all":
        for b in ("dshow", "msmf", "default"):
            backends.append(b)
    else:
        backends = [args.backend]

    full_results = {}

    for b in backends:
        flag = backend_flag(b)
        if flag is None and b != "default":
            print(f"Backend {b} ist in dieser OpenCV-Build nicht verfügbar -> übersprungen")
            continue

        # source kann entweder ein Index (int) oder ein dshow-Name (string) sein
        source = args.device
        if b == "dshow" and args.device_name:
            # Nutze DirectShow-Gerätenamen, Format: "video=Gerätename"
            source = f"video={args.device_name}"
            print(f"Versuche DSHOW mit source='{source}'")

        out_file = os.path.join(args.out_dir, f"result_{b}.jpg")
        print(f"\n--- Versuch Backend={b} (source={source}) -> speichere in {out_file} ---")
        res = try_capture(source, flag, args.width, args.height, args.tries, out_file)
        full_results[b] = res

        if not res["ok"]:
            print("Fehler:", res.get("error"))
            continue

        print("Properties:")
        for k, v in res["props"].items():
            print(f"  {k}: {v}")
        if res["got_frame"]:
            st = res["stats"]
            print("Frame erhalten:", st["shape"])
            print(f"  channel_means: {st['channel_means']}")
            print(f"  channel_mins: {st['channel_mins']}")
            print(f"  channel_maxs: {st['channel_maxs']}")
            print(f"  overall_mean: {st['overall_mean']:.2f}")
            print(f"  Bild gespeichert: {res['out_path']}")
        else:
            print("Kein Frame erhalten (nach mehreren Versuchen).")

    print("\nFERTIG. Beispiele nächste Schritte:")
    print("- Öffne die gespeicherten Dateien (diag_out/result_*.jpg) und prüfe, ob sie schwarz sind.")
    print("- Poste die komplette Ausgabe dieses Skripts hier und sag mir, welche result_*.jpg schwarz sind.")
    print("- Wenn DSHOW mit Gerätname probiert werden soll, liste Geräte mit 'ffmpeg -list_devices true -f dshow -i dummy' und nutze --device-name '...'.")
    print("- Prüfe die Windows-Kamera-App: wenn dort auch kein Bild erscheint, ist es kein OpenCV-Problem, sondern Treiber/Hardware/Privacy.")
    print("- Falls die Frames sehr dunkel sind (low mean), wir können versuchen, CAP_PROP_EXPOSURE / CAP_PROP_GAIN zu setzen.")

if __name__ == "__main__":
    main()
