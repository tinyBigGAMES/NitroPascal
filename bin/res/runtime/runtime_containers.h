/**
 * NitroPascal Runtime - Containers (DynArray, Set)
 */

#pragma once

#include "runtime_types.h"
#include <vector>
#include <memory>
#include <unordered_set>

namespace np {

// ============================================================================
// DYNAMIC ARRAY
// ============================================================================

template<typename T>
class DynArray {
private:
    std::shared_ptr<std::vector<T>> data_;
    
    void EnsureUnique() {
        if (data_ && data_.use_count() > 1) {
            data_ = std::make_shared<std::vector<T>>(*data_);
        }
    }
    
public:
    DynArray() : data_(std::make_shared<std::vector<T>>()) {}
    DynArray(const DynArray& other) : data_(other.data_) {}
    
    DynArray& operator=(const DynArray& other) {
        if (this != &other) {
            data_ = other.data_;
        }
        return *this;
    }
    
    const T& operator[](Integer index) const {
        if (!data_ || index < 0 || index >= static_cast<Integer>(data_->size())) {
            throw std::out_of_range("DynArray index out of range");
        }
        return (*data_)[index];
    }
    
    T& operator[](Integer index) {
        EnsureUnique();
        if (!data_ || index < 0 || index >= static_cast<Integer>(data_->size())) {
            throw std::out_of_range("DynArray index out of range");
        }
        return (*data_)[index];
    }
    
    Integer Length() const {
        return data_ ? static_cast<Integer>(data_->size()) : 0;
    }
    
    Integer Low() const {
        return 0;
    }
    
    Integer High() const {
        Integer len = Length();
        return len > 0 ? len - 1 : -1;
    }
    
    template<typename U>
    friend void SetLength(DynArray<U>& arr, Integer newLength);
    
    template<typename U>
    friend DynArray<U> Copy(const DynArray<U>& arr);
};

// ============================================================================
// DYNAMIC ARRAY FUNCTIONS
// ============================================================================

template<typename T>
void SetLength(DynArray<T>& arr, Integer newLength) {
    if (newLength < 0) {
        throw std::invalid_argument("SetLength: negative length");
    }
    
    arr.EnsureUnique();
    if (arr.data_) {
        arr.data_->resize(static_cast<size_t>(newLength));
    }
}

template<typename T>
DynArray<T> Copy(const DynArray<T>& arr) {
    DynArray<T> result;
    if (arr.data_) {
        result.data_ = std::make_shared<std::vector<T>>(*arr.data_);
    }
    return result;
}

template<typename T>
Integer Length(const DynArray<T>& arr) {
    return arr.Length();
}

template<typename T>
Integer High(const DynArray<T>& arr) {
    return arr.High();
}

template<typename T>
Integer Low(const DynArray<T>& arr) {
    return arr.Low();
}

template<typename T, std::size_t N>
Integer Low(const std::array<T, N>& arr) {
    return 0;
}

template<typename T, std::size_t N>
Integer High(const std::array<T, N>& arr) {
    return static_cast<Integer>(N) - 1;
}

// ============================================================================
// SET
// ============================================================================

template<typename T>
class Set {
private:
    std::unordered_set<T> data_;
    
public:
    Set() = default;
    Set(std::initializer_list<T> init) : data_(init) {}
    
    void Include(T elem) {
        data_.insert(elem);
    }
    
    void Exclude(T elem) {
        data_.erase(elem);
    }
    
    bool Contains(T elem) const {
        return data_.count(elem) > 0;
    }
    
    Set operator+(const Set& other) const {
        Set result = *this;
        for (const auto& elem : other.data_) {
            result.data_.insert(elem);
        }
        return result;
    }
    
    Set operator-(const Set& other) const {
        Set result = *this;
        for (const auto& elem : other.data_) {
            result.data_.erase(elem);
        }
        return result;
    }
    
    Set operator*(const Set& other) const {
        Set result;
        for (const auto& elem : data_) {
            if (other.Contains(elem)) {
                result.data_.insert(elem);
            }
        }
        return result;
    }
    
    bool operator==(const Set& other) const {
        return data_ == other.data_;
    }
    
    bool operator!=(const Set& other) const {
        return data_ != other.data_;
    }
    
    bool operator<=(const Set& other) const {
        for (const auto& elem : data_) {
            if (!other.Contains(elem)) {
                return false;
            }
        }
        return true;
    }
    
    bool operator>=(const Set& other) const {
        return other <= *this;
    }
    
    Integer Size() const {
        return static_cast<Integer>(data_.size());
    }
};

// ============================================================================
// SET FUNCTIONS
// ============================================================================

template<typename T>
void Include(Set<T>& set, T elem) {
    set.Include(elem);
}

template<typename T>
void Exclude(Set<T>& set, T elem) {
    set.Exclude(elem);
}

template<typename T>
bool In(T elem, const Set<T>& set) {
    return set.Contains(elem);
}

template<typename T>
Set<T> MakeSet(std::initializer_list<T> init) {
    return Set<T>(init);
}

template<typename T>
inline DynArray<T> Copy(const DynArray<T>& AArray, const Integer AIndex, const Integer ACount) {
    if (AIndex < 0 || ACount < 0 || AIndex >= AArray.Length()) {
        return DynArray<T>();
    }
    
    Integer actual_count = (ACount < AArray.Length() - AIndex) ? ACount : (AArray.Length() - AIndex);
    DynArray<T> result;
    SetLength(result, actual_count);
    
    for (Integer i = 0; i < actual_count; i++) {
        result[i] = AArray[AIndex + i];
    }
    
    return result;
}

} // namespace np
