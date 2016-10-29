//
//  MPNativeAd.h
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MPNativeAdAdapter;
@protocol MPNativeAdDelegate;
@protocol MPNativeAdRendering;
@class MPAdConfiguration;

/**
 * The `MPNativeAd` class is used to render and manage events for a native advertisement. The
 * class provides methods for accessing native ad properties returned by the server, as well as
 * convenience methods for URL navigation and metrics-gathering.
 */

@interface MPNativeAd : NSObject

/** @name Ad Resources */

/**
 * The delegate of the `MPNativeAd` object.
 */
@property (nonatomic, weak) id<MPNativeAdDelegate> delegate;

/**
 * A dictionary representing the native ad properties.
 */
@property (nonatomic, readonly) NSDictionary *properties;

/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
/**
 * A dictionary representing the native ad adapter properties.
 */
@property (nonatomic, readonly) NSDictionary *originalProperties;

- (instancetype)initWithAdAdapter:(id<MPNativeAdAdapter>)adAdapter offline:(BOOL)offline;

/** @name Retrieving Ad View */

/**
 * Retrieves a rendered view containing the ad.
 *
 * @param error A pointer to an error object. If an error occurs, this pointer will be set to an
 * actual error object containing the error information.
 *
 * @return If successful, the method will return a view containing the rendered ad. The method will
 * return nil if it cannot render the ad data to a view.
 */
- (UIView *)retrieveAdViewWithError:(NSError **)error;

- (void)trackMetricForURL:(NSURL *)URL;


/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
//- (instancetype)initWithAdAdapter:(id<MPNativeAdAdapter>)adAdapter addLinks:(BOOL)add;

/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
- (void)removeGestureRecognizerFromContainerView;

/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
- (void)setAdView:(UIView<MPNativeAdRendering> *) adView containerView:(UIView *)containerView error:(NSError **)error;

@end
