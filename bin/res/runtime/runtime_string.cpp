/**
 * NitroPascal Runtime - String Implementation
 */

#include "runtime_string.h"
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <sstream>

namespace {
    // Helper: Convert UTF-8 to UTF-16
    std::u16string utf8_to_utf16(const std::string& utf8) {
        std::u16string result;
        size_t i = 0;
        while (i < utf8.size()) {
            uint32_t codepoint = 0;
            unsigned char ch = utf8[i];
            
            if (ch <= 0x7F) {
                codepoint = ch;
                i++;
            } else if ((ch & 0xE0) == 0xC0) {
                if (i + 1 < utf8.size()) {
                    codepoint = ((ch & 0x1F) << 6) | (utf8[i + 1] & 0x3F);
                    i += 2;
                } else break;
            } else if ((ch & 0xF0) == 0xE0) {
                if (i + 2 < utf8.size()) {
                    codepoint = ((ch & 0x0F) << 12) | 
                               ((utf8[i + 1] & 0x3F) << 6) | 
                               (utf8[i + 2] & 0x3F);
                    i += 3;
                } else break;
            } else if ((ch & 0xF8) == 0xF0) {
                if (i + 3 < utf8.size()) {
                    codepoint = ((ch & 0x07) << 18) | 
                               ((utf8[i + 1] & 0x3F) << 12) | 
                               ((utf8[i + 2] & 0x3F) << 6) | 
                               (utf8[i + 3] & 0x3F);
                    i += 4;
                } else break;
            } else {
                i++;
                continue;
            }
            
            if (codepoint <= 0xFFFF) {
                result += static_cast<char16_t>(codepoint);
            } else {
                codepoint -= 0x10000;
                result += static_cast<char16_t>(0xD800 + (codepoint >> 10));
                result += static_cast<char16_t>(0xDC00 + (codepoint & 0x3FF));
            }
        }
        return result;
    }
    
    // Helper: Convert UTF-16 to UTF-8
    std::string utf16_to_utf8(const std::u16string& utf16) {
        std::string result;
        size_t i = 0;
        while (i < utf16.size()) {
            uint32_t codepoint = utf16[i];
            
            if (codepoint >= 0xD800 && codepoint <= 0xDBFF && i + 1 < utf16.size()) {
                uint32_t high = codepoint;
                uint32_t low = utf16[i + 1];
                if (low >= 0xDC00 && low <= 0xDFFF) {
                    codepoint = 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
                    i += 2;
                } else {
                    i++;
                    continue;
                }
            } else {
                i++;
            }
            
            if (codepoint <= 0x7F) {
                result += static_cast<char>(codepoint);
            } else if (codepoint <= 0x7FF) {
                result += static_cast<char>(0xC0 | (codepoint >> 6));
                result += static_cast<char>(0x80 | (codepoint & 0x3F));
            } else if (codepoint <= 0xFFFF) {
                result += static_cast<char>(0xE0 | (codepoint >> 12));
                result += static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F));
                result += static_cast<char>(0x80 | (codepoint & 0x3F));
            } else {
                result += static_cast<char>(0xF0 | (codepoint >> 18));
                result += static_cast<char>(0x80 | ((codepoint >> 12) & 0x3F));
                result += static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F));
                result += static_cast<char>(0x80 | (codepoint & 0x3F));
            }
        }
        return result;
    }
    
    // Helper: Convert UTF-16 to wstring
    std::wstring utf16_to_wstring(const std::u16string& utf16) {
#ifdef _WIN32
        return std::wstring(reinterpret_cast<const wchar_t*>(utf16.c_str()), utf16.length());
#else
        std::wstring result;
        result.reserve(utf16.size());
        for (char16_t ch : utf16) {
            result.push_back(static_cast<wchar_t>(ch));
        }
        return result;
#endif
    }
    
    // Helper: Convert wstring to UTF-16
    std::u16string wstring_to_utf16(const std::wstring& wstr) {
#ifdef _WIN32
        return std::u16string(reinterpret_cast<const char16_t*>(wstr.c_str()), wstr.length());
#else
        std::u16string result;
        result.reserve(wstr.size());
        for (wchar_t ch : wstr) {
            result.push_back(static_cast<char16_t>(ch));
        }
        return result;
#endif
    }
} // anonymous namespace

