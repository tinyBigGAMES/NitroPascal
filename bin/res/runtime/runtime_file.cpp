/**
 * NitroPascal Runtime - File I/O Implementation
 */

#include "runtime_file.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

namespace np {

Boolean DirectoryExists(const String& ADirName) {
    std::string dname(ADirName.Data().begin(), ADirName.Data().end());
#ifdef _WIN32
    DWORD attrs = GetFileAttributesA(dname.c_str());
    return (attrs != INVALID_FILE_ATTRIBUTES && (attrs & FILE_ATTRIBUTE_DIRECTORY));
#else
    struct stat info;
    return (stat(dname.c_str(), &info) == 0 && S_ISDIR(info.st_mode));
#endif
}

Boolean CreateDir(const String& ADirName) {
    std::string dname(ADirName.Data().begin(), ADirName.Data().end());
#ifdef _WIN32
    return CreateDirectoryA(dname.c_str(), NULL) != 0;
#else
    return mkdir(dname.c_str(), 0755) == 0;
#endif
}

String GetCurrentDir() {
    char buffer[FILENAME_MAX];
#ifdef _WIN32
    GetCurrentDirectoryA(FILENAME_MAX, buffer);
#else
    getcwd(buffer, FILENAME_MAX);
#endif
    return String(buffer);
}

} // namespace np
