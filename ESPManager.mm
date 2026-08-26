#import "ESPManager.h"
#import "MemoryHelper.h"
#import "GameOffsets.h"
#import "GameStructs.h"
#include "imgui.h"

#include <vector>
#include <string>
#include <cmath>

@implementation ESPManager

+ (instancetype)sharedInstance {
    static ESPManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showLines = YES;
        _showBoxes = YES;
    }
    return self;
}

- (bool)projectWorldToScreen:(FVector)worldPos outScreen:(FVector2D&)outScreen {
    if (!ADDR_PROJECT_WORLD_TO_SCREEN) return false;

    typedef bool (*ProjectFn)(uintptr_t, FVector*, FVector2D*);
    ProjectFn fn = (ProjectFn)ADDR_PROJECT_WORLD_TO_SCREEN;
    
    uintptr_t UWorld = Read<uintptr_t>(ADDR_UWORLD);
    if (!UWorld) return false;
    
    uintptr_t NetDriver = Read<uintptr_t>(UWorld + OFFSET_NETDRIVER);
    if (!NetDriver) return false;
    
    uintptr_t ServerConn = Read<uintptr_t>(NetDriver + OFFSET_SERVERCONNECTION);
    if (!ServerConn) return false;
    
    uintptr_t LocalPC = Read<uintptr_t>(ServerConn + OFFSET_LOCALPLAYERCONTROLLER);
    if (!LocalPC) return false;
    
    uintptr_t CameraManager = Read<uintptr_t>(LocalPC + OFFSET_PLAYERCAMERAMANAGER);
    if (!CameraManager) return false;

    return fn(CameraManager, &worldPos, &outScreen);
}

- (void)updateAndDraw {
    uintptr_t UWorld = Read<uintptr_t>(ADDR_UWORLD);
    if (!UWorld) return;
    
    uintptr_t Level = Read<uintptr_t>(UWorld + OFFSET_ULEVEL);
    if (!Level) return;
    
    uintptr_t NetDriver = Read<uintptr_t>(UWorld + OFFSET_NETDRIVER);
    if (!NetDriver) return;
    
    uintptr_t ServerConn = Read<uintptr_t>(NetDriver + OFFSET_SERVERCONNECTION);
    if (!ServerConn) return;
    
    uintptr_t LocalPC = Read<uintptr_t>(ServerConn + OFFSET_LOCALPLAYERCONTROLLER);
    if (!LocalPC) return;
    
    int LocalTeam = Read<int>(LocalPC + OFFSET_TEAMID);
    
    uintptr_t ActorArray = Read<uintptr_t>(Level + OFFSET_ACTOR_ARRAY);
    int ActorCount = Read<int>(Level + OFFSET_ACTOR_ARRAY + 0x8);
    if (!ActorArray || ActorCount <= 0) return;
    if (ActorCount > 1024) ActorCount = 1024;

    ImDrawList* drawList = ImGui::GetForegroundDrawList();
    if (!drawList) return;
    
    ImVec2 screenCenter = ImVec2(ImGui::GetIO().DisplaySize.x * 0.5f, ImGui::GetIO().DisplaySize.y * 0.5f);
    int nearbyCount = 0;

    for (int i = 0; i < ActorCount; i++) {
        uintptr_t Actor = Read<uintptr_t>(ActorArray + (i * 8));
        if (!Actor) continue;

        int Team = Read<int>(Actor + OFFSET_TEAMID);
        if (Team <= 0 || Team == LocalTeam) continue;

        float Health = Read<float>(Actor + OFFSET_HEALTH);
        bool bDead = Read<bool>(Actor + OFFSET_ISDEAD);
        if (bDead || Health <= 0.0f) continue;

        uintptr_t RootComp = Read<uintptr_t>(Actor + OFFSET_ROOTCOMPONENT);
        if (!RootComp) continue;
        
        FVector WorldPos = Read<FVector>(RootComp + OFFSET_RELATIVELOCATION);
        FVector2D ScreenPos;
        
        if (![self projectWorldToScreen:WorldPos outScreen:ScreenPos]) continue;

        float Distance = sqrtf(WorldPos.X * WorldPos.X + WorldPos.Y * WorldPos.Y + WorldPos.Z * WorldPos.Z) / 100.0f;
        if (Distance < 100.0f) nearbyCount++;
        
        ImVec2 screen(ScreenPos.X, ScreenPos.Y);

        // ---- LINE ----
        if (self.showLines) {
            drawList->AddLine(screenCenter, screen, IM_COL32(255, 50, 50, 220), 1.5f);
        }

        // ---- BOX ----
        if (self.showBoxes) {
            float boxH = 1500.0f / (Distance > 1.0f ? Distance : 1.0f);
            if (boxH > 150.0f) boxH = 150.0f;
            if (boxH < 20.0f) boxH = 20.0f;
            float boxW = boxH * 0.5f;

            drawList->AddRect(ImVec2(screen.x - boxW * 0.5f, screen.y - boxH), 
                              ImVec2(screen.x + boxW * 0.5f, screen.y), 
                              IM_COL32(50, 255, 50, 255), 0.0f, 0, 1.5f);
            
            // Health Bar
            float healthRatio = Health / 100.0f;
            if (healthRatio > 1.0f) healthRatio = 1.0f;
            if (healthRatio < 0.0f) healthRatio = 0.0f;

            drawList->AddRectFilled(ImVec2(screen.x - boxW * 0.5f, screen.y + 2.0f), 
                                    ImVec2(screen.x - boxW * 0.5f + (boxW * healthRatio), screen.y + 5.0f), 
                                    IM_COL32(0, 255, 0, 255));
        }
    }

    // ---- CENTER ENEMY COUNT ----
    if (nearbyCount > 0) {
        char text[32];
        snprintf(text, sizeof(text), "Enemies: %d", nearbyCount);
        drawList->AddText(ImVec2(screenCenter.x - 30.0f, 50.0f), IM_COL32(255, 230, 0, 255), text);
    }
}

@end