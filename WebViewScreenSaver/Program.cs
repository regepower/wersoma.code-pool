using System;
using System.Windows.Forms;

namespace WebViewScreensaver
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string arg = args.Length > 0 ? args[0].Trim().ToLowerInvariant() : string.Empty;

            if (arg.StartsWith("/s"))
            {
                // Vollbild-Bildschirmschoner starten (auf allen Monitoren)
                Application.Run(new ScreensaverApplicationContext());
            }
            else if (arg.StartsWith("/p"))
            {
                // Vorschau im kleinen Fenster der Windows-Einstellungen.
                // Wird hier bewusst einfach gehalten: leeres Vorschaufenster reicht meist aus,
                // da diese Miniaturansicht selten kritisch ist.
                return;
            }
            else
            {
                // "/c", "/c:<hwnd>" oder ganz ohne Parameter (z.B. Doppelklick) -> Konfiguration
                Application.Run(new ConfigForm());
            }
        }
    }
}