namespace np {

// ============================================================================
// STRING CLASS IMPLEMENTATION
// ============================================================================

String::String() : data_() {
}

String::String(const char* s) {
    data_ = utf8_to_utf16(s);
}

String::String(const char16_t* s) : data_(s) {
}

String::String(const wchar_t* s) {
    std::wstring wstr(s);
    data_ = wstring_to_utf16(wstr);
}

String::String(const std::string& s) {
    data_ = utf8_to_utf16(s);
}

String::String(const std::u16string& s) : data_(s) {
}

String::String(const std::wstring& s) {
    data_ = wstring_to_utf16(s);
}

char16_t String::operator[](Integer index) const {
    if (index < 1 || index > static_cast<Integer>(data_.length())) {
        throw std::out_of_range("String index out of range");
    }
    return data_[index - 1];
}

char16_t& String::operator[](Integer index) {
    if (index < 1 || index > static_cast<Integer>(data_.length())) {
        throw std::out_of_range("String index out of range");
    }
    return data_[index - 1];
}

String String::operator+(const String& other) const {
    return String(data_ + other.data_);
}

String& String::operator+=(const String& other) {
    data_ += other.data_;
    return *this;
}

bool String::operator==(const String& other) const {
    return data_ == other.data_;
}

bool String::operator!=(const String& other) const {
    return data_ != other.data_;
}

bool String::operator<(const String& other) const {
    return data_ < other.data_;
}

bool String::operator>(const String& other) const {
    return data_ > other.data_;
}

bool String::operator<=(const String& other) const {
    return data_ <= other.data_;
}

bool String::operator>=(const String& other) const {
    return data_ >= other.data_;
}

Integer String::Length() const {
    return static_cast<Integer>(data_.length());
}

std::string String::ToStdString() const {
    return utf16_to_utf8(data_);
}

std::wstring String::ToWString() const {
    return utf16_to_wstring(data_);
}

const wchar_t* String::c_str_wide() const {
#ifdef _WIN32
    return reinterpret_cast<const wchar_t*>(data_.c_str());
#else
    thread_local std::wstring temp;
    temp.clear();
    temp.reserve(data_.size());
    for (char16_t ch : data_) {
        temp.push_back(static_cast<wchar_t>(ch));
    }
    return temp.c_str();
#endif
}

std::ostream& operator<<(std::ostream& os, const String& s) {
    os << s.ToStdString();
    return os;
}

// ============================================================================
// STRING UTILITY FUNCTIONS
// ============================================================================

Integer Length(const String& s) {
    return s.Length();
}

String Copy(const String& s, Integer start, Integer count) {
    if (start < 1) {
        start = 1;
    }
    
    Integer len = s.Length();
    if (start > len) {
        return String();
    }
    
    if (start + count - 1 > len) {
        count = len - start + 1;
    }
    
    if (count <= 0) {
        return String();
    }
    
    const std::u16string& data = s.Data();
    return String(data.substr(start - 1, count));
}

Integer Pos(const String& substr, const String& s) {
    const std::u16string& haystack = s.Data();
    const std::u16string& needle = substr.Data();
    
    size_t pos = haystack.find(needle);
    if (pos == std::u16string::npos) {
        return 0;
    }
    
    return static_cast<Integer>(pos) + 1;
}

String IntToStr(Integer value) {
    return String(std::to_string(value));
}

Integer StrToInt(const String& s) {
    try {
        std::string str = s.ToStdString();
        return std::stoi(str);
    } catch (...) {
        throw std::runtime_error("Invalid integer string");
    }
}

Integer StrToIntDef(const String& s, Integer defaultValue) {
    try {
        std::string str = s.ToStdString();
        return std::stoi(str);
    } catch (...) {
        return defaultValue;
    }
}

String FloatToStr(Double value) {
    // Use ostringstream for proper floating-point formatting
    // This matches Delphi's FloatToStr behavior:
    // - No unnecessary trailing zeros
    // - Scientific notation for very large/small numbers
    // - Clean, human-readable output
    std::ostringstream oss;
    
    // Set precision and disable scientific notation for readability
    oss.precision(15);  // Sufficient precision for Double
    oss << std::fixed << value;
    
    std::string result = oss.str();
    
    // Remove trailing zeros after decimal point
    if (result.find('.') != std::string::npos) {
        result.erase(result.find_last_not_of('0') + 1, std::string::npos);
        // Remove trailing decimal point if no decimals remain
        if (result.back() == '.') {
            result.pop_back();
        }
    }
    
    return String(result);
}

Double StrToFloat(const String& s) {
    try {
        std::string str = s.ToStdString();
        return std::stod(str);
    } catch (...) {
        throw std::runtime_error("Invalid float string");
    }
}

String UpperCase(const String& s) {
    std::string str = s.ToStdString();
    std::transform(str.begin(), str.end(), str.begin(),
                   [](unsigned char c) { return std::toupper(c); });
    return String(str);
}

String LowerCase(const String& s) {
    std::string str = s.ToStdString();
    std::transform(str.begin(), str.end(), str.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    return String(str);
}

String Trim(const String& s) {
    std::string str = s.ToStdString();
    
    auto start = str.begin();
    while (start != str.end() && std::isspace(*start)) {
        start++;
    }
    
    auto end = str.end();
    do {
        end--;
    } while (std::distance(start, end) > 0 && std::isspace(*end));
    
    return String(std::string(start, end + 1));
}

String TrimLeft(const String& s) {
    std::string str = s.ToStdString();
    
    auto start = str.begin();
    while (start != str.end() && std::isspace(static_cast<unsigned char>(*start))) {
        start++;
    }
    
    return String(std::string(start, str.end()));
}

String TrimRight(const String& s) {
    std::string str = s.ToStdString();
    
    if (str.empty()) {
        return String();
    }
    
    auto end = str.end();
    do {
        end--;
    } while (end != str.begin() && std::isspace(static_cast<unsigned char>(*end)));
    
    if (end == str.begin() && std::isspace(static_cast<unsigned char>(*end))) {
        return String();
    }
    
    return String(std::string(str.begin(), end + 1));
}

void Delete(String& s, Integer index, Integer count) {
    if (index < 1 || count <= 0) {
        return;
    }
    
    Integer len = s.Length();
    if (index > len) {
        return;
    }
    
    if (index + count - 1 > len) {
        count = len - index + 1;
    }
    
    std::u16string& data = const_cast<std::u16string&>(s.Data());
    data.erase(index - 1, count);
}

void Insert(const String& substr, String& s, Integer index) {
    if (index < 1) {
        return;
    }
    
    Integer len = s.Length();
    
    if (index > len) {
        s += substr;
        return;
    }
    
    std::u16string& data = const_cast<std::u16string&>(s.Data());
    data.insert(index - 1, substr.Data());
}

void String::SetLength(Integer newLength) {
    if (newLength < 0) {
        newLength = 0;
    }
    data_.resize(static_cast<size_t>(newLength));
}

void SetLength(String& s, Integer newLength) {
    s.SetLength(newLength);
}

void UniqueString(String& s) {
    String temp = s;
    s = temp;
}

void SetString(String& s, const char16_t* buffer, Integer length) {
    if (buffer == nullptr || length <= 0) {
        s = String();
        return;
    }
    s = String(std::u16string(buffer, static_cast<size_t>(length)));
}

void Val(const String& s, Integer& value, Integer& errorCode) {
    try {
        std::string str = s.ToStdString();
        size_t pos = 0;
        value = std::stoi(str, &pos);
        errorCode = (pos == str.length()) ? 0 : static_cast<Integer>(pos + 1);
    } catch (...) {
        errorCode = 1;
        value = 0;
    }
}

void Val(const String& s, Double& value, Integer& errorCode) {
    try {
        std::string str = s.ToStdString();
        size_t pos = 0;
        value = std::stod(str, &pos);
        errorCode = (pos == str.length()) ? 0 : static_cast<Integer>(pos + 1);
    } catch (...) {
        errorCode = 1;
        value = 0.0;
    }
}

void Str(Integer value, String& s) {
    s = IntToStr(value);
}

void Str(Double value, String& s) {
    s = FloatToStr(value);
}

void Str(Integer value, Integer width, String& s) {
    std::string result = std::to_string(value);
    if (width > 0 && static_cast<Integer>(result.length()) < width) {
        result = std::string(width - result.length(), ' ') + result;
    }
    s = String(result);
}

void Str(Double value, Integer width, Integer decimals, String& s) {
    char buffer[256];
    if (width > 0 && decimals >= 0) {
        snprintf(buffer, sizeof(buffer), "%*.*f", width, decimals, value);
    } else if (decimals >= 0) {
        snprintf(buffer, sizeof(buffer), "%.*f", decimals, value);
    } else {
        snprintf(buffer, sizeof(buffer), "%f", value);
    }
    s = String(buffer);
}

Char UpCase(Char c) {
    if (c >= u'a' && c <= u'z') {
        return c - (u'a' - u'A');
    }
    return c;
}

String StringOfChar(Char c, Integer count) {
    if (count <= 0) {
        return String();
    }
    return String(std::u16string(static_cast<size_t>(count), c));
}

Integer WideCharLen(const wchar_t* str) {
    if (str == nullptr) {
        return 0;
    }
    Integer len = 0;
    while (str[len] != L'\0') {
        len++;
    }
    return len;
}

String WideCharToString(const wchar_t* buffer, Integer length) {
    if (buffer == nullptr || length <= 0) {
        return String();
    }
    return String(std::wstring(buffer, static_cast<size_t>(length)));
}

void StringToWideChar(const String& s, wchar_t* buffer, Integer bufferSize) {
    if (buffer == nullptr || bufferSize <= 0) {
        return;
    }
    std::wstring wstr = s.ToWString();
    Integer copyLen = (static_cast<Integer>(wstr.length()) < bufferSize - 1) ? 
                      static_cast<Integer>(wstr.length()) : (bufferSize - 1);
    for (Integer i = 0; i < copyLen; ++i) {
        buffer[i] = wstr[i];
    }
    buffer[copyLen] = L'\0';
}

void WideCharToStrVar(const wchar_t* buffer, String& s) {
    if (buffer == nullptr) {
        s = String();
        return;
    }
    s = String(buffer);
}

} // namespace np
