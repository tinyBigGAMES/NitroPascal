/**
 * NitroPascal Runtime - Memory Management Implementation
 */

#include "runtime_memory.h"

namespace np {

void GetMem(void*& ptr, Integer size) {
    if (size <= 0) {
        ptr = nullptr;
        return;
    }
    
    ptr = std::malloc(static_cast<size_t>(size));
    if (ptr == nullptr) {
        throw std::bad_alloc();
    }
}

void FreeMem(void* ptr) {
    if (ptr != nullptr) {
        std::free(ptr);
    }
}

void ReallocMem(void*& ptr, Integer newSize) {
    if (newSize <= 0) {
        if (ptr != nullptr) {
            std::free(ptr);
            ptr = nullptr;
        }
        return;
    }
    
    void* newPtr = std::realloc(ptr, static_cast<size_t>(newSize));
    if (newPtr == nullptr && newSize > 0) {
        throw std::bad_alloc();
    }
    
    ptr = newPtr;
}

void FillChar(void* dest, Integer count, Byte value) {
    if (dest == nullptr || count <= 0) {
        return;
    }
    
    std::memset(dest, value, static_cast<size_t>(count));
}

void Move(const void* source, void* dest, Integer count) {
    if (source == nullptr || dest == nullptr || count <= 0) {
        return;
    }
    
    std::memmove(dest, source, static_cast<size_t>(count));
}

void AllocMem(void*& ptr, Integer size) {
    if (size <= 0) {
        ptr = nullptr;
        return;
    }
    
    ptr = std::calloc(1, static_cast<size_t>(size));
    if (ptr == nullptr) {
        throw std::bad_alloc();
    }
}

void FillByte(void* dest, Integer count, Byte value) {
    FillChar(dest, count, value);
}

void FillWord(void* dest, Integer count, Word value) {
    if (dest == nullptr || count <= 0) {
        return;
    }
    
    Word* ptr = static_cast<Word*>(dest);
    for (Integer i = 0; i < count; ++i) {
        ptr[i] = value;
    }
}

void FillDWord(void* dest, Integer count, Cardinal value) {
    if (dest == nullptr || count <= 0) {
        return;
    }
    
    Cardinal* ptr = static_cast<Cardinal*>(dest);
    for (Integer i = 0; i < count; ++i) {
        ptr[i] = value;
    }
}

} // namespace np
