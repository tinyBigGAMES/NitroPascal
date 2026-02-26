/**
 * NitroPascal Runtime - File I/O
 */

#pragma once

#include "runtime_types.h"
#include "runtime_string.h"
#include <fstream>
#include <string>
#include <vector>
#include <sys/stat.h>

namespace np {

// ============================================================================
// TEXT FILE
// ============================================================================

struct TextFile {
    std::wfstream* stream;
    std::wstring filename;
    bool is_open;
    
    TextFile() : stream(nullptr), is_open(false) {}
    
    ~TextFile() {
        if (stream && is_open) {
            stream->close();
            delete stream;
        }
    }
};

using Text = TextFile;

// ============================================================================
// BINARY FILE
// ============================================================================

struct BinaryFile {
    std::fstream* stream;
    std::string filename;
    bool is_open;
    Integer record_size;
    
    BinaryFile() : stream(nullptr), is_open(false), record_size(1) {}
    
    ~BinaryFile() {
        if (stream && is_open) {
            stream->close();
            delete stream;
        }
    }
};

// ============================================================================
// TEXT FILE OPERATIONS
// ============================================================================

inline void AssignFile(Text& AFile, const String& AFileName) {
    AFile.filename = AFileName.ToWString();
}

inline void Reset(Text& AFile) {
    if (AFile.stream) {
        delete AFile.stream;
    }
    std::string fname(AFile.filename.begin(), AFile.filename.end());
    AFile.stream = new std::wfstream(fname, std::ios::in);
    AFile.is_open = AFile.stream && AFile.stream->is_open();
}

inline void Rewrite(Text& AFile) {
    if (AFile.stream) {
        delete AFile.stream;
    }
    std::string fname(AFile.filename.begin(), AFile.filename.end());
    AFile.stream = new std::wfstream(fname, std::ios::out | std::ios::trunc);
    AFile.is_open = AFile.stream && AFile.stream->is_open();
}

inline void Append(Text& AFile) {
    if (AFile.stream) {
        delete AFile.stream;
    }
    std::string fname(AFile.filename.begin(), AFile.filename.end());
    AFile.stream = new std::wfstream(fname, std::ios::out | std::ios::app);
    AFile.is_open = AFile.stream && AFile.stream->is_open();
}

inline void CloseFile(Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        AFile.stream->close();
        AFile.is_open = false;
    }
}

inline void WriteLn(Text& AFile, const String& AText) {
    if (AFile.stream && AFile.is_open) {
        *AFile.stream << AText.ToWString() << std::endl;
    }
}

template<typename... Args>
void WriteLn(Text& AFile, Args&&... args) {
    if (AFile.stream && AFile.is_open) {
        (*AFile.stream << ... << std::forward<Args>(args));
        *AFile.stream << std::endl;
    }
}

template<typename... Args>
void Write(Text& AFile, Args&&... args) {
    if (AFile.stream && AFile.is_open) {
        (*AFile.stream << ... << std::forward<Args>(args));
    }
}

inline void WriteLn(Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        *AFile.stream << std::endl;
    }
}

inline void ReadLn(Text& AFile, String& ALine) {
    if (AFile.stream && AFile.is_open) {
        std::wstring line;
        std::getline(*AFile.stream, line);
        ALine = String(line);
    }
}

inline Boolean Eof(const Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        return AFile.stream->peek() == std::char_traits<wchar_t>::eof();
    }
    return true;
}

inline Boolean Eoln(const Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        wchar_t ch = static_cast<wchar_t>(AFile.stream->peek());
        return (ch == L'\n' || ch == std::char_traits<wchar_t>::eof());
    }
    return true;
}

inline void Read(Text& AFile, Integer& AValue) {
    if (AFile.stream && AFile.is_open) {
        *AFile.stream >> AValue;
    }
}

inline void Read(Text& AFile, Double& AValue) {
    if (AFile.stream && AFile.is_open) {
        *AFile.stream >> AValue;
    }
}

inline void Read(Text& AFile, String& AValue) {
    if (AFile.stream && AFile.is_open) {
        std::wstring temp;
        *AFile.stream >> temp;
        AValue = String(temp);
    }
}

inline void Read(Text& AFile, Char& AValue) {
    if (AFile.stream && AFile.is_open) {
        wchar_t ch;
        // Skip leading whitespace to match Delphi text file Read behavior
        *AFile.stream >> std::ws;
        AFile.stream->get(ch);
        AValue = static_cast<char16_t>(ch);
    }
}

inline Boolean SeekEof(Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        while (true) {
            auto ch_int = AFile.stream->peek();
            // Check for EOF first
            if (ch_int == std::char_traits<wchar_t>::eof()) {
                return true;
            }
            wchar_t ch = static_cast<wchar_t>(ch_int);
            if (!std::isspace(ch)) {
                return false;
            }
            AFile.stream->get();
        }
    }
    return true;
}

inline Boolean SeekEoln(Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        while (!AFile.stream->eof()) {
            wchar_t ch = static_cast<wchar_t>(AFile.stream->peek());
            if (ch == L'\n') {
                return true;
            }
            if (!std::isspace(ch)) {
                return false;
            }
            AFile.stream->get();
        }
    }
    return true;
}

inline void Flush(Text& AFile) {
    if (AFile.stream && AFile.is_open) {
        AFile.stream->flush();
    }
}

// ============================================================================
// BINARY FILE OPERATIONS
// ============================================================================

inline void AssignFile(BinaryFile& AFile, const String& AFileName) {
    AFile.filename = std::string(AFileName.Data().begin(), AFileName.Data().end());
}

