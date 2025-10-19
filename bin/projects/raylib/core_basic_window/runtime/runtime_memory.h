/**
 * NitroPascal Runtime - Memory Management
 */

#pragma once

#include "runtime_types.h"
#include <memory>
#include <cstring>
#include <cstdlib>

namespace np {

// ============================================================================
// OBJECT MEMORY MANAGEMENT
// ============================================================================

template<typename T>
void New(T*& ptr) {
    ptr = new T();
}

template<typename T>
void Dispose(T*& ptr) {
    delete ptr;
    ptr = nullptr;
}

// ============================================================================
// RAW MEMORY MANAGEMENT
// ============================================================================

void GetMem(void*& ptr, Integer size);
void FreeMem(void* ptr);
void ReallocMem(void*& ptr, Integer newSize);
void AllocMem(void*& ptr, Integer size);
void FillChar(void* dest, Integer count, Byte value);
void FillByte(void* dest, Integer count, Byte value);
void FillWord(void* dest, Integer count, Word value);
void FillDWord(void* dest, Integer count, Cardinal value);
void Move(const void* source, void* dest, Integer count);

// ============================================================================
// STATIC ARRAY MEMORY OPERATIONS
// ============================================================================

template<typename T, std::size_t N>
void FillChar(std::array<T, N>& dest, Integer count, Byte value) {
    if (count < 0) {
        throw std::invalid_argument("FillChar: negative count");
    }
    std::size_t byteCount = (static_cast<std::size_t>(count) < sizeof(dest)) ? 
                             static_cast<std::size_t>(count) : sizeof(dest);
    std::memset(dest.data(), value, byteCount);
}

template<typename T, std::size_t N>
void FillByte(std::array<T, N>& dest, Integer count, Byte value) {
    if (count < 0) {
        throw std::invalid_argument("FillByte: negative count");
    }
    std::size_t byteCount = (static_cast<std::size_t>(count) < sizeof(dest)) ? 
                             static_cast<std::size_t>(count) : sizeof(dest);
    std::memset(dest.data(), value, byteCount);
}

template<typename T, std::size_t N>
void FillWord(std::array<T, N>& dest, Integer count, Word value) {
    if (count < 0) {
        throw std::invalid_argument("FillWord: negative count");
    }
    std::size_t wordCount = (static_cast<std::size_t>(count) < (sizeof(dest) / sizeof(Word))) ? 
                             static_cast<std::size_t>(count) : (sizeof(dest) / sizeof(Word));
    Word* ptr = reinterpret_cast<Word*>(dest.data());
    for (std::size_t i = 0; i < wordCount; ++i) {
        ptr[i] = value;
    }
}

template<typename T, std::size_t N>
void FillDWord(std::array<T, N>& dest, Integer count, Cardinal value) {
    if (count < 0) {
        throw std::invalid_argument("FillDWord: negative count");
    }
    std::size_t dwordCount = (static_cast<std::size_t>(count) < (sizeof(dest) / sizeof(Cardinal))) ? 
                              static_cast<std::size_t>(count) : (sizeof(dest) / sizeof(Cardinal));
    Cardinal* ptr = reinterpret_cast<Cardinal*>(dest.data());
    for (std::size_t i = 0; i < dwordCount; ++i) {
        ptr[i] = value;
    }
}

template<typename T1, std::size_t N1, typename T2, std::size_t N2>
void Move(const std::array<T1, N1>& source, std::array<T2, N2>& dest, Integer count) {
    if (count < 0) {
        throw std::invalid_argument("Move: negative count");
    }
    std::size_t s1 = sizeof(source);
    std::size_t s2 = sizeof(dest);
    std::size_t byteCount = static_cast<std::size_t>(count);
    if (byteCount > s1) byteCount = s1;
    if (byteCount > s2) byteCount = s2;
    std::memmove(dest.data(), source.data(), byteCount);
}

} // namespace np
