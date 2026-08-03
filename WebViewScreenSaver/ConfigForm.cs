using System.Windows.Forms;

namespace WebViewScreensaver
{
    public class ConfigForm : Form
    {
        private readonly TextBox _urlBox;

        public ConfigForm()
        {
            Text = "WebView Bildschirmschoner - Einstellungen";
            Width = 440;
            Height = 175;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;

            Settings settings = Settings.Load();

            var lblUrl = new Label { Text = "Webseite / Datei:", Left = 20, Top = 25, Width = 140 };
            _urlBox = new TextBox { Left = 170, Top = 22, Width = 165, Text = settings.Url };

            var btnBrowse = new Button { Text = "…", Left = 340, Top = 21, Width = 30 };
            btnBrowse.Click += (s, e) =>
            {
                using var dialog = new OpenFileDialog
                {
                    Title = "HTML-Datei auswaehlen",
                    Filter = "HTML-Dateien (*.html;*.htm)|*.html;*.htm|Alle Dateien (*.*)|*.*"
                };

                if (dialog.ShowDialog(this) == DialogResult.OK)
                {
                    _urlBox.Text = dialog.FileName;
                }
            };

            var hint = new Label
            {
                Text = "http://... / https://... oder lokaler Pfad (auch UNC, z.B. \\\\Server\\Share\\index.html)",
                Left = 20,
                Top = 50,
                Width = 400,
                ForeColor = System.Drawing.Color.Gray
            };

            var btnOk = new Button { Text = "Speichern", Left = 190, Top = 90, Width = 100, DialogResult = DialogResult.OK };
            var btnCancel = new Button { Text = "Abbrechen", Left = 300, Top = 90, Width = 100, DialogResult = DialogResult.Cancel };

            btnOk.Click += (s, e) =>
            {
                var newSettings = new Settings
                {
                    Url = _urlBox.Text.Trim()
                };
                newSettings.Save();
                Close();
            };
            btnCancel.Click += (s, e) => Close();

            AcceptButton = btnOk;
            CancelButton = btnCancel;

            Controls.AddRange(new Control[] { lblUrl, _urlBox, btnBrowse, hint, btnOk, btnCancel });
        }
    }
}
