#pragma once
#include <cstdint>
#include <string>
#include <vector>
#include <iostream>
#include <mach/mach.h>

// Direct read helper
template<typename T>
inline T Read(uintptr_t address) {
    if (!address) return T();
    return *(T*)address;
}

// Direct write helper
template<typename T>
inline void Write(uintptr_t address, T value) {
    if (!address) return;
    *(T*)address = value;
}

// FString read helper
inline std::string ReadFString(uintptr_t address) {
    if (!address) return "";

    uintptr_t DataPtr = Read<uintptr_t>(address);
    int32_t Length = Read<int32_t>(address + 0x8);

    if (!DataPtr || Length <= 0 || Length > 128) return "";

    wchar_t* wstr = (wchar_t*)DataPtr;
    std::wstring ws(wstr, Length);
    return std::string(ws.begin(), ws.end());
}