/**
 * NitroPascal Runtime - Ordinal Functions
 */

#pragma once

#include "runtime_types.h"

namespace np {

// ============================================================================
// ORDINAL FUNCTIONS
// ============================================================================

template<typename T>
inline Integer Ord(T value) {
    return static_cast<Integer>(value);
}

inline Char Chr(Integer value) {
    return static_cast<Char>(value);
}

template<typename T>
inline T Succ(T value) {
    return static_cast<T>(static_cast<Integer>(value) + 1);
}

template<typename T>
inline T Pred(T value) {
    return static_cast<T>(static_cast<Integer>(value) - 1);
}

template<typename T>
inline void Inc(T& value) {
    value = static_cast<T>(static_cast<Integer>(value) + 1);
}

template<typename T, typename U>
inline void Inc(T& value, U amount) {
    value = static_cast<T>(static_cast<Integer>(value) + static_cast<Integer>(amount));
}

template<typename T>
inline void Dec(T& value) {
    value = static_cast<T>(static_cast<Integer>(value) - 1);
}

template<typename T, typename U>
inline void Dec(T& value, U amount) {
    value = static_cast<T>(static_cast<Integer>(value) - static_cast<Integer>(amount));
}

// ============================================================================
// TYPE INFORMATION
// ============================================================================

inline Boolean Assigned(void* ptr) {
    return ptr != nullptr;
}

template<typename T>
inline Boolean Assigned(T* ptr) {
    return ptr != nullptr;
}

inline Boolean Odd(const Integer AValue) {
    return (AValue & 1) != 0;
}

inline Word Swap(const Word AValue) {
    return ((AValue & 0xFF00) >> 8) | ((AValue & 0x00FF) << 8);
}

} // namespace np
