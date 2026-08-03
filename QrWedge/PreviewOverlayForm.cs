// FILE: QrWedge/PreviewOverlayForm.cs

using System;
using System.Drawing;
using System.Windows.Forms;
using System.Collections.Generic;

namespace QrWedge
{
    public sealed class PreviewOverlayForm : Form
    {
        // ❗ KORRIGIERT: GEÄNDERT von private/implizit auf public, um CS0122 in MainForm zu beheben
        public readonly PictureBox _preview = new() { Dock = DockStyle.Fill, SizeMode = PictureBoxSizeMode.Zoom }; 
        private readonly Label _badge = new()
        {
            AutoSize = true,
            BackColor = Color.FromArgb(180, 0, 0, 0),
            ForeColor = Color.White,
            Padding = new Padding(6, 3, 6, 3)
        };

        private readonly System.Windows.Forms.Timer _blinkTmr = new() { Interval = 150 };
        private Color _borderColor = Color.DimGray;

        // --- Notwendige Felder und Events für die Kommunikation mit MainForm ---
        public Action? OnToggleRequested;
        public Action? OnResizeRequested;

        // Definition der Größen: (W, H)
        public readonly (int W, int H)[] _fullSizes = new[]
        {
            (160, 120), // Mini
            (320, 240), // Klein (Standard)
            (480, 360)  // Standard
        };
        public int _currentSizeIndex = 1;
        private bool _compactMode = false;

        public PreviewOverlayForm()
        {
            // Windows Form Eigenschaften
            TopMost = true;
            Text = "QR Wedge Preview";
            Size = new Size(_fullSizes[_currentSizeIndex].W, _fullSizes[_currentSizeIndex].H);
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.Manual;
            Location = new Point(Screen.PrimaryScreen!.Bounds.Width - Width - 100, Screen.PrimaryScreen.Bounds.Height - Height - 100);

            // Container-Eigenschaften
            BackColor = Color.Black;
            TransparencyKey = Color.Magenta; // Farbschlüssel für Transparenz (falls benötigt)

            // Steuerelemente hinzufügen
            Controls.Add(_preview);
            Controls.Add(_badge);

            // Events
            _blinkTmr.Tick += (_, __) => Invalidate();
            Paint += (_, e) => DrawBorder(e);
            Layout += (_, __) => LayoutBadge();

            // Setzt den Initialzustand des Badges
            SetScanning(false);
        }

        // --- Öffentliche Methoden für MainForm ---

        public void SetPreviewImage(Bitmap bmp)
        {
            OverlayHelpers.SetPreviewImageSafe(_preview, bmp);
        }

        public void SetScanning(bool scanning)
        {
            _badge.Text = scanning ? "SCAN AKTIV" : "PAUSIERT";
            _borderColor = scanning ? Color.Green : Color.DimGray;
            Invalidate(); // Neu zeichnen, um Rahmen zu aktualisieren
        }

        public void SetDetected(string code)
        {
            _badge.Text = $"GEFUNDEN: {Short(code, 20)}";
        }

        public void SetCommitted(string code)
        {
            _badge.Text = $"GESENDET: {Short(code, 20)}";
        }

        public void BlinkBorder(Color color, int durationMs)
        {
            var originalColor = _borderColor;
            _borderColor = color;
            Invalidate();

            // Blinken nach Zeit beenden
            if (_blinkTmr.Enabled) _blinkTmr.Stop();
            _blinkTmr.Interval = durationMs;
            _blinkTmr.Tick += (s, e) =>
            {
                _blinkTmr.Stop();
                _borderColor = originalColor;
                Invalidate();
            };
            _blinkTmr.Start();
        }

        public void ToggleCompactMode(bool compact)
        {
            _compactMode = compact;
            if (compact)
            {
                // Setze auf kompakte Größe
                Size = new Size(100, 30);
                // Badge immer in der Mitte
                _badge.Anchor = AnchorStyles.None;
                _badge.Location = new Point((Width - _badge.Width) / 2, (Height - _badge.Height) / 2);
                _preview.Visible = false;
            }
            else
            {
                // Zurück zur vollen Größe
                var (w, h) = _fullSizes[_currentSizeIndex];
                Size = new Size(w, h);
                // Badge oben links
                _badge.Anchor = AnchorStyles.Top | AnchorStyles.Left;
                _preview.Visible = true;
            }
        }

        public void ResizeToNext()
        {
            _currentSizeIndex = (_currentSizeIndex + 1) % _fullSizes.Length;
            var (w, h) = _fullSizes[_currentSizeIndex];
            Size = new Size(w, h);
            Location = new Point(Screen.PrimaryScreen!.Bounds.Width - Width - 100, Screen.PrimaryScreen.Bounds.Height - Height - 100);
            Invalidate();
        }


        // --- UI Rendering ---

        private void DrawBorder(PaintEventArgs e)
        {
            using var pen = new Pen(_borderColor, 4);
            e.Graphics.DrawRectangle(pen, 0, 0, Width - 1, Height - 1);
        }

        private void LayoutBadge()
        {
            _badge.Left = 8;
            _badge.Top = 8;
        }

        private static string Short(string s, int n) => s.Length <= n ? s : s.Substring(0, n - 1) + "…";

        // --- Drag- and Event-Logik ---
        private const int WM_NCLBUTTONDOWN = 0xA1;
        private const int HTCAPTION = 0x02;
        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool ReleaseCapture();
        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button == MouseButtons.Left)
            {
                ReleaseCapture();
                SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
            }
        }

        protected override void OnMouseDoubleClick(MouseEventArgs e)
        {
            base.OnMouseDoubleClick(e);
            OnToggleRequested?.Invoke();
        }

        protected override void OnMouseClick(MouseEventArgs e)
        {
            base.OnMouseClick(e);
            if (e.Button == MouseButtons.Right)
            {
                OnResizeRequested?.Invoke();
            }
        }
    }
}