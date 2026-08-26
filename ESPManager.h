#pragma once
#import <Foundation/Foundation.h>
#import "imgui.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPManager : NSObject

@property (class, readonly, nonatomic) ESPManager *sharedInstance;
@property (nonatomic, assign) BOOL showLines;
@property (nonatomic, assign) BOOL showBoxes;

- (void)updateAndDraw;

@end

NS_ASSUME_NONNULL_END