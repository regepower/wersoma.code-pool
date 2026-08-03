#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kurze Diagnose mit OpenCV + ffplay (DirectShow)
Usage:
  python webcam_diagnostic_ffplay.py --device 0 --device-name "UGREEN Camera" --duration 8

Was das Script tut:
- Führt den kurzen OpenCV-Test aus (wie zuvor).
- Startet ffplay mit den angegebenen Optionen für eine bestimmte Dauer (oder bis der Benutzer das Fenster schließt).
- Gibt stderr/output von ffplay zur Analyse aus.

Hinweis:
- Führe das Script in einer normalen CMD aus (nicht PowerShell), und schließe vorher VLC/andere Programme, welche die Kamera nutzen.
- ffplay muss in PATH sein oder per --ffplay Pfad angegeben werden.
"""
import argparse
import subprocess
import shlex
import sys
import time
import cv2
import os

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--device", type=int, default=0, help="Device-Index für OpenCV-Test")
    p.add_argument("--device-name", type=str, default=None, help='DirectShow-Name für ffplay, z.B. "UGREEN Camera"')
    p.add_argument("--ffplay", default="ffplay", help="ffplay executable (oder Pfad)")
    p.add_argument("--size", default="1280x720", help="video size z.B. 1280x720")
    p.add_argument("--framerate", type=int, default=30, help="Framerate (z.B. 30)")
    p.add_argument("--duration", type=int, default=8, help="Sekunden ffplay laufen lassen (0 = bis Schließen durch Nutzer)")
    return p.parse_args()

def opencv_test(device):
    print("=== OpenCV Test ===")
    print("OpenCV version:", cv2.__version__)
    flag = cv2.CAP_DSHOW if hasattr(cv2, "CAP_DSHOW") else 0
    print("Benutze DSHOW-Flag:", bool(flag))
    try:
        cap = cv2.VideoCapture(device, flag) if flag else cv2.VideoCapture(device)
    except Exception as e:
        print("Exception beim Öffnen mit OpenCV:", e)
        return
    if not cap or not cap.isOpened():
        print("OpenCV: Kamera konnte nicht geöffnet werden.")
        return
    # kurze Testreihe
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    time.sleep(0.2)
    for i in range(6):
        ret, frame = cap.read()
        if not ret or frame is None:
            print(f"Frame {i}: ret={ret}, frame=None")
        else:
            print(f"Frame {i}: ret={ret}, shape={frame.shape}, dtype={frame.dtype}, mean={float(frame.mean()):.3f}")
        time.sleep(0.05)
    cap.release()
    print("OpenCV Test Ende\n")

def ffplay_test(ffplay_bin, device_name, size, framerate, duration):
    print("=== ffplay Test ===")
    if not device_name:
        print("Kein --device-name angegeben, überspringe ffplay-Test.")
        return
    # build command
    cmd = [
        ffplay_bin,
        "-hide_banner",
        "-loglevel", "info",
        "-rtbufsize", "100M",
        "-f", "dshow",
        "-framerate", str(framerate),
        "-video_size", size,
        "-i", f'video={device_name}',
        "-an",            # kein Audio
        "-autoexit"      # nach Ende automatisch beenden (wenn duration gesetzt)
    ]
    # Wenn duration == 0: entferne autoexit, ffplay läuft bis der Nutzer schließt.
    if duration == 0:
        # leave autoexit; user will close window manually. But keep autoexit removed to allow manual close.
        cmd = [c for c in cmd if c != "-autoexit"]
    print("Starte ffplay:")
    print("  " + " ".join(shlex.quote(c) for c in cmd))
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    except FileNotFoundError:
        print("ffplay nicht gefunden (FileNotFoundError). Setze --ffplay auf den Pfad zu ffplay.exe oder installiere ffplay in PATH.")
        return

    try:
        if duration > 0:
            try:
                # Warte bis duration oder bis ffplay beendet
                out, err = proc.communicate(timeout=duration)
            except subprocess.TimeoutExpired:
                # Zeit abgelaufen -> beende ffplay
                try:
                    proc.kill()
                except Exception:
                    pass
                _, err = proc.communicate(timeout=2)
        else:
            # duration == 0: warte auf manuelles Schließen (blockierend)
            out, err = proc.communicate()
    except KeyboardInterrupt:
        print("Abbruch per Tastatur: ffplay wird beendet.")
        try:
            proc.kill()
        except Exception:
            pass
        return

    if err:
        try:
            s = err.decode("utf-8", errors="replace")
        except Exception:
            s = str(err)
        print("\nffplay stderr (Auszug, max 2000 chars):")
        print(s[:2000])
        # falls länger, speichere komplett
        if len(s) > 2000:
            with open("ffplay_stderr.txt", "w", encoding="utf-8", errors="replace") as f:
                f.write(s)
            print("Vollständige ffplay-stderr in ffplay_stderr.txt gespeichert.")
    print("ffplay-Prozess beendet, returncode:", proc.returncode)
    print("ffplay Test Ende\n")

def main():
    args = parse_args()
    print("Hinweis: bitte VLC/andere Programme schließen, die die Kamera nutzen.")
    opencv_test(args.device)
    ffplay_test(args.ffplay, args.device_name, args.size, args.framerate, args.duration)

if __name__ == "__main__":
    main()#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kurze Diagnose: OpenCV DSHOW-Test + ffmpeg-pipe Test.
Usage:
  python webcam_diagnostic_short.py --device 0 --device-name "UGREEN Camera"
"""
import argparse
import subprocess
import shlex
import sys
import time
import cv2
import numpy as np
import os

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--device", type=int, default=0, help="Device-Index für OpenCV")
    p.add_argument("--device-name", type=str, default=None, help='DirectShow-Name für ffmpeg, z.B. "UGREEN Camera"')
    p.add_argument("--ffmpeg", default="ffmpeg", help="ffmpeg executable (oder Pfad)")
    return p.parse_args()

