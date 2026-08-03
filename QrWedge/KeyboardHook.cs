using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace QrWedge
{
    internal static class KeyboardHook
    {
        private static IntPtr _hhk = IntPtr.Zero;
        private static HookProc? _proc;
        private static Func<int, IntPtr, IntPtr, IntPtr>? _handler;

        private const int WH_KEYBOARD_LL = 13;

        public static void Install(Func<int, IntPtr, IntPtr, IntPtr> handler)
        {
            if (_hhk != IntPtr.Zero) return;
            _handler = handler;
            _proc = HookProcImpl;
            using var cur = Process.GetCurrentProcess();
            using var mod = cur.MainModule!;
            _hhk = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(mod.ModuleName), 0);
            if (_hhk == IntPtr.Zero)
                throw new InvalidOperationException("KeyboardHook Install failed.");
        }

        public static void Uninstall()
        {
            if (_hhk != IntPtr.Zero)
            {
                UnhookWindowsHookEx(_hhk);
                _hhk = IntPtr.Zero;
                _proc = null;
                _handler = null;
            }
        }

        private static IntPtr HookProcImpl(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (_handler is null) return CallNext(nCode, wParam, lParam);
            return _handler(nCode, wParam, lParam);
        }

        public static IntPtr CallNext(int nCode, IntPtr wParam, IntPtr lParam)
            => CallNextHookEx(_hhk, nCode, wParam, lParam);

        [StructLayout(LayoutKind.Sequential)]
        public struct KBDLLHOOKSTRUCT
        {
            public int vkCode; public int scanCode; public int flags; public int time; public IntPtr dwExtraInfo;
        }

        private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll")]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll")]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);
    }
}
