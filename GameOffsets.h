#pragma once
#include <cstdint>
#include <mach-o/dyld.h>

// ---- STRUCTURE OFFSETS ----
#define OFFSET_ULEVEL                  0x30
#define OFFSET_NETDRIVER               0x38
#define OFFSET_SERVERCONNECTION        0x78
#define OFFSET_LOCALPLAYERCONTROLLER   0x98
#define OFFSET_ACTOR_ARRAY             0xE0
#define OFFSET_PLAYERCAMERAMANAGER     0x548
#define OFFSET_POV                     (0x10A0 + 0x10)
#define OFFSET_ROOTCOMPONENT           0x208
#define OFFSET_RELATIVELOCATION        0x1E4
#define OFFSET_TEAMID                  0x998
#define OFFSET_HEALTH                  0xE60
#define OFFSET_ISDEAD                  0xE7C
#define OFFSET_PLAYERNAME              0x960
#define OFFSET_ISAI                    0xA40

// ---- RAW RVA / STATIC OFFSETS (IDA/Ghidra Base: 0x100000000) ----
#define RVA_UWORLD                     0xC034388
#define RVA_PROJECT_WORLD_TO_SCREEN    0x62B69B8
#define RVA_GNAMES                     0xA5BD5F0

// ---- DYNAMIC ASLR RESOLUTION ----
inline uintptr_t GetMainExecutableSlide() {
    static uintptr_t slide = 0;
    static bool init = false;
    if (!init) {
        slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
        init = true;
    }
    return slide;
}

// Global dynamic pointers
#define ADDR_UWORLD                     (GetMainExecutableSlide() + 0x100000000 + RVA_UWORLD)
#define ADDR_PROJECT_WORLD_TO_SCREEN     (GetMainExecutableSlide() + 0x100000000 + RVA_PROJECT_WORLD_TO_SCREEN)
#define ADDR_GNAMES                     (GetMainExecutableSlide() + 0x100000000 + RVA_GNAMES)