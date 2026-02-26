/**
 * NitroPascal Runtime - Exception Handling Implementation
 *
 * Platform-specific hardware exception handlers:
 *   Windows : Vectored Exception Handler (VEH) via AddVectoredExceptionHandler
 *   POSIX   : signal handlers for SIGFPE, SIGSEGV, SIGBUS, SIGILL
 *
 * The handler writes the exception code and message into thread-local storage
 * and then longjmps back to the setjmp point established by TryCatch /
 * TryFinally / TryCatchFinally, allowing hardware faults to be caught by
 * Pascal try..except blocks just like software exceptions.
 */

#include "runtime_exceptions.h"

#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
#else
    #include <signal.h>
#endif

namespace np {

// ============================================================================
// WINDOWS: VECTORED EXCEPTION HANDLER
// ============================================================================

#ifdef _WIN32

static bool _IsHardwareException(DWORD ACode) {
    switch (ACode) {
        case EXCEPTION_ACCESS_VIOLATION:
        case EXCEPTION_IN_PAGE_ERROR:
        case EXCEPTION_INT_DIVIDE_BY_ZERO:
        case EXCEPTION_FLT_DIVIDE_BY_ZERO:
        case EXCEPTION_FLT_INVALID_OPERATION:
        case EXCEPTION_STACK_OVERFLOW:
        case EXCEPTION_INT_OVERFLOW:
        case EXCEPTION_FLT_OVERFLOW:
        case EXCEPTION_FLT_UNDERFLOW:
        case EXCEPTION_ILLEGAL_INSTRUCTION:
        case EXCEPTION_PRIV_INSTRUCTION:
            return true;
        default:
            return false;
    }
}

static LONG WINAPI _NpVehHandler(PEXCEPTION_POINTERS AEp) {
    // Only handle this if a Pascal try block is active on this thread.
    if (_g_jmp_target == nullptr)
        return EXCEPTION_CONTINUE_SEARCH;

    DWORD LCode = AEp->ExceptionRecord->ExceptionCode;
    if (!_IsHardwareException(LCode))
        return EXCEPTION_CONTINUE_SEARCH;

    // Map Windows exception code to NitroPascal exception code + message.
    switch (LCode) {
        case EXCEPTION_ACCESS_VIOLATION:
        case EXCEPTION_IN_PAGE_ERROR:
            _g_exc_code = EXC_ACCESS_VIOLATION;
            _g_exc_msg  = L"Access violation";
            break;
        case EXCEPTION_INT_DIVIDE_BY_ZERO:
        case EXCEPTION_FLT_DIVIDE_BY_ZERO:
        case EXCEPTION_FLT_INVALID_OPERATION:
            _g_exc_code = EXC_DIV_BY_ZERO;
            _g_exc_msg  = L"Divide by zero";
            break;
        case EXCEPTION_STACK_OVERFLOW:
            _g_exc_code = EXC_STACK_OVERFLOW;
            _g_exc_msg  = L"Stack overflow";
            break;
        case EXCEPTION_INT_OVERFLOW:
        case EXCEPTION_FLT_OVERFLOW:
        case EXCEPTION_FLT_UNDERFLOW:
            _g_exc_code = EXC_INTEGER_OVERFLOW;
            _g_exc_msg  = L"Numeric overflow";
            break;
        case EXCEPTION_ILLEGAL_INSTRUCTION:
        case EXCEPTION_PRIV_INSTRUCTION:
            _g_exc_code = EXC_ILLEGAL_INSTRUCTION;
            _g_exc_msg  = L"Illegal instruction";
            break;
        default:
            _g_exc_code = EXC_UNKNOWN;
            _g_exc_msg  = L"Hardware exception";
            break;
    }

    // Jump back to the setjmp point in TryCatch / TryFinally / TryCatchFinally.
    // Return value 2 distinguishes hardware path from software path (0 = normal,
    // 1 is not used, 2 = hardware fault).
    longjmp(*_g_jmp_target, 2);

    // Unreachable; required to satisfy the WINAPI return type.
    return EXCEPTION_CONTINUE_SEARCH;
}

static PVOID _g_veh_handle = nullptr;

static void _DoInstallHardwareHandlers() {
    if (_g_veh_handle == nullptr) {
        _g_veh_handle = AddVectoredExceptionHandler(1, _NpVehHandler);
    }
}

// ============================================================================
// POSIX: SIGNAL HANDLERS
// ============================================================================

#else // !_WIN32

static void _NpSignalHandler(int ASig) {
    if (_g_jmp_target == nullptr)
        return;

    switch (ASig) {
        case SIGFPE:
            _g_exc_code = EXC_DIV_BY_ZERO;
            _g_exc_msg  = L"Divide by zero";
            break;
        case SIGSEGV:
            _g_exc_code = EXC_ACCESS_VIOLATION;
            _g_exc_msg  = L"Segmentation fault";
            break;
#ifdef SIGBUS
        case SIGBUS:
            _g_exc_code = EXC_BUS_ERROR;
            _g_exc_msg  = L"Bus error";
            break;
#endif
        case SIGILL:
            _g_exc_code = EXC_ILLEGAL_INSTRUCTION;
            _g_exc_msg  = L"Illegal instruction";
            break;
        default:
            _g_exc_code = EXC_UNKNOWN;
            _g_exc_msg  = L"Hardware exception";
            break;
    }

    longjmp(*_g_jmp_target, 2);
}

static void _DoInstallHardwareHandlers() {
    struct sigaction LSa;
    std::memset(&LSa, 0, sizeof(LSa));
    LSa.sa_handler = _NpSignalHandler;
    sigemptyset(&LSa.sa_mask);
    LSa.sa_flags = 0;

    sigaction(SIGFPE,  &LSa, nullptr);
    sigaction(SIGSEGV, &LSa, nullptr);
    sigaction(SIGILL,  &LSa, nullptr);
#ifdef SIGBUS
    sigaction(SIGBUS,  &LSa, nullptr);
#endif
}

#endif // _WIN32

// ============================================================================
// PUBLIC: INSTALL HANDLERS (once per process)
// ============================================================================

void _InstallHardwareHandlers() {
    static std::once_flag LOnce;
    std::call_once(LOnce, _DoInstallHardwareHandlers);
}

} // namespace np
