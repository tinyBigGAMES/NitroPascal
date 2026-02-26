/**
 * NitroPascal Runtime - Console I/O
 */

#pragma once

#include "runtime_types.h"
#include "runtime_operators_custom.h"
#include "runtime_string.h"
#include <iostream>

namespace np {

// ============================================================================
// CONSOLE INITIALIZATION
// ============================================================================

void InitializeConsole();

// ============================================================================
// I/O FUNCTIONS
// ============================================================================

template<typename... Args>
void Write(Args&&... args) {
    std::cout << std::boolalpha;
    (std::cout << ... << std::forward<Args>(args));
}

template<typename... Args>
void WriteLn(Args&&... args) {
    std::cout << std::boolalpha;
    (std::cout << ... << std::forward<Args>(args));
    std::cout << std::endl;
}

inline void WriteLn() {
    std::cout << std::endl;
}

template<typename T>
void ReadLn(T& value) {
    std::cin >> value;
}

inline void ReadLn(String& value) {
    std::string line;
    std::getline(std::cin, line);
    value = String(line);
}

} // namespace np
