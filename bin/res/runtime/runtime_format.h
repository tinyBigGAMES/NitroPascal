/**
 * NitroPascal Runtime - String Formatting
 */

#pragma once

#include "runtime_types.h"
#include "runtime_string.h"
#include <cstdio>
#include <vector>
#include <string>
#include <algorithm>
#include <cctype>
#include <tuple>

namespace np {

// ============================================================================
// STRING FORMATTING FUNCTIONS
// ============================================================================

inline String BoolToStr(const Boolean AValue, const Boolean AUseBoolStrs = true) {
    if (AUseBoolStrs) {
        return AValue ? String(u"True") : String(u"False");
    } else {
        return AValue ? String(u"-1") : String(u"0");
    }
}

// Helper to convert String to std::string and store it
template<typename T>
auto store_converted_arg(T&& arg) {
    using Decay = std::decay_t<T>;
    if constexpr (std::is_same_v<Decay, String>) {
        return arg.ToStdString();
    } else {
        return std::forward<T>(arg);
    }
}

// Helper to get the actual value for snprintf
template<typename T>
auto get_snprintf_arg(const T& arg) {
    if constexpr (std::is_same_v<std::decay_t<T>, std::string>) {
        return arg.c_str();
    } else {
        return arg;
    }
}

template<typename... Args>
inline String Format(const String& AFmt, Args&&... AArgs) {
    // Convert np::String format to std::string
    std::string fmt_str = AFmt.ToStdString();
    
    // Store converted arguments (keeps std::strings alive)
    auto stored_args = std::make_tuple(store_converted_arg(std::forward<Args>(AArgs))...);
    
    // First, get the required buffer size
    int size = std::apply([&](const auto&... args) {
        return std::snprintf(nullptr, 0, fmt_str.c_str(), get_snprintf_arg(args)...);
    }, stored_args);
    
    if (size < 0) {
        return String("");
    }
    
    // Allocate buffer and format
    std::vector<char> buffer(size + 1);
    std::apply([&](const auto&... args) {
        std::snprintf(buffer.data(), buffer.size(), fmt_str.c_str(), get_snprintf_arg(args)...);
    }, stored_args);
    
    // Convert result back to np::String
    return String(std::string(buffer.data()));
}

inline String StringReplace(const String& AText, const String& AOld, const String& ANew) {
    std::wstring result = AText.ToWString();
    std::wstring old_str = AOld.ToWString();
    std::wstring new_str = ANew.ToWString();
    
    if (old_str.empty()) {
        return AText;
    }
    
    size_t pos = 0;
    while ((pos = result.find(old_str, pos)) != std::wstring::npos) {
        result.replace(pos, old_str.length(), new_str);
        pos += new_str.length();
    }
    
    return String(result);
}

inline Integer CompareStr(const String& A, const String& B) {
    const std::wstring& a_data = A.ToWString();
    const std::wstring& b_data = B.ToWString();
    
    if (a_data < b_data) return -1;
    if (a_data > b_data) return 1;
    return 0;
}

inline Boolean SameText(const String& A, const String& B) {
    std::wstring a_lower = A.ToWString();
    std::wstring b_lower = B.ToWString();
    
    std::transform(a_lower.begin(), a_lower.end(), a_lower.begin(), ::towlower);
    std::transform(b_lower.begin(), b_lower.end(), b_lower.begin(), ::towlower);
    
    return a_lower == b_lower;
}

inline String QuotedStr(const String& AText) {
    return String(u"'") + AText + String(u"'");
}

} // namespace np
