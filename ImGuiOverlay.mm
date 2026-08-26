#import "ImGuiOverlay.h"
#import "ESPManager.h"

#include "imgui.h"
#include "imgui_impl_metal.h"
#include <chrono>

@interface ImGuiOverlay () {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _queue;
    id<MTLCommandBuffer> _currentCmdBuffer;

    // FPS tracking
    std::chrono::high_resolution_clock::time_point _lastTime;
    int _frameCount;
    float _fps;
    float _frameTime;
}
@end

@implementation ImGuiOverlay

- (BOOL)isInteractingWithMenu {
    ImGuiIO &io = ImGui::GetIO();
    return io.WantCaptureMouse || _showMenu;
}

+ (instancetype)sharedInstance {
    static ImGuiOverlay *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showMenu = YES;
        _showFPS = YES;
        _showESP = NO;
        _showLines = NO;
        _showBoxes =  NO;
        _fps = 0.0f;
        _frameTime = 0.0f;
        _frameCount = 0;
        _lastTime = std::chrono::high_resolution_clock::now();
    }
    return self;
}

- (void)setupWithDevice:(id<MTLDevice>)device
           commandQueue:(id<MTLCommandQueue>)queue
       colorPixelFormat:(MTLPixelFormat)pixelFormat {
    _device = device;
    _queue = queue;

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();
    io.IniFilename = NULL;

    // Styling
    ImGui::StyleColorsDark();
    ImGuiStyle &style = ImGui::GetStyle();
    style.WindowRounding = 8.0f;
    style.FrameRounding = 5.0f;
    style.PopupRounding = 5.0f;
    style.ScrollbarRounding = 5.0f;
    style.GrabRounding = 5.0f;
    style.WindowBorderSize = 1.0f;

    ImGui_ImplMetal_Init(device);
}

- (void)updateTelemetry {
    _frameCount++;
    auto currentTime = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float, std::chrono::milliseconds::period> elapsed = currentTime - _lastTime;
    if (elapsed.count() >= 500.0f) {
        _fps = (_frameCount * 1000.0f) / elapsed.count();
        _frameTime = elapsed.count() / _frameCount;
        _frameCount = 0;
        _lastTime = currentTime;
    }
}

- (void)beginFrameWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               renderPassDescriptor:(MTLRenderPassDescriptor *)rpd {
    _currentCmdBuffer = commandBuffer;
    [self updateTelemetry];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat scale = [UIScreen mainScreen].scale;

    // Landscape orientation check
    CGFloat screenW = fmaxf(screenBounds.size.width, screenBounds.size.height);
    CGFloat screenH = fminf(screenBounds.size.width, screenBounds.size.height);

    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize = ImVec2(screenW, screenH);
    io.DisplayFramebufferScale = ImVec2(scale, scale);

    ImGui_ImplMetal_NewFrame(rpd);
    ImGui::NewFrame();

    // -------------------- ESP UPDATE & DRAW --------------------
    if (_showESP) {
        ESPManager *esp = [ESPManager sharedInstance];
        esp.showLines = _showLines;
        esp.showBoxes = _showBoxes;
        [esp updateAndDraw];
    }
    // -----------------------------------------------------------

    // 1. Floating Quick Toggle Button
    ImGui::SetNextWindowPos(ImVec2(20, 20), ImGuiCond_FirstUseEver);
    ImGui::Begin("ToggleHUD", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_AlwaysAutoResize);
    if (ImGui::Button(_showMenu ? "Close Menu" : "Open Menu", ImVec2(100, 35))) {
        _showMenu = !_showMenu;
    }
    ImGui::End();

    // 2. Real-time Telemetry HUD (FPS & Frame Time)
    if (_showFPS) {
        ImGui::SetNextWindowPos(ImVec2(screenW - 170, 20), ImGuiCond_FirstUseEver);
        ImGui::Begin("Telemetry", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_AlwaysAutoResize);
        ImGui::TextColored(ImVec4(0.2f, 1.0f, 0.4f, 1.0f), "FPS: %.1f", _fps);
        ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Frame: %.2f ms", _frameTime);
        ImGui::End();
    }

    // 3. Main Configuration Menu
    if (_showMenu) {
        ImGui::SetNextWindowSize(ImVec2(340, 280), ImGuiCond_FirstUseEver);
        ImGui::Begin("Control Center", &_showMenu, ImGuiWindowFlags_NoCollapse);

        ImGui::Text("Telemetry");
        ImGui::Separator();
        ImGui::Checkbox("Show FPS Counter", &_showFPS);

        ImGui::Spacing();
        ImGui::Text("Visuals");
        ImGui::Separator();
        ImGui::Checkbox("Enable Visual Overlay", &_showESP);
        if (_showESP) {
            ImGui::Indent();
            ImGui::Checkbox("Tracers / Lines", &_showLines);
            ImGui::Checkbox("2D Boxes", &_showBoxes);
            ImGui::Unindent();
        }

        ImGui::Spacing();
        ImGui::Text("Settings");
        ImGui::Separator();
        if (ImGui::Button("Reset UI Positions", ImVec2(-1, 28))) {
            ImGui::SetWindowPos("ToggleHUD", ImVec2(20, 20));
            ImGui::SetWindowPos("Telemetry", ImVec2(screenW - 170, 20));
        }

        ImGui::End();
    }

    ImGui::Render();
}

- (void)endFrameWithCommandEncoder:(id<MTLRenderCommandEncoder>)encoder {
    if (_currentCmdBuffer && encoder) {
        ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), _currentCmdBuffer, encoder);
    }
}

#pragma mark - Touch Handling

- (BOOL)handleTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    ImGuiIO &io = ImGui::GetIO();
    UITouch *touch = [touches anyObject];
    if (!touch) return NO;
    CGPoint loc = [touch locationInView:touch.view];
    io.MousePos = ImVec2(loc.x, loc.y);
    io.MouseDown[0] = true;
    return io.WantCaptureMouse;
}

- (BOOL)handleTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    ImGuiIO &io = ImGui::GetIO();
    UITouch *touch = [touches anyObject];
    if (!touch) return NO;
    CGPoint loc = [touch locationInView:touch.view];
    io.MousePos = ImVec2(loc.x, loc.y);
    return io.WantCaptureMouse;
}

- (BOOL)handleTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    ImGuiIO &io = ImGui::GetIO();
    io.MouseDown[0] = false;
    return io.WantCaptureMouse;
}

- (BOOL)handleTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    ImGuiIO &io = ImGui::GetIO();
    io.MouseDown[0] = false;
    return io.WantCaptureMouse;
}

@end
