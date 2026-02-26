/**
 * NitroPascal Runtime - Exceptions
 */

#pragma once

#include "runtime_types.h"
#include "runtime_string.h"
#include <thread>
#include <string>

namespace np {

// ============================================================================
// EXCEPTION HANDLING
// ============================================================================

struct Exception {
    std::wstring Message;
    
    Exception(const String& msg) : Message(msg.ToWString()) {}
    Exception(const std::wstring& msg) : Message(msg) {}
};

inline thread_local std::wstring _current_exception_message;

inline void RaiseException(const String& AMessage) {
    throw Exception(AMessage);
}

inline String GetExceptionMessage() {
    return String(_current_exception_message);
}

} // namespace np
