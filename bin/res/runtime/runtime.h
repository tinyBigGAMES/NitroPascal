/**
 * NitroPascal Runtime Library
 * 
 * This is the C++ Runtime Library (RTL) that provides Delphi/Object Pascal
 * semantics in C++20. The code generator emits calls to these functions
 * and classes, making code generation trivial.
 * 
 * Key Design Principles:
 * - All Delphi semantics are wrapped in C++ functions/classes
 * - Code generator just emits function calls (simple syntax translation)
 * - All complexity lives here (written once, correct once)
 * - Uses C++20 features (fold expressions, concepts, etc.)
 * 
 * Module Organization:
 * - runtime_types.h: Core type aliases
 * - runtime_operators_custom.h: Custom output operators (before namespace)
 * - runtime_string.h/cpp: String class and utilities
 * - runtime_console.h/cpp: Console I/O
 * - runtime_control.h/cpp: Control flow (for, while, repeat)
 * - runtime_operators.h/cpp: Arithmetic operators (div, mod, shl, shr)
 * - runtime_ordinal.h/cpp: Ordinal functions (Ord, Chr, Succ, Pred, Inc, Dec)
 * - runtime_containers.h/cpp: DynArray<T>, Set<T>
 * - runtime_memory.h/cpp: Memory management (New, Dispose, GetMem, Move)
 * - runtime_math.h/cpp: Math functions (Abs, Sqrt, Sin, Cos, etc.)
 * - runtime_file.h/cpp: File I/O (Text, Binary files)
 * - runtime_exceptions.h/cpp: Exception handling
 * - runtime_cmdline.h/cpp: Command line parameters
 * - runtime_format.h/cpp: String formatting
 * 
 * Version: 1.0
 * Date: 2025-10-15
 */

#pragma once

// ============================================================================
// GLOBAL INCLUDES (required before np namespace)
// ============================================================================

#include <iostream>
#include <string>
#include <functional>
#include <cstdint>
#include <vector>
#include <unordered_set>
#include <memory>
#include <sstream>
#include <iomanip>
#include <stdexcept>
#include <cassert>
#include <array>
#include <cstring>
#include <cmath>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <sys/stat.h>
#include <algorithm>



// ============================================================================
// MODULAR INCLUDES IN DEPENDENCY ORDER
// ============================================================================

#include "runtime_types.h"
#include "runtime_operators_custom.h"
#include "runtime_string.h"
#include "runtime_console.h"
#include "runtime_control.h"
#include "runtime_operators.h"
#include "runtime_ordinal.h"
#include "runtime_containers.h"
#include "runtime_memory.h"
#include "runtime_math.h"
#include "runtime_file.h"
#include "runtime_exceptions.h"
#include "runtime_cmdline.h"
#include "runtime_format.h"
