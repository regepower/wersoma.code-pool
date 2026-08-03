using Microsoft.Win32;

namespace WebViewScreensaver
{
    public class Settings
    {
        private const string RegPath = @"Software\WebViewScreensaver";

        public string Url { get; set; } = "https://example.com";

        public static Settings Load()
        {
            var settings = new Settings();

            using RegistryKey key = Registry.CurrentUser.OpenSubKey(RegPath);
            if (key != null)
            {
                settings.Url = key.GetValue("Url", settings.Url) as string ?? settings.Url;
            }

            return settings;
        }

        public void Save()
        {
            using RegistryKey key = Registry.CurrentUser.CreateSubKey(RegPath);
            key.SetValue("Url", Url);
        }
    }
}