def opencv_test(device):
    print("=== OpenCV Test ===")
    print("OpenCV version:", cv2.__version__)
    flag = cv2.CAP_DSHOW if hasattr(cv2, "CAP_DSHOW") else 0
    print("Benutze DSHOW-Flag:" , bool(flag))
    try:
        cap = cv2.VideoCapture(device, flag) if flag else cv2.VideoCapture(device)
    except Exception as e:
        print("Exception beim Öffnen mit OpenCV:", e)
        return
    if not cap or not cap.isOpened():
        print("OpenCV: Kamera konnte nicht geöffnet werden.")
        return
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    time.sleep(0.2)
    for i in range(8):
        ret, frame = cap.read()
        if not ret or frame is None:
            print(f"Frame {i}: ret={ret}, frame=None")
        else:
            print(f"Frame {i}: ret={ret}, shape={frame.shape}, dtype={frame.dtype}, mean={float(frame.mean()):.3f}")
        time.sleep(0.05)
    cap.release()
    print("OpenCV Test Ende\n")

def ffmpeg_pipe_test(ffmpeg_bin, device_name):
    print("=== ffmpeg Pipe Test ===")
    if not device_name:
        print("Kein --device-name angegeben, überspringe ffmpeg-Test.")
        return
    cmd = [
        ffmpeg_bin,
        "-hide_banner", "-loglevel", "error",
        "-rtbufsize", "100M",
        "-f", "dshow",
        "-i", f'video={device_name}',
        "-frames:v", "1",
        "-f", "image2pipe",
        "-vcodec", "mjpeg",
        "pipe:1"
    ]
    print("Starte ffmpeg:", " ".join(shlex.quote(c) for c in cmd))
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError:
        print("ffmpeg nicht gefunden (FileNotFoundError). Setze --ffmpeg auf den Pfad zu ffmpeg.exe oder installiere ffmpeg in PATH.")
        return
    try:
        out, err = proc.communicate(timeout=8)
    except subprocess.TimeoutExpired:
        proc.kill()
        out, err = proc.communicate()
        print("ffmpeg TimeoutExpired")
    if proc.returncode != 0:
        print("ffmpeg returncode:", proc.returncode)
        if err:
            print("ffmpeg stderr (kurz):")
            print(err.decode("utf-8", errors="replace")[:1000])
    if not out:
        print("ffmpeg lieferte keine Daten (out empty).")
        # speichere stderr komplett zur Analyse
        if err:
            with open("ffmpeg_err.txt", "wb") as f:
                f.write(err)
            print("ffmpeg stderr in ffmpeg_err.txt gespeichert.")
        return
    # versuche erstes JPEG zu dekodieren
    # finde EOI
    eoi = out.find(b'\xff\xd9')
    blob = out if eoi == -1 else out[:eoi+2]
    img = cv2.imdecode(np.frombuffer(blob, dtype=np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        print("cv2.imdecode returned None (konnte JPEG nicht dekodieren). Rohdatengröße:", len(out))
        with open("ffmpeg_raw.bin", "wb") as f:
            f.write(out)
        print("Rohdaten in ffmpeg_raw.bin gespeichert.")
        return
    print("ffmpeg -> Bild erhalten, shape:", img.shape, "dtype:", img.dtype, "mean:", float(img.mean()))
    cv2.imwrite("ffmpeg_frame.jpg", img)
    print("ffmpeg_frame.jpg gespeichert.")
    print("ffmpeg Test Ende\n")

def main():
    args = parse_args()
    # Stelle sicher, dass VLC etc. geschlossen sind
    print("Schließe bitte vorher VLC/andere Programme, die die Kamera nutzen.")
    opencv_test(args.device)
    ffmpeg_pipe_test(args.ffmpeg, args.device_name)

if __name__ == "__main__":
    main()