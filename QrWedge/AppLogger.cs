// FILE: QrWedge/AppLogger.cs
using System;
using System.IO;
using System.Reflection;

namespace QrWedge
{
    // Eine einfache statische Klasse für die Protokollierung in eine Datei (neben der EXE).
    public static class AppLogger
    {
        private static readonly string LogFilePath;

        static AppLogger()
        {
            string logDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? ".";
            LogFilePath = Path.Combine(logDirectory, "QrWedge.log");
        }

        public static void Log(string message)
        {
            try
            {
                string logEntry = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [INFO] {message}{Environment.NewLine}";
                File.AppendAllText(LogFilePath, logEntry);
            }
            catch (Exception)
            {
                // Fehler bei der Protokollierung ignorieren, um keine Endlosschleife zu erzeugen
            }
        }

        public static void LogError(string message, Exception ex)
        {
            try
            {
                string logEntry = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [ERROR] {message}{Environment.NewLine}";
                logEntry += $"Exception: {ex.GetType().Name} - {ex.Message}{Environment.NewLine}{ex.StackTrace}{Environment.NewLine}";
                File.AppendAllText(LogFilePath, logEntry);
            }
            catch (Exception)
            {
                // Fehler bei der Protokollierung ignorieren
            }
        }
    }
}
