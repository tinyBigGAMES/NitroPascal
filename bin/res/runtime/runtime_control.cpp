/**
 * NitroPascal Runtime - Control Flow Implementation
 */

#include "runtime_control.h"
#include <cstdlib>
#include <cstdio>

namespace np {

// Control flow functions are header-only (templates)

// ============================================================================
// PROGRAM CONTROL
// ============================================================================

void Halt(Integer exitCode) {
    std::exit(static_cast<int>(exitCode));
}

void RunError(Integer errorCode) {
    std::fprintf(stderr, "Runtime error %d\n", static_cast<int>(errorCode));
    std::exit(static_cast<int>(errorCode));
}

void Abort() {
    std::abort();
}

} // namespace np
