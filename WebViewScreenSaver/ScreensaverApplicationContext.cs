using System;
using System.IO;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;

namespace WebViewScreensaver
{
    public class ScreensaverApplicationContext : ApplicationContext
    {
        public ScreensaverApplicationContext()
        {
            // Eigener, garantiert beschreibbarer Datenordner (wichtig, da die .scr
            // z.B. in C:\Windows\System32 liegen kann, wo kein Schreibzugriff besteht).
            string userDataFolder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "WebViewScreensaver", "WebView2");

            CoreWebView2Environment environment;
            try
            {
                // Eine einzige, gemeinsame Environment-Instanz fuer alle Monitore -
                // verhindert, dass mehrere WebView2-Instanzen gleichzeitig denselben
                // Datenordner sperren wollen (Fehler 0x800700AA / ERROR_BUSY).
                environment = CoreWebView2Environment.CreateAsync(userDataFolder: userDataFolder)
                    .GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"WebView2 konnte nicht initialisiert werden:\n{ex.Message}",
                    "WebViewScreensaver",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                ExitThread();
                return;
            }

            foreach (Screen screen in Screen.AllScreens)
            {
                var form = new ScreensaverForm(screen, environment);
                form.FormClosed += (s, e) => ExitThread();
                form.Show();
            }
        }
    }
}

