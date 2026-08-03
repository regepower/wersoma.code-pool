using System;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace WebViewScreensaver
{
    public class ScreensaverForm : Form
    {
        private readonly WebView2 _webView;
        private readonly CoreWebView2Environment _environment;
        private Point _lastMousePos;
        private readonly Timer _inputWatchTimer;

        public ScreensaverForm(Screen screen, CoreWebView2Environment environment)
        {
            _environment = environment;

            FormBorderStyle = FormBorderStyle.None;
            Bounds = screen.Bounds;
            TopMost = true;
            BackColor = Color.Black;
            ShowInTaskbar = false;
            Cursor.Hide();

            _webView = new WebView2 { Dock = DockStyle.Fill };
            Controls.Add(_webView);

            Settings settings = Settings.Load();

            Load += async (s, e) =>
            {
                try
                {
                    await _webView.EnsureCoreWebView2Async(_environment);

                    _webView.CoreWebView2.NavigationCompleted += (s2, e2) =>
                    {
                        if (!e2.IsSuccess)
                        {
                            ShowError(
                                "Seite konnte nicht geladen werden.\n" +
                                $"Fehler: {e2.WebErrorStatus}\n\n" +
                                $"Pfad/URL: {settings.Url}");
                        }
                    };

                    string uri = UrlHelper.ToNavigableUri(settings.Url);
                    _webView.CoreWebView2.Navigate(uri);
                }
                catch (Exception ex)
                {
                    ShowError($"Fehler beim Initialisieren von WebView2:\n{ex.Message}");
                }
            };

            _lastMousePos = Cursor.Position;

            KeyPreview = true;
            KeyDown += (s, e) => Application.Exit();
            MouseClick += (s, e) => Application.Exit();

            // Regelmaessig prüfen, ob sich die Maus bewegt hat (WebView2 verschluckt
            // sonst manche globalen Maus-Events im eingebetteten Browserfenster).
            _inputWatchTimer = new Timer { Interval = 200 };
            _inputWatchTimer.Tick += (s, e) =>
            {
                if (Cursor.Position != _lastMousePos)
                {
                    Application.Exit();
                }
            };
            _inputWatchTimer.Start();
        }

        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            Cursor.Show();
            base.OnFormClosed(e);
        }

        private void ShowError(string message)
        {
            if (InvokeRequired)
            {
                Invoke(new Action(() => ShowError(message)));
                return;
            }

            var label = new Label
            {
                Text = message,
                ForeColor = Color.White,
                BackColor = Color.Black,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Segoe UI", 14)
            };
            Controls.Add(label);
            label.BringToFront();
        }
    }
}
