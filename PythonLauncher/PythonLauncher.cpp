
#include <windows.h>
#include <shellapi.h>
#include <string>

#pragma comment(lib, "shell32.lib")

// ======================================
// Fester Python-Pfad
// ======================================

const wchar_t* PYTHON_HOME =
    L"\\\\File01\\Fertigung\\Download\\PortableApps\\Python";

const wchar_t* PYTHON_EXE =
    L"\\\\File01\\Fertigung\\Download\\PortableApps\\Python\\python.exe";


// ======================================

void ErrorMessage(const wchar_t* text)
{
    MessageBoxW(
        nullptr,
        text,
        L"PythonLauncher",
        MB_ICONERROR | MB_OK
    );
}


int WINAPI wWinMain(
    HINSTANCE,
    HINSTANCE,
    PWSTR,
    int)
{

    // Python vorhanden?

    if (GetFileAttributesW(PYTHON_EXE) == INVALID_FILE_ATTRIBUTES)
    {
        ErrorMessage(
            L"Python wurde nicht gefunden.\n\n"
            L"Pfad:\n"
            L"\\\\File01\\Fertigung\\Download\\PortableApps\\Python"
        );

        return 1;
    }


    // Kommandozeile auswerten

    int argc;

    LPWSTR* argv =
        CommandLineToArgvW(
            GetCommandLineW(),
            &argc
        );


    if (argc < 2)
    {
        ErrorMessage(
            L"Keine Python-Datei angegeben."
        );

        return 2;
    }


    // Python Umgebung setzen

    SetEnvironmentVariableW(
        L"PYTHONHOME",
        PYTHON_HOME
    );


    SetEnvironmentVariableW(
        L"PYTHONPATH",
        PYTHON_HOME
    );


    // PATH erweitern

    wchar_t oldPath[32768];

    GetEnvironmentVariableW(
        L"PATH",
        oldPath,
        32768
    );


    std::wstring newPath =
        std::wstring(PYTHON_HOME)
        + L";"
        + std::wstring(PYTHON_HOME)
        + L"\\Scripts;"
        + oldPath;


    SetEnvironmentVariableW(
        L"PATH",
        newPath.c_str()
    );


    // Python Kommando erzeugen

    std::wstring command;

    command += L"\"";
    command += PYTHON_EXE;
    command += L"\"";


    for (int i = 1; i < argc; i++)
    {
        command += L" \"";
        command += argv[i];
        command += L"\"";
    }


    // Python starten

    STARTUPINFOW si{};
    PROCESS_INFORMATION pi{};

    si.cb = sizeof(si);


    if (!CreateProcessW(
        nullptr,
        command.data(),
        nullptr,
        nullptr,
        FALSE,
        0,
        nullptr,
        nullptr,
        &si,
        &pi))
    {
        ErrorMessage(
            L"Python konnte nicht gestartet werden."
        );

        return 3;
    }


    WaitForSingleObject(
        pi.hProcess,
        INFINITE
    );


    DWORD exitCode = 0;

    GetExitCodeProcess(
        pi.hProcess,
        &exitCode
    );


    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);


    return exitCode;
}