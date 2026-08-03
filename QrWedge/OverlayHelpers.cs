using System;
using System.Drawing;
using System.Windows.Forms;

namespace QrWedge
{
    // Hilfsmethoden für sicheres Setzen des Preview-Bildes aus einem Background-Thread.
    public static class OverlayHelpers
    {
        // Setzt ein Preview-Bild in eine PictureBox thread-sicher.
        // - pictureBox: das Ziel-Control (üblicherweise ein Feld in Deiner Overlay-Klasse)
        // - bmp: das zu setzende Bitmap (die Methode klont das Bitmap, damit der Producer das Original frei geben kann)
        public static void SetPreviewImageSafe(PictureBox pictureBox, Bitmap bmp)
        {
            if (pictureBox == null)
            {
                bmp?.Dispose();
                return;
            }

            if (bmp == null)
            {
                // Entferne Bild sicher auf UI-Thread
                if (pictureBox.InvokeRequired)
                {
                    pictureBox.BeginInvoke((MethodInvoker)(() =>
                    {
                        var old = pictureBox.Image;
                        pictureBox.Image = null;
                        old?.Dispose();
                    }));
                }
                else
                {
                    var old = pictureBox.Image;
                    pictureBox.Image = null;
                    old?.Dispose();
                }
                return;
            }

            Bitmap copy;
            try
            {
                copy = (Bitmap)bmp.Clone();
            }
            catch
            {
                // Falls Clone fehlschlägt, versuche, das Original zu verwenden (noch besser wäre vorher sicherzustellen, dass bmp nicht shared ist)
                copy = bmp;
            }

            void SetImageAction()
            {
                try
                {
                    var old = pictureBox.Image;
                    pictureBox.Image = copy;
                    old?.Dispose();
                }
                catch
                {
                    // Falls das Setzen oder Dispose fehlschlägt, versuche, das neue Bild zu entsorgen
                    try { copy?.Dispose(); } catch { }
                }
            }

            if (pictureBox.InvokeRequired)
            {
                pictureBox.BeginInvoke((MethodInvoker)SetImageAction);
            }
            else
            {
                SetImageAction();
            }
        }
    }
}