inline void Reset(BinaryFile& AFile) {
    if (AFile.stream) {
        delete AFile.stream;
    }
    AFile.stream = new std::fstream(AFile.filename, std::ios::in | std::ios::binary);
    AFile.is_open = AFile.stream && AFile.stream->is_open();
}

inline void Reset(BinaryFile& AFile, const Integer ARecordSize) {
    AFile.record_size = ARecordSize;
    Reset(AFile);
}

inline void Rewrite(BinaryFile& AFile) {
    if (AFile.stream) {
        delete AFile.stream;
    }
    AFile.stream = new std::fstream(AFile.filename, std::ios::out | std::ios::binary | std::ios::trunc);
    AFile.is_open = AFile.stream && AFile.stream->is_open();
}

inline void Rewrite(BinaryFile& AFile, const Integer ARecordSize) {
    AFile.record_size = ARecordSize;
    Rewrite(AFile);
}

inline void CloseFile(BinaryFile& AFile) {
    if (AFile.stream && AFile.is_open) {
        AFile.stream->close();
        AFile.is_open = false;
    }
}

template<typename T>
inline void BlockRead(BinaryFile& AFile, T& ABuffer, const Integer ACount, Integer& ABytesRead) {
    if (AFile.stream && AFile.is_open) {
        AFile.stream->read(reinterpret_cast<char*>(&ABuffer), ACount * AFile.record_size);
        ABytesRead = static_cast<Integer>(AFile.stream->gcount());
    } else {
        ABytesRead = 0;
    }
}

template<typename T>
inline void BlockRead(BinaryFile& AFile, T& ABuffer, const Integer ACount) {
    Integer bytesRead;
    BlockRead(AFile, ABuffer, ACount, bytesRead);
}

template<typename T>
inline void BlockWrite(BinaryFile& AFile, const T& ABuffer, const Integer ACount, Integer& ABytesWritten) {
    if (AFile.stream && AFile.is_open) {
        AFile.stream->write(reinterpret_cast<const char*>(&ABuffer), ACount * AFile.record_size);
        ABytesWritten = AFile.stream->good() ? ACount : 0;
    } else {
        ABytesWritten = 0;
    }
}

template<typename T>
inline void BlockWrite(BinaryFile& AFile, const T& ABuffer, const Integer ACount) {
    Integer bytesWritten;
    BlockWrite(AFile, ABuffer, ACount, bytesWritten);
}

inline Integer FileSize(BinaryFile& AFile) {
    if (AFile.stream && AFile.is_open) {
        auto current = AFile.stream->tellg();
        AFile.stream->seekg(0, std::ios::end);
        auto size = AFile.stream->tellg();
        AFile.stream->seekg(current);
        return static_cast<Integer>(size) / AFile.record_size;
    }
    return 0;
}

inline Integer FilePos(BinaryFile& AFile) {
    if (AFile.stream && AFile.is_open) {
        return static_cast<Integer>(AFile.stream->tellg()) / AFile.record_size;
    }
    return 0;
}

inline void Seek(BinaryFile& AFile, const Integer APosition) {
    if (AFile.stream && AFile.is_open) {
        AFile.stream->seekg(APosition * AFile.record_size);
        AFile.stream->seekp(APosition * AFile.record_size);
    }
}

inline Boolean Eof(const BinaryFile& AFile) {
    if (AFile.stream && AFile.is_open) {
        return AFile.stream->peek() == std::char_traits<char>::eof();
    }
    return true;
}

inline void Truncate(BinaryFile& AFile) {
    if (AFile.stream && AFile.is_open) {
        // Truncate at current position
        // Note: This is a simplified implementation
        // In a full implementation, platform-specific calls would be used
        auto pos = AFile.stream->tellp();
        AFile.stream->flush();
        
        // Close and reopen with truncate at position
        // This is approximate behavior - proper implementation needs platform APIs
        std::string fname = AFile.filename;
        AFile.stream->close();
        delete AFile.stream;
        
        // Read existing content up to pos
        std::ifstream in(fname, std::ios::binary);
        std::vector<char> content(static_cast<size_t>(pos));
        if (in.is_open() && pos > 0) {
            in.read(content.data(), pos);
            in.close();
        }
        
        // Write back truncated content
        std::ofstream out(fname, std::ios::binary | std::ios::trunc);
        if (out.is_open() && pos > 0) {
            out.write(content.data(), pos);
            out.close();
        }
        
        // Reopen for continued use
        AFile.stream = new std::fstream(fname, std::ios::in | std::ios::out | std::ios::binary);
        AFile.is_open = AFile.stream && AFile.stream->is_open();
        if (AFile.is_open) {
            AFile.stream->seekp(pos);
        }
    }
}

inline Integer IOResult() {
    return 0;
}

// ============================================================================
// FILE SYSTEM OPERATIONS
// ============================================================================

inline Boolean FileExists(const String& AFileName) {
    std::string fname(AFileName.Data().begin(), AFileName.Data().end());
    std::ifstream f(fname);
    return f.good();
}

inline Boolean DeleteFile(const String& AFileName) {
    std::string fname(AFileName.Data().begin(), AFileName.Data().end());
    return std::remove(fname.c_str()) == 0;
}

inline Boolean RenameFile(const String& AOldName, const String& ANewName) {
    std::string old_name(AOldName.Data().begin(), AOldName.Data().end());
    std::string new_name(ANewName.Data().begin(), ANewName.Data().end());
    return std::rename(old_name.c_str(), new_name.c_str()) == 0;
}

Boolean DirectoryExists(const String& ADirName);

Boolean CreateDir(const String& ADirName);

String GetCurrentDir();

} // namespace np
