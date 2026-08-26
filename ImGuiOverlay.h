#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

@class ESPManager;

NS_ASSUME_NONNULL_BEGIN

@interface ImGuiOverlay : NSObject

@property (class, readonly, nonatomic) ImGuiOverlay *sharedInstance;

// Menu & UI Toggles
@property (nonatomic, assign) BOOL showMenu;
@property (nonatomic, assign) BOOL showFPS;

// ESP Toggles
@property (nonatomic, assign) BOOL showESP;
@property (nonatomic, assign) BOOL showLines;
@property (nonatomic, assign) BOOL showBoxes;

- (BOOL)isInteractingWithMenu;

- (void)setupWithDevice:(id<MTLDevice>)device
           commandQueue:(id<MTLCommandQueue>)queue
       colorPixelFormat:(MTLPixelFormat)pixelFormat;

- (void)beginFrameWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               renderPassDescriptor:(MTLRenderPassDescriptor *)rpd;

- (void)endFrameWithCommandEncoder:(id<MTLRenderCommandEncoder>)encoder;

// Touch handling
- (BOOL)handleTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (BOOL)handleTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (BOOL)handleTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (BOOL)handleTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;

@end

NS_ASSUME_NONNULL_END