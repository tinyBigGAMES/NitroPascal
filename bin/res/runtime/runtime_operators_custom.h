/**
 * NitroPascal Runtime - Custom Output Operators
 * Required for Delphi types in np namespace
 */

#pragma once

#include <iostream>
#include <iomanip>
#include <cstdint>

namespace np {

/**
 * Custom output operator for char16_t (Delphi Char type)
 * 
 * Must be in np namespace for proper visibility in template instantiation.
 */
inline std::ostream& operator<<(std::ostream& os, char16_t ch) {
    if (ch < 128) {
        os << static_cast<char>(ch);
    } else {
        os << "\\u" << std::hex << std::setw(4) << std::setfill('0') << static_cast<int>(ch);
    }
    return os;
}

/**
 * Custom output operator for char16_t to wide streams (for file I/O)
 * Converts char16_t to wchar_t for wide file streams
 */
inline std::wostream& operator<<(std::wostream& os, char16_t ch) {
    return os << static_cast<wchar_t>(ch);
}

/**
 * Custom output operator for uint8_t (Delphi Byte type)
 */
inline std::ostream& operator<<(std::ostream& os, uint8_t value) {
    return os << static_cast<int>(value);
}

} // namespace np
