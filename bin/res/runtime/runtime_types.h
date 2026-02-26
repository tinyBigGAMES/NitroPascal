/**
 * NitroPascal Runtime - Type Definitions
 * Core type aliases for Delphi/Pascal semantics
 */

#pragma once

#include <cstdint>
#include <string>
#include <cstring>
#include <csetjmp>

namespace np {

// ============================================================================
// TYPE ALIASES - Delphi types mapped to fixed-size C++ types
// ============================================================================

using Integer = int32_t;
using Cardinal = uint32_t;
using Int64 = int64_t;
using Byte = uint8_t;
using Word = uint16_t;
using Boolean = bool;
using Char = char16_t;
using Double = double;
using Single = float;
using Pointer = void*;

// ============================================================================
// POINTER TYPE ALIASES - Delphi pointer types (^Type becomes PType)
// ============================================================================

using PInteger = Integer*;
using PCardinal = Cardinal*;
using PInt64 = Int64*;
using PByte = Byte*;
using PWord = Word*;
using PBoolean = Boolean*;
using PChar = Char*;
using PDouble = Double*;
using PSingle = Single*;
using PPointer = Pointer*;

// ============================================================================
// EXCEPTION CODES
// Defined here so all runtime modules can use them without depending on
// runtime_exceptions.h (which is included late in the dependency chain).
// ============================================================================

constexpr Integer EXC_NONE                = 0;
constexpr Integer EXC_SOFTWARE            = 1;
constexpr Integer EXC_DIV_BY_ZERO         = 2;
constexpr Integer EXC_ACCESS_VIOLATION    = 3;
constexpr Integer EXC_STACK_OVERFLOW      = 4;
constexpr Integer EXC_INTEGER_OVERFLOW    = 5;
constexpr Integer EXC_ILLEGAL_INSTRUCTION = 6;
constexpr Integer EXC_BUS_ERROR           = 7;
constexpr Integer EXC_UNKNOWN             = 99;

// Internal exception object used by RaiseException and hardware handlers.
// Using std::wstring so it is independent of the np::String class.
struct _Exception {
    Integer      code;
    std::wstring msg;
};

// Thread-local exception state -- written by raise/hardware handlers,
// read by GetExceptionCode() and GetExceptionMessage().
inline thread_local Integer      _g_exc_code   = EXC_NONE;
inline thread_local std::wstring _g_exc_msg;

// Thread-local longjmp target -- set by TryCatch/TryFinally wrappers,
// read by the hardware exception handlers.
inline thread_local jmp_buf* _g_jmp_target = nullptr;

} // namespace np
