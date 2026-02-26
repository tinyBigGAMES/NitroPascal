/**
 * NitroPascal Runtime - Control Flow
 */

#pragma once

#include "runtime_types.h"
#include <type_traits>

namespace np {

// ============================================================================
// LOOP CONTROL
// ============================================================================

enum class LoopControl {
    Normal,
    Break,
    Continue
};

// ============================================================================
// FOR LOOP
// ============================================================================

template<typename Func>
auto ForLoop(Integer start, Integer end, Func body)
    -> std::enable_if_t<std::is_same_v<decltype(body(start)), void>> {
    for (Integer i = start; i <= end; i++) {
        body(i);
    }
}

template<typename Func>
auto ForLoop(Integer start, Integer end, Func body) 
    -> std::enable_if_t<std::is_same_v<decltype(body(start)), LoopControl>> {
    for (Integer i = start; i <= end; i++) {
        LoopControl ctrl = body(i);
        if (ctrl == LoopControl::Break) {
            break;
        }
        if (ctrl == LoopControl::Continue) {
            continue;
        }
    }
}

// ============================================================================
// FOR LOOP DOWNTO
// ============================================================================

template<typename Func>
auto ForLoopDownto(Integer start, Integer end, Func body)
    -> std::enable_if_t<std::is_same_v<decltype(body(start)), void>> {
    for (Integer i = start; i >= end; i--) {
        body(i);
    }
}

template<typename Func>
auto ForLoopDownto(Integer start, Integer end, Func body)
    -> std::enable_if_t<std::is_same_v<decltype(body(start)), LoopControl>> {
    for (Integer i = start; i >= end; i--) {
        LoopControl ctrl = body(i);
        if (ctrl == LoopControl::Break) {
            break;
        }
        if (ctrl == LoopControl::Continue) {
            continue;
        }
    }
}

// ============================================================================
// WHILE LOOP
// ============================================================================

template<typename CondFunc, typename BodyFunc>
auto WhileLoop(CondFunc condition, BodyFunc body)
    -> std::enable_if_t<std::is_same_v<decltype(body()), void>> {
    while (condition()) {
        body();
    }
}

template<typename CondFunc, typename BodyFunc>
auto WhileLoop(CondFunc condition, BodyFunc body)
    -> std::enable_if_t<std::is_same_v<decltype(body()), LoopControl>> {
    while (condition()) {
        LoopControl ctrl = body();
        if (ctrl == LoopControl::Break) {
            break;
        }
        if (ctrl == LoopControl::Continue) {
            continue;
        }
    }
}

// ============================================================================
// REPEAT UNTIL
// ============================================================================

template<typename BodyFunc, typename CondFunc>
auto RepeatUntil(BodyFunc body, CondFunc condition)
    -> std::enable_if_t<std::is_same_v<decltype(body()), void>> {
    do {
        body();
    } while (!condition());
}

template<typename BodyFunc, typename CondFunc>
auto RepeatUntil(BodyFunc body, CondFunc condition)
    -> std::enable_if_t<std::is_same_v<decltype(body()), LoopControl>> {
    do {
        LoopControl ctrl = body();
        if (ctrl == LoopControl::Break) {
            break;
        }
    } while (!condition());
}

// ============================================================================
// PROGRAM CONTROL
// ============================================================================

/**
 * Halt - Terminate program execution
 * @param exitCode Exit code to return to operating system (default: 0)
 */
void Halt(Integer exitCode = 0);

/**
 * RunError - Terminate with runtime error
 * @param errorCode Error code
 */
[[noreturn]] void RunError(Integer errorCode);

/**
 * Abort - Abort program execution
 */
void Abort();

} // namespace np
