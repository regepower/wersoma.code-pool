// FILE: QrWedge/MainForm.cs

using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Media;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using ZXing;
using ZXing.Common;

using GitHub.secile.Video;

namespace QrWedge
{
    public sealed class MainForm : Form
    {
        private readonly NotifyIcon _tray = new() { Visible = true, Text = "QR Wedge" };
        private readonly ContextMenuStrip _menu = new();
        private readonly PreviewOverlayForm _overlay = new();

        // CancellationTokenSource und Task-Logik ist nicht mehr notwendig, da UsbCamera Events nutzt
        // private CancellationTokenSource? _captureCts;
        private bool _scanning = false;
        private readonly object _candidateLock = new();
        private string _candidate = string.Empty;
        private string _lastCommitted = string.Empty;
        private DateTime _lastCommittedAt = DateTime.MinValue;
        private readonly int _dupWindowMs = 1500;
        private readonly TimeSpan _frameInterval = TimeSpan.FromMilliseconds(150); // Wird jetzt nur als Richtwert verwendet

        // ERSETZT: OpenCvSharp.VideoCapture
        private CameraService? _cameraService; // Instanz des CameraService

        private int _currentCameraId = -1;
        private List<int> _availableCameraIds = new();

        private readonly BarcodeReaderGeneric _reader = new BarcodeReaderGeneric
        {
            AutoRotate = true,
            Options = new DecodingOptions
            {
                TryHarder = true,
                PossibleFormats = new System.Collections.Generic.List<BarcodeFormat>
                {
                    BarcodeFormat.QR_CODE,
                    BarcodeFormat.DATA_MATRIX,
                    BarcodeFormat.PDF_417,
                    BarcodeFormat.CODE_128,
                    BarcodeFormat.CODE_39
                }
            }
        };

        private const int VK_VOLUME_UP = 0xAF;
        private const int VK_VOLUME_DOWN = 0xAE;
        private const ushort VK_RETURN = 0x0D;

        public MainForm()
        {
            ShowInTaskbar = false;
            WindowState = FormWindowState.Minimized;
            Load += (_, __) => OnLoaded();
            FormClosing += (_, __) => OnClosing();

            // Menü-Struktur erstellen
            _menu.Items.Add(new ToolStripMenuItem("Scan an/aus (Vol-)", null, (s, e) => ToggleScan()));
            _menu.Items.Add(new ToolStripSeparator());
            _menu.Items.Add(new ToolStripMenuItem("Kamera wählen (Wird geladen...)", null, null, "CameraSelectMenu"));
            _menu.Items.Add(new ToolStripSeparator());
            _menu.Items.Add(new ToolStripMenuItem("Beenden", null, (s, e) => Close()));

            // ICON KORREKTUR
            try
            {
                this.Icon = System.Drawing.Icon.ExtractAssociatedIcon(Application.ExecutablePath);
                _tray.Icon = this.Icon;
            }
            catch
            {
                _tray.Icon = SystemIcons.Application;
            }

            _tray.ContextMenuStrip = _menu;
            _tray.DoubleClick += (_, __) => ToggleScan();
        }

        private void OnLoaded()
        {
            _overlay.Show();
            KeyboardHook.Install(KeyHandler);
            _overlay.OnToggleRequested = ToggleScan;
            _overlay.OnResizeRequested = ResizeOverlay;

            InitializeCameraSelection();
            Hide();
        }

        private void OnClosing()
        {
            StopCaptureLoop();
            KeyboardHook.Uninstall();
            _tray.Visible = false;
            _overlay.Dispose();
        }

        private void UpdateTray(string msg) => _tray.Text = "QR Wedge — " + msg;

        // --- KAMERA-LOGIK ---

        private void InitializeCameraSelection()
        {
            // Die UsbCamera-Bibliothek liefert DeviceInfo-Objekte
            var devices = CameraService.GetDevices();
            _availableCameraIds = new List<int>();
            for(int i = 0; i < devices.Count; i++)
            {
                _availableCameraIds.Add(i);
            }

            _currentCameraId = _availableCameraIds.Count > 0 ? _availableCameraIds[0] : -1;

            BuildCameraMenu();

            if (_currentCameraId != -1)
            {
                _scanning = true;
                StartCaptureLoop();
                _overlay.BeginInvoke((Action)(() => _overlay.SetScanning(true)));
                UpdateTray($"Scan AKTIV (Kamera ID {_currentCameraId}) (Vol+ sendet, Vol- toggle)");
            }
            else
            {
                _scanning = false;
                UpdateTray("Keine Kamera gefunden");
                _overlay.BeginInvoke((Action)(() => _overlay.SetScanning(false)));
            }
        }

        /// <summary>
        /// Sucht verfügbare Kameras über die UsbCamera-Bibliothek.
        /// </summary>
        private List<int> FindAvailableCameras()
        {
            var devices = CameraService.GetDevices();
            var ids = new List<int>();

            for (int i = 0; i < devices.Count; i++)
            {
                ids.Add(i);
                AppLogger.Log($"[DEBUG] Kamera ID {i} gefunden: {devices[i].Name}");
            }
            return ids;
        }

