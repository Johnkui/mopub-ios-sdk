//
//  MOPUBNativeVideoAdRenderer.h
//  Copyright (c) 2015 MoPub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPNativeAdRenderer.h"

@class MPNativeAdRendererConfiguration;
@class MPStaticNativeAdRendererSettings;
@protocol MPNativeAdRenderer;

@interface MOPUBNativeVideoAdRenderer : NSObject<MPNativeAdRenderer>

@property (nonatomic, readonly) MPNativeViewSizeHandler viewSizeHandler;

- (instancetype)initWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings; /// Johnkui
+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings;

@end
