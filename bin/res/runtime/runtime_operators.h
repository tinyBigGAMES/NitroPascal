/**
 * NitroPascal Runtime - Operators
 */

#pragma once

#include "runtime_types.h"
#include <stdexcept>

namespace np {

// ============================================================================
// INTEGER OPERATORS
// ============================================================================

inline Integer Div(Integer a, Integer b) {
    // No explicit zero check -- let the hardware fault fire so the VEH /
    // signal handler can catch it as EXC_DIV_BY_ZERO inside a try block.
    // Outside a try block the process will fault (correct Delphi behaviour).
    return a / b;
}

inline Integer Mod(Integer a, Integer b) {
    // Same as Div -- hardware fault for divide-by-zero.
    return a % b;
}

// ============================================================================
// BITWISE OPERATORS
// ============================================================================

inline Integer Shl(Integer value, Integer shift) {
    return value << shift;
}

inline Integer Shr(Integer value, Integer shift) {
    return value >> shift;
}

// ============================================================================
// SET MEMBERSHIP
// ============================================================================

template<typename T, typename SetType>
bool In(const T& element, const SetType& set) {
    return set.contains(element);
}

} // namespace np
