/**
 * NitroPascal Runtime - Math Functions
 */

#pragma once

#include "runtime_types.h"
#include <cmath>
#include <cstdlib>
#include <ctime>

namespace np {

// ============================================================================
// BASIC MATH
// ============================================================================

inline Integer Abs(const Integer AValue) {
    return std::abs(AValue);
}

inline Double Abs(const Double AValue) {
    return std::abs(AValue);
}

inline Integer Sqr(const Integer AValue) {
    return AValue * AValue;
}

inline Double Sqr(const Double AValue) {
    return AValue * AValue;
}

// ============================================================================
// TRANSCENDENTAL FUNCTIONS
// ============================================================================

inline Double Sqrt(const Double AValue) {
    return std::sqrt(AValue);
}

inline Double Sin(const Double AValue) {
    return std::sin(AValue);
}

inline Double Cos(const Double AValue) {
    return std::cos(AValue);
}

inline Double Tan(const Double AValue) {
    return std::tan(AValue);
}

inline Double ArcTan(const Double AValue) {
    return std::atan(AValue);
}

inline Double ArcSin(const Double AValue) {
    return std::asin(AValue);
}

inline Double ArcCos(const Double AValue) {
    return std::acos(AValue);
}

inline Double Int(const Double AValue) {
    return std::trunc(AValue);
}

inline Double Frac(const Double AValue) {
    return AValue - std::trunc(AValue);
}

inline Double Exp(const Double AValue) {
    return std::exp(AValue);
}

inline Double Ln(const Double AValue) {
    return std::log(AValue);
}

inline Double Power(const Double ABase, const Double AExponent) {
    return std::pow(ABase, AExponent);
}

inline double Pi() {
    return 3.14159265358979323846;
}

inline Double ArcTan2(const Double Y, const Double X) {
    return std::atan2(Y, X);
}

inline Double Sinh(const Double AValue) {
    return std::sinh(AValue);
}

inline Double Cosh(const Double AValue) {
    return std::cosh(AValue);
}

inline Double Tanh(const Double AValue) {
    return std::tanh(AValue);
}

inline Double ArcSinh(const Double AValue) {
    return std::asinh(AValue);
}

inline Double ArcCosh(const Double AValue) {
    return std::acosh(AValue);
}

inline Double ArcTanh(const Double AValue) {
    return std::atanh(AValue);
}

inline Double Log10(const Double AValue) {
    return std::log10(AValue);
}

inline Double Log2(const Double AValue) {
    return std::log2(AValue);
}

inline Double LogN(const Double ABase, const Double AValue) {
    return std::log(AValue) / std::log(ABase);
}

// ============================================================================
// ROUNDING
// ============================================================================

inline Integer Round(const Double AValue) {
    return static_cast<Integer>(std::round(AValue));
}

inline Integer Trunc(const Double AValue) {
    return static_cast<Integer>(std::trunc(AValue));
}

inline Double Ceil(const Double AValue) {
    return std::ceil(AValue);
}

inline Double Floor(const Double AValue) {
    return std::floor(AValue);
}

// ============================================================================
// MIN/MAX
// ============================================================================

template<typename T>
inline T Max(const T A, const T B) {
    return (A > B) ? A : B;
}

template<typename T>
inline T Min(const T A, const T B) {
    return (A < B) ? A : B;
}

// ============================================================================
// RANDOM
// ============================================================================

inline void Randomize() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
}

inline Integer Random(const Integer ARange) {
    return std::rand() % ARange;
}

inline Double Random() {
    return static_cast<Double>(std::rand()) / RAND_MAX;
}

} // namespace np
