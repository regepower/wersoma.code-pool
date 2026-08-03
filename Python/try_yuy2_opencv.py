#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Versuch, das Black-Frame-Problem in OpenCV zu umgehen:
- Öffnet Kamera per DSHOW (falls verfügbar)
- Benutzt grab()/retrieve() und mehrfache Warmup-Frames
- Versucht explizite Konvertierung von YUY2 -> BGR, toggelt CAP_PROP_CONVERT_RGB
- Wenn Frame schwarz bleibt, versucht kurz neu zu öffnen
Tasten:
  s -> Snapshot
  q / ESC -> Beenden
"""
import cv2
import time
import os
from datetime import datetime

DEVICE = 0
W = 1920
H = 1080
SNAP_DIR = "snap_fix"
WARMUP_FRAMES = 30
REOPEN_WAIT = 0.5

os.makedirs(SNAP_DIR, exist_ok=True)

def open_cap(device):
    flag = cv2.CAP_DSHOW if hasattr(cv2, "CAP_DSHOW") else 0
    try:
        cap = cv2.VideoCapture(device, flag) if flag else cv2.VideoCapture(device)
    except Exception:
        cap = cv2.VideoCapture(device)
    return cap

def warmup(cap, n=WARMUP_FRAMES):
    # grab/retrieve warmup to let camera settle
    for i in range(n):
        cap.grab()
        time.sleep(0.01)
    # also try a few read() to ensure conversion happens
    for i in range(3):
        ret, f = cap.read()
        time.sleep(0.01)

def is_black(frame, thr=1.0):
    if frame is None:
        return True
    return float(frame.mean()) <= thr

def try_convert_yuy2(frame):
    try:
        conv = cv2.cvtColor(frame, cv2.COLOR_YUV2BGR_YUY2)
        if not is_black(conv):
            return conv
    except Exception:
        pass
    return None

def main():
    cap = open_cap(DEVICE)
    if not cap or not cap.isOpened():
        print("Kamera konnte nicht geöffnet werden. Schließe andere Apps (VLC/Browser) und versuche erneut.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, W)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, H)
    # Versuche Convert-RGB an, falls unterstützt
    if hasattr(cv2, "CAP_PROP_CONVERT_RGB"):
        try:
            cap.set(cv2.CAP_PROP_CONVERT_RGB, 1)
        except Exception:
            pass

    time.sleep(0.2)
    warmup(cap)

    win = "webcam-fix"
    cv2.namedWindow(win, cv2.WINDOW_NORMAL)
    last_nonblack = None
    reopen_attempts = 0

    try:
        while True:
            # Prefer grab/retrieve to have more control
            if not cap.grab():
                # failed to grab -> reopen
                print("grab() failed, versuche neu zu öffnen...")
                cap.release()
                time.sleep(REOPEN_WAIT)
                cap = open_cap(DEVICE)
                if not cap or not cap.isOpened():
                    print("Reopen fehlgeschlagen.")
                    time.sleep(1.0)
                    continue
                cap.set(cv2.CAP_PROP_FRAME_WIDTH, W)
                cap.set(cv2.CAP_PROP_FRAME_HEIGHT, H)
                warmup(cap)
                continue

            ret, frame = cap.retrieve()
            if not ret or frame is None:
                # versuche read fallback
                ret2, frame2 = cap.read()
                frame = frame2 if ret2 else None

            if frame is None or is_black(frame):
                # Versuch: explizite YUY2-Konvertierung
                conv = try_convert_yuy2(frame)
                if conv is not None:
                    frame = conv
                else:
                    # wenn schwarz: probiere CAP_PROP_CONVERT_RGB toggle
                    if hasattr(cv2, "CAP_PROP_CONVERT_RGB"):
                        try:
                            # toggle off -> on
                            cap.set(cv2.CAP_PROP_CONVERT_RGB, 0)
                            time.sleep(0.02)
                            cap.set(cv2.CAP_PROP_CONVERT_RGB, 1)
                        except Exception:
                            pass
                    # noch einmal grab/retrieve kurz
                    for i in range(3):
                        cap.grab()
                        ret3, f3 = cap.retrieve()
                        if ret3 and f3 is not None and not is_black(f3):
                            frame = f3
                            break

            if frame is None:
                # nichts zu zeigen; kleines Delay
                cv2.waitKey(50)
                continue

            # Wenn Frame immer noch schwarz, zählen wir Reopens
            if is_black(frame):
                reopen_attempts += 1
                if reopen_attempts >= 5:
                    print("Mehrere schwarze Frames, versuche Kamera neu zu öffnen...")
                    cap.release()
                    time.sleep(REOPEN_WAIT)
                    cap = open_cap(DEVICE)
                    if cap and cap.isOpened():
                        cap.set(cv2.CAP_PROP_FRAME_WIDTH, W)
                        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, H)
                        warmup(cap)
                    reopen_attempts = 0
            else:
                reopen_attempts = 0
                last_nonblack = frame

            cv2.imshow(win, frame)
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q') or key == 27:
                break
            if key == ord('s'):
                ts = datetime.now().strftime("%Y%m%d_%H%M%S")
                fn = os.path.join(SNAP_DIR, f"snapshot_{ts}.jpg")
                cv2.imwrite(fn, frame)
                print("Snapshot:", fn)

    finally:
        if cap:
            cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    main()