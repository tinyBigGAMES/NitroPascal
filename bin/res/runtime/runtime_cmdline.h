/**
 * NitroPascal Runtime - Command Line Parameters
 */

#pragma once

#include "runtime_types.h"
#include "runtime_string.h"

namespace np {

// ============================================================================
// COMMAND LINE PARAMETERS
// ============================================================================

inline int _argc = 0;
inline char** _argv = nullptr;

inline void InitCommandLine(int argc, char* argv[]) {
    _argc = argc;
    _argv = argv;
}

inline Integer ParamCount() {
    return _argc - 1;
}

inline String ParamStr(const Integer AIndex) {
    if (AIndex < 0 || AIndex >= _argc) {
        return String(u"");
    }
    return String(_argv[AIndex]);
}

} // namespace np
