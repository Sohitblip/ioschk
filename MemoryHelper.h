#pragma once
#include <cstdint>
#include <string>
#include <vector>
#include <iostream>
#include <mach/mach.h>

inline bool IsValidPtr(uintptr_t ptr) {
    return (ptr >= 0x100000000 && ptr < 0x2000000000);
}

template<typename T>
inline T Read(uintptr_t address) {
    if (!IsValidPtr(address)) return T();
    
    T buffer;
    vm_size_t size = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)address, sizeof(T), (vm_address_t)&buffer, &size);
    if (kr != KERN_SUCCESS || size != sizeof(T)) {
        return T();
    }
    return buffer;
}

template<typename T>
inline void Write(uintptr_t address, T value) {
    if (!IsValidPtr(address)) return;
    vm_write(mach_task_self(), (vm_address_t)address, (vm_offset_t)&value, sizeof(T));
}

inline std::string ReadFString(uintptr_t address) {
    if (!IsValidPtr(address)) return "";

    uintptr_t DataPtr = Read<uintptr_t>(address);
    int32_t Length = Read<int32_t>(address + 0x8);

    if (!IsValidPtr(DataPtr) || Length <= 0 || Length > 64) return "";

    wchar_t wstr[64] = {0};
    vm_size_t size = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)DataPtr, Length * sizeof(wchar_t), (vm_address_t)wstr, &size);
    if (kr != KERN_SUCCESS) return "";

    std::wstring ws(wstr, Length);
    return std::string(ws.begin(), ws.end());
}
