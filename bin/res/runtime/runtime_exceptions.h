/**
 * NitroPascal Runtime - Exception Handling
 *
 * Provides full hardware + software exception support for both Windows
 * (Vectored Exception Handler) and POSIX (signal handlers).
 *
 * Pascal semantics:
 *   try..except        -> np::TryCatch(tryFn, catchFn)
 *   try..finally       -> np::TryFinally(tryFn, finallyFn)
 *   try..except..finally -> np::TryCatchFinally(tryFn, catchFn, finallyFn)
 *   raiseexception(msg)       -> np::RaiseException(msg)
 *   raiseexceptioncode(c,msg) -> np::RaiseException(c, msg)
 *   getexceptionmessage()     -> np::GetExceptionMessage()
 *   getexceptioncode()        -> np::GetExceptionCode()
 */

#pragma once

#include "runtime_types.h"
#include "runtime_string.h"

namespace np {

// ============================================================================
// INTERNAL
// ============================================================================

// _Exception, EXC_* constants, _g_exc_code, _g_exc_msg, _g_jmp_target
// are all defined in runtime_types.h so every module can use them.

// Installed once per process. Defined in runtime_exceptions.cpp.
void _InstallHardwareHandlers();

// ============================================================================
// INTERNAL HELPERS
// ============================================================================

// Narrow ASCII -> wide string for std::exception::what() messages.
inline std::wstring _AsciiToWide(const char* AStr) {
    if (!AStr)
        return L"";
    return std::wstring(AStr, AStr + std::strlen(AStr));
}

// ============================================================================
// PUBLIC API
// ============================================================================

// Raise a software exception with a message only (code = EXC_SOFTWARE).
inline void RaiseException(const String& AMessage) {
    throw _Exception{EXC_SOFTWARE, AMessage.ToWString()};
}

// Raise a software exception with an explicit code and message.
inline void RaiseException(Integer ACode, const String& AMessage) {
    throw _Exception{ACode, AMessage.ToWString()};
}

// Retrieve the message from the most recently caught exception.
inline String GetExceptionMessage() {
    return String(_g_exc_msg);
}

// Retrieve the code from the most recently caught exception.
inline Integer GetExceptionCode() {
    return _g_exc_code;
}

// ============================================================================
// TRY WRAPPERS
// ============================================================================

// --- try..except ---
// try_fn  : the protected body
// catch_fn: the except handler; GetExceptionCode/Message are valid inside it
template<typename TryFn, typename CatchFn>
inline void TryCatch(TryFn try_fn, CatchFn catch_fn) {
    _InstallHardwareHandlers();

    jmp_buf                  buf;
    volatile jmp_buf*        old_target     = _g_jmp_target;
    volatile bool            had_exception  = false;
    _g_jmp_target = &buf;

    int jmp_result = setjmp(buf);

    if (jmp_result == 0) {
        // Normal path: run the try body inside a C++ try so software
        // exceptions are caught here rather than via longjmp.
        try {
            try_fn();
        }
        catch (const _Exception& e) {
            _g_exc_code   = e.code;
            _g_exc_msg    = e.msg;
            had_exception = true;
        }
        catch (const std::exception& e) {
            _g_exc_code   = EXC_SOFTWARE;
            _g_exc_msg    = _AsciiToWide(e.what());
            had_exception = true;
        }
        catch (...) {
            _g_exc_code   = EXC_SOFTWARE;
            _g_exc_msg    = L"Unknown exception";
            had_exception = true;
        }
    }
    else {
        // Hardware exception path: state was already written by the VEH /
        // signal handler before it called longjmp.
        had_exception = true;
    }

    _g_jmp_target = const_cast<jmp_buf*>(old_target);

    if (had_exception) {
        catch_fn();
    }
}

// --- try..finally ---
// try_fn    : the protected body
// finally_fn: always runs; if try_fn raised, exception re-propagates after
template<typename TryFn, typename FinallyFn>
inline void TryFinally(TryFn try_fn, FinallyFn finally_fn) {
    _InstallHardwareHandlers();

    jmp_buf           buf;
    volatile jmp_buf* old_target    = _g_jmp_target;
    volatile bool     had_exception = false;
    _g_jmp_target = &buf;

    int jmp_result = setjmp(buf);

    if (jmp_result == 0) {
        try {
            try_fn();
        }
        catch (const _Exception& e) {
            _g_exc_code   = e.code;
            _g_exc_msg    = e.msg;
            had_exception = true;
        }
        catch (const std::exception& e) {
            _g_exc_code   = EXC_SOFTWARE;
            _g_exc_msg    = _AsciiToWide(e.what());
            had_exception = true;
        }
        catch (...) {
            _g_exc_code   = EXC_SOFTWARE;
            _g_exc_msg    = L"Unknown exception";
            had_exception = true;
        }
    }
    else {
        had_exception = true;
    }

    _g_jmp_target = const_cast<jmp_buf*>(old_target);

    // Save exception state -- finally_fn may itself raise an exception.
    Integer      saved_code = _g_exc_code;
    std::wstring saved_msg  = _g_exc_msg;

    finally_fn();

    if (had_exception) {
        // Restore state and re-propagate so the caller sees the original fault.
        _g_exc_code = saved_code;
        _g_exc_msg  = saved_msg;
        throw _Exception{saved_code, saved_msg};
    }
}

// --- try..except..finally ---
// try_fn    : the protected body
// catch_fn  : the except handler (swallows the exception)
// finally_fn: always runs after catch_fn (no re-propagation)
template<typename TryFn, typename CatchFn, typename FinallyFn>
inline void TryCatchFinally(TryFn try_fn, CatchFn catch_fn, FinallyFn finally_fn) {
    _InstallHardwareHandlers();

    jmp_buf           buf;
    volatile jmp_buf* old_target    = _g_jmp_target;
    volatile bool     had_exception = false;
    _g_jmp_target = &buf;

    int jmp_result = setjmp(buf);

    if (jmp_result == 0) {
        try {
            try_fn();
        }
        catch (const _Exception& e) {
            _g_exc_code   = e.code;
            _g_exc_msg    = e.msg;
            had_exception = true;
        }
        catch (const std::exception& e) {
            _g_exc_code   = EXC_SOFTWARE;
            _g_exc_msg    = _AsciiToWide(e.what());
            had_exception = true;
        }
        catch (...) {
            _g_exc_code   = EXC_SOFTWARE;
            _g_exc_msg    = L"Unknown exception";
            had_exception = true;
        }
    }
    else {
        had_exception = true;
    }

    _g_jmp_target = const_cast<jmp_buf*>(old_target);

    if (had_exception) {
        catch_fn();
    }

    // Finally always runs; exception was swallowed by catch_fn.
    finally_fn();
}

} // namespace np
