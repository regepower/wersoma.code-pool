using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using GitHub.secile.Video;
using System.Windows.Forms;

namespace QrWedge
{
    /// <summary>
    /// Event-Argumente für ein aufgenommenes Bild (Frame).
    /// </summary>
    public class FrameCapturedEventArgs : EventArgs
    {
        public Bitmap Bitmap { get; }

        public FrameCapturedEventArgs(Bitmap bitmap)
        {
            Bitmap = bitmap;
        }
    }

    /// <summary>
    /// Wrapper-Service für die UsbCamera-Klasse.
    /// </summary>
    public sealed class CameraService : IDisposable
    {
        private readonly UsbCamera _camera;

        /// <summary>Tritt auf, wenn ein neuer Frame von der Kamera aufgenommen wurde.</summary>
        public event EventHandler<FrameCapturedEventArgs>? FrameCaptured;

        // Dummy-Struktur für die Gerätedefinition, basierend auf der Verwendung in MainForm.cs
        public struct CameraDevice
        {
            public string Name { get; set; }
            public int Index { get; set; }
        }

        // ❗ KORREKTUR: Der Konstruktor erwartet nun KEINE Size mehr.
        public CameraService(int cameraIndex)
        {
            // 1. Verfügbare Formate der Kamera abrufen.
            var formats = UsbCamera.GetVideoFormat(cameraIndex);

            if (formats.Length == 0)
            {
                AppLogger.LogError($"Kamera Index {cameraIndex} liefert keine Videoformate.", new InvalidOperationException());
                throw new InvalidOperationException("Die Kamera unterstützt keine Videoformate.");
            }

            // 2. Das erste Format als Standard verwenden (am zuverlässigsten).
            var selectedFormat = formats[0];

            // Optionale Protokollierung für Debugging
            AppLogger.Log($"[INFO] Kamera {cameraIndex} ({UsbCamera.FindDevices()[cameraIndex]}) wählt Format {selectedFormat.Size.Width}x{selectedFormat.Size.Height} für die Initialisierung.");

            // 3. UsbCamera mit dem expliziten VideoFormat initialisieren.
            // Dadurch wird ein häufiges Problem mit Format-Inkompatibilität behoben.
            _camera = new UsbCamera(cameraIndex, selectedFormat);

            // Setzt den Callback für aufgenommene Frames
            _camera.PreviewCaptured = OnPreviewCaptured;
        }

        /// <summary>
        /// Sucht alle verfügbaren Kameras.
        /// </summary>
        public static IList<CameraDevice> GetDevices()
        {
            var devices = UsbCamera.FindDevices();
            return devices.Select((name, index) => new CameraDevice { Name = name, Index = index }).ToList();
        }

        /// <summary>
        /// Startet die Videoaufnahme.
        /// </summary>
        public void Start(IntPtr previewHandle, Size previewSize)
        {
            // FIX (aus vorherigem Schritt): SetPreviewControl bleibt entfernt,
            // da die Anzeige über das Event in MainForm erfolgt.

            _camera.Start();
        }

        /// <summary>
        /// Stoppt die Videoaufnahme.
        /// </summary>
        public void Stop()
        {
            _camera.Stop();
        }

        private void OnPreviewCaptured(Bitmap bmp)
        {
            // Löst das FrameCaptured-Event im QrWedge-Kontext aus
            FrameCaptured?.Invoke(this, new FrameCapturedEventArgs(bmp));
        }

        public void Dispose()
        {
            _camera.Release();
        }
    }
}
