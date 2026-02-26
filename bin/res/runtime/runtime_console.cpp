/**
 * NitroPascal Runtime - Console I/O Implementation
 */

#include "runtime_console.h"

#ifdef _WIN32
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#endif

namespace np {

void InitializeConsole() {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
    _setmode(_fileno(stdout), _O_BINARY);
    _setmode(_fileno(stderr), _O_BINARY);
    HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hOut != INVALID_HANDLE_VALUE) {
        DWORD dwMode = 0;
        if (GetConsoleMode(hOut, &dwMode)) {
            dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            SetConsoleMode(hOut, dwMode);
        }
    }
#endif
}

} // namespace np
