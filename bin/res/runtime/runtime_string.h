/**
 * NitroPascal Runtime - String Type
 * UTF-16 String class with 1-based indexing and Delphi semantics
 */

#pragma once

#include "runtime_types.h"
#include <string>
#include <iostream>

namespace np {

// Forward declarations
class String;
std::ostream& operator<<(std::ostream& os, const String& s);
std::wostream& operator<<(std::wostream& os, const String& s);

// ============================================================================
// STRING CLASS - UTF-16, 1-based indexing, Delphi semantics
// ============================================================================

class String {
private:
    std::u16string data_;

public:
    String();
    String(const char* s);
    String(const char16_t* s);
    String(const wchar_t* s);
    String(const std::string& s);
    String(const std::u16string& s);
    String(const std::wstring& s);
    
    char16_t operator[](Integer index) const;
    char16_t& operator[](Integer index);
    
    String operator+(const String& other) const;
    String& operator+=(const String& other);
    
    bool operator==(const String& other) const;
    bool operator!=(const String& other) const;
    bool operator<(const String& other) const;
    bool operator>(const String& other) const;
    bool operator<=(const String& other) const;
    bool operator>=(const String& other) const;
    
    Integer Length() const;
    void SetLength(Integer newLength);
    std::string ToStdString() const;
    std::wstring ToWString() const;
    const wchar_t* c_str_wide() const;
    
    std::string to_ansi() const {
        return ToStdString();
    }
    
    const std::u16string& Data() const { return data_; }
    
    friend std::ostream& operator<<(std::ostream& os, const String& s);
};

std::ostream& operator<<(std::ostream& os, const String& s);

inline std::wostream& operator<<(std::wostream& os, const String& s) {
    os << s.ToWString();
    return os;
}

// ============================================================================
// STRING UTILITY FUNCTIONS
// ============================================================================

Integer Length(const String& s);
String Copy(const String& s, Integer start, Integer count);
Integer Pos(const String& substr, const String& s);
String IntToStr(Integer value);
Integer StrToInt(const String& s);
Integer StrToIntDef(const String& s, Integer defaultValue);
String FloatToStr(Double value);
Double StrToFloat(const String& s);
String UpperCase(const String& s);
String LowerCase(const String& s);
String Trim(const String& s);
void Delete(String& s, Integer index, Integer count);
void Insert(const String& substr, String& s, Integer index);
inline void Insert(Char substr, String& s, Integer index) {
    char16_t buf[2] = {substr, 0};
    Insert(String(buf), s, index);
}
String TrimLeft(const String& s);
String TrimRight(const String& s);
void SetLength(String& s, Integer newLength);
void UniqueString(String& s);
void SetString(String& s, const char16_t* buffer, Integer length);
void Val(const String& s, Integer& value, Integer& errorCode);
void Val(const String& s, Double& value, Integer& errorCode);
void Str(Integer value, String& s);
void Str(Double value, String& s);
void Str(Integer value, Integer width, String& s);
void Str(Double value, Integer width, Integer decimals, String& s);
Char UpCase(Char c);
String StringOfChar(Char c, Integer count);
Integer WideCharLen(const wchar_t* str);
String WideCharToString(const wchar_t* buffer, Integer length);
void StringToWideChar(const String& s, wchar_t* buffer, Integer bufferSize);
void WideCharToStrVar(const wchar_t* buffer, String& s);

} // namespace np
