/**
 * NitroPascal Runtime - Type Definitions
 * Core type aliases for Delphi/Pascal semantics
 */

#pragma once

#include <cstdint>

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

} // namespace np