        private void BuildCameraMenu()
        {
            var cameraMenu = _menu.Items.Find("CameraSelectMenu", false).Length > 0
                ? _menu.Items.Find("CameraSelectMenu", false)[0] as ToolStripMenuItem
                : null;

            if (cameraMenu == null) return;

            cameraMenu.Text = "Kamera wählen";
            cameraMenu.DropDownItems.Clear();

            var devices = CameraService.GetDevices(); // Aktuelle Geräteliste

            if (_availableCameraIds.Count == 0)
            {
                cameraMenu.DropDownItems.Add(new ToolStripMenuItem("Keine Kamera gefunden") { Enabled = false });
            }
            else
            {
                for (int i = 0; i < _availableCameraIds.Count; i++)
                {
                    int id = _availableCameraIds[i];

                    string designation = devices[id].Name; // Verwende den echten Namen

                    var item = new ToolStripMenuItem(designation, null, CameraMenuItem_Click)
                    {
                        Tag = id,
                        Checked = id == _currentCameraId
                    };
                    cameraMenu.DropDownItems.Add(item);
                }
            }
        }

        private void CameraMenuItem_Click(object? sender, EventArgs e)
        {
            if (sender is ToolStripMenuItem clickedItem && clickedItem.Tag is int newId)
            {
                if (newId == _currentCameraId) return;

                StopCaptureLoop();
                _currentCameraId = newId;

                BuildCameraMenu();

                _scanning = true;
                _overlay.BeginInvoke((Action)(() => _overlay.SetScanning(true)));
                StartCaptureLoop();
                UpdateTray($"Scan AKTIV (Kamera ID {_currentCameraId}) (Vol+ sendet, Vol- toggle)");
            }
        }

        private void ResizeOverlay()
        {
             StopCaptureLoop();
             _overlay.ResizeToNext();
             if (_scanning) StartCaptureLoop();
        }

        // --- ENDE KAMERA-LOGIK ---

        private void ToggleScan()
        {
             if (_currentCameraId == -1)
            {
                UpdateTray("Keine Kamera verfügbar.");
                SystemSounds.Hand.Play();
                return;
            }

            _scanning = !_scanning;

            _overlay.BeginInvoke((Action)(() => _overlay.ToggleCompactMode(!_scanning)));
            _overlay.BeginInvoke((Action)(() => _overlay.SetScanning(_scanning)));

            UpdateTray(_scanning
                ? $"Scan AKTIV (Kamera ID {_currentCameraId}) (Vol+ sendet, Vol- toggle)"
                : "Scan PAUSIERT");
            SystemSounds.Asterisk.Play();

            if (_scanning) StartCaptureLoop(); else StopCaptureLoop();
        }

        // --- NEUE CAPTURE-LOGIK (EVENT-BASIERT) ---
	private void StartCaptureLoop()
	{
	    if (_cameraService != null) return;
	    if (_currentCameraId == -1) return;

	    var devices = CameraService.GetDevices();
	    if (_currentCameraId >= devices.Count) return;

	    var deviceInfo = devices[_currentCameraId];
	    AppLogger.Log($"[INFO] Starte CameraService für {deviceInfo.Name} (ID {_currentCameraId})");

	    try
	    {
		// 1. Instanziieren des Dienstes
		// ❗ KORRIGIERT: CameraService benötigt nun nur noch die Kamera-ID.
		_cameraService = new CameraService(_currentCameraId);

		// 2. Event abonnieren
		_cameraService.FrameCaptured += CameraFrameReceived;

		// 3. Starten des Dienstes
		_cameraService.Start(_overlay.Handle, _overlay.Size);

		AppLogger.Log($"[DEBUG] CameraService gestartet.");
	    }
	    catch (Exception ex)
	    {
		AppLogger.LogError("Fehler beim Starten des CameraService", ex);
		StopCaptureLoop();
	    }
	}

        private void StopCaptureLoop()
        {
            if (_cameraService == null) return;

            AppLogger.Log($"[INFO] Stoppe CameraService (ID {_currentCameraId})");
            try
            {
                _cameraService.Stop();
                _cameraService.FrameCaptured -= CameraFrameReceived;
                _cameraService.Dispose();
                _cameraService = null;
            }
            catch (Exception ex)
            {
                 AppLogger.LogError("Fehler beim Stoppen des CameraService", ex);
            }
            // Zeige ein leeres Bild, wenn die Kamera gestoppt wird
            _overlay.BeginInvoke((Action)(() => _overlay.SetPreviewImage(new Bitmap(1, 1))));
        }

