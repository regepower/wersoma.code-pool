using System;

namespace WebViewScreensaver
{
    public static class UrlHelper
    {
        /// <summary>
        /// Wandelt eine Benutzereingabe (http/https-URL, file://-URI, lokaler Pfad
        /// wie "N:\Ordner\index.html" oder UNC-Pfad wie "\\Server\Share\index.html")
        /// in eine korrekt kodierte, navigierbare URI um.
        /// .NET's Uri-Klasse erkennt Laufwerksbuchstaben und UNC-Pfade automatisch
        /// und wandelt sie in eine gueltige file://-URI inkl. Prozent-Encoding von
        /// Sonderzeichen (z.B. Umlaute) um.
        /// </summary>
        public static string ToNavigableUri(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
            {
                return "about:blank";
            }

            input = input.Trim();

            if (Uri.TryCreate(input, UriKind.Absolute, out Uri uri))
            {
                return uri.AbsoluteUri;
            }

            // Konnte nicht als URI erkannt werden - unveraendert zurueckgeben,
            // WebView2 zeigt dann einen Navigationsfehler an (siehe NavigationCompleted
            // in ScreensaverForm), statt dass die Anwendung abstuerzt.
            return input;
        }
    }
}
