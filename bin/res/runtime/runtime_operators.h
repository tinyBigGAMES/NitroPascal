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
    if (b == 0) {
        throw std::runtime_error("Division by zero");
    }
    return a / b;
}

inline Integer Mod(Integer a, Integer b) {
    if (b == 0) {
        throw std::runtime_error("Division by zero");
    }
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