        private void CameraFrameReceived(object? sender, FrameCapturedEventArgs e)
        {
            if (!_scanning || !_overlay.IsHandleCreated) return;

            // Die UsbCamera-Bibliothek liefert ein Bitmap.
            // Wir müssen es klonen, bevor wir es im UI-Thread verwenden.
            using var bmp = (Bitmap)e.Bitmap.Clone();

            // 1. Übergabe an den UI-Thread
            var uiBmp = (Bitmap)bmp.Clone();
            _overlay.BeginInvoke((Action)(() =>
            {
                try
                {
                    // ❗ KORRIGIERT: CS0122 behoben: _preview ist jetzt public in PreviewOverlayForm
                    OverlayHelpers.SetPreviewImageSafe(_overlay._preview, uiBmp);
                }
                catch (Exception ex)
                {
                    AppLogger.LogError("GDI+ Fehler beim Zeichnen (DrawImage) im Event-Handler", ex);
                    uiBmp.Dispose();
                }
            }));

            // 2. Decode-Logik
            var result = DecodeBitmapWithZXing(bmp);
            if (result != null)
            {
                var text = (result.Text ?? "").Trim();
                if (!string.IsNullOrWhiteSpace(text))
                {
                    lock (_candidateLock) { _candidate = text; }
                    _overlay.BeginInvoke((Action)(() => _overlay.SetDetected(text)));
                }
            }
        }

        // --- DECODE & COMMIT ---

        // Die Decodier-Methode wird vereinfacht, da wir keine OpenCV-Mat-Konvertierung mehr haben
        private Result? DecodeBitmapWithZXing(Bitmap bmp)
        {
            if (bmp == null) return null;

            // Wir versuchen, die Bits im Format 24bppRgb zu sperren
            try
            {
                var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
                var bmpData = bmp.LockBits(rect, System.Drawing.Imaging.ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format24bppRgb);
                try
                {
                    int stride = Math.Abs(bmpData.Stride);
                    int size = stride * bmp.Height;
                    var buffer = new byte[size];
                    Marshal.Copy(bmpData.Scan0, buffer, 0, size);

                    // ZXing's RGBLuminanceSource erfordert die Angabe des Formats BGR24 für die Windows Bitmap-Daten
                    var source = new RGBLuminanceSource(buffer, bmp.Width, bmp.Height, RGBLuminanceSource.BitmapFormat.BGR24);

                    return _reader.Decode(source);
                }
                finally
                {
                    bmp.UnlockBits(bmpData);
                }
            }
            catch(Exception ex)
            {
                AppLogger.LogError("Fehler beim Dekodieren mit ZXing", ex);
                return null;
            }
        }

        private IntPtr KeyHandler(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode < 0) return KeyboardHook.CallNext(nCode, wParam, lParam);

            var msg = (int)wParam;
            var info = Marshal.PtrToStructure<KeyboardHook.KBDLLHOOKSTRUCT>(lParam)!;
            const int WM_KEYDOWN = 0x0100, WM_SYSKEYDOWN = 0x0104;

            if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN)
            {
                if (info.vkCode == VK_VOLUME_UP)
                {
                    CommitCandidate();
                    return (IntPtr)1;
                }
                if (info.vkCode == VK_VOLUME_DOWN)
                {
                    ToggleScan();
                    return (IntPtr)1;
                }
            }
            return KeyboardHook.CallNext(nCode, wParam, lParam);
        }

        private void CommitCandidate()
        {
            string text;
            lock (_candidateLock) text = _candidate;
            if (string.IsNullOrWhiteSpace(text)) { _overlay.BlinkBorder(Color.OrangeRed, 120); SystemSounds.Hand.Play(); return; }

            var win = TimeSpan.FromMilliseconds(_dupWindowMs);
            if (text == _lastCommitted && DateTime.UtcNow - _lastCommittedAt < win)
            {
                _overlay.BlinkBorder(Color.DarkGray, 120);
                return;
            }

            _lastCommitted = text;
            _lastCommittedAt = DateTime.UtcNow;

            SendUnicodeText(text);
            SendKey(VK_RETURN);

            _overlay.BeginInvoke((Action)(() => _overlay.SetCommitted(text)));
            _overlay.BlinkBorder(Color.LimeGreen, 120);
            SystemSounds.Asterisk.Play();
        }

        // --- SEND INPUT (Unverändert) ---
        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT { public uint type; public InputUnion U; }
        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion { [FieldOffset(0)] public KEYBDINPUT ki; }
        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }

        private const uint INPUT_KEYBOARD = 1;
        private const uint KEYEVENTF_KEYUP = 0x0002;
        private const uint KEYEVENTF_UNICODE = 0x0004;

        private static void SendUnicodeText(string text)
        {
            if (string.IsNullOrEmpty(text)) return;
            var inputs = new INPUT[text.Length * 2];
            int i = 0;
            foreach (var ch in text)
            {
                inputs[i++] = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = 0, wScan = ch, dwFlags = KEYEVENTF_UNICODE } } };
                inputs[i++] = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = 0, wScan = ch, dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP } } };
            }
            _ = SendInput((uint)inputs.Length, inputs, Marshal.SizeOf<INPUT>());
        }

        private static void SendKey(ushort vk)
        {
            var inputs = new INPUT[2];
            inputs[0] = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = vk } } };
            inputs[1] = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = vk, dwFlags = KEYEVENTF_KEYUP } } };
            _ = SendInput((uint)inputs.Length, inputs, Marshal.SizeOf<INPUT>());
        }
    }
}
