#include "ImGuiOverlay.h"
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <pthread.h>
#include <unistd.h>

@interface OverlayWindow : UIWindow
@end

@implementation OverlayWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([ImGuiOverlay sharedInstance].showMenu) {
        return [super hitTest:point withEvent:event];
    }
    CGRect toggleButtonRect = CGRectMake(10, 10, 140, 60);
    if (CGRectContainsPoint(toggleButtonRect, point)) {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}
@end

@interface OverlayViewController : UIViewController <MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

@implementation OverlayViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return;

    self.commandQueue = [device newCommandQueue];
    if (!self.commandQueue) return;

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.mtkView = [[MTKView alloc] initWithFrame:screenBounds device:device];
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.mtkView.framebufferOnly = NO;
    self.mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mtkView];

    [[ImGuiOverlay sharedInstance] setupWithDevice:device
                                      commandQueue:self.commandQueue
                                  colorPixelFormat:self.mtkView.colorPixelFormat];
}

- (void)drawInMTKView:(MTKView *)view {
    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!rpd || !drawable) return;

    rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    rpd.colorAttachments[0].storeAction = MTLStoreActionStore;

    id<MTLCommandBuffer> cmdBuf = [self.commandQueue commandBuffer];
    if (!cmdBuf) return;

    [[ImGuiOverlay sharedInstance] beginFrameWithCommandBuffer:cmdBuf renderPassDescriptor:rpd];

    id<MTLRenderCommandEncoder> enc = [cmdBuf renderCommandEncoderWithDescriptor:rpd];
    if (enc) {
        [[ImGuiOverlay sharedInstance] endFrameWithCommandEncoder:enc];
        [enc endEncoding];
    }

    [cmdBuf presentDrawable:drawable];
    [cmdBuf commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[ImGuiOverlay sharedInstance] handleTouchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[ImGuiOverlay sharedInstance] handleTouchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[ImGuiOverlay sharedInstance] handleTouchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[ImGuiOverlay sharedInstance] handleTouchesCancelled:touches withEvent:event];
}
@end

static OverlayWindow *g_overlayWindow = nil;

static void SetupOverlayWindow() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }

        if (scene) {
            g_overlayWindow = [[OverlayWindow alloc] initWithWindowScene:scene];
        } else {
            g_overlayWindow = [[OverlayWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        g_overlayWindow.windowLevel = UIWindowLevelAlert + 1000.0;
        g_overlayWindow.backgroundColor = [UIColor clearColor];
        g_overlayWindow.rootViewController = [[OverlayViewController alloc] init];
        g_overlayWindow.hidden = NO;
        g_overlayWindow.userInteractionEnabled = YES;
    });
}

static void* SafeInitThread(void*) {
    // Game engine aur splash screens load hone ke liye safe delay
    sleep(6);
    SetupOverlayWindow();
    return NULL;
}

__attribute__((constructor))
static void entry() {
    pthread_t thread;
    pthread_create(&thread, NULL, SafeInitThread, NULL);
}
