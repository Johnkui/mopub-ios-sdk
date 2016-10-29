//
//  MPNativeAd.m
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPNativeAd+Internal.h"
#import "MPAdConfiguration.h"
#import "MPCoreInstanceProvider.h"
#import "MPNativeAdError.h"
#import "MPLogging.h"
#import "MPNativeCache.h"
#import "MPNativeAdRendering.h"
#import "MPImageDownloadQueue.h"
#import "NSJSONSerialization+MPAdditions.h"
#import "MPNativeCustomEvent.h"
#import "MPNativeAdAdapter.h"
#import "MPNativeAdConstants.h"
#import "MPTimer.h"
#import "MPNativeAdRenderer.h"
#import "MPNativeAdDelegate.h"
#import "MPNativeView.h"
#import "MOPUBNativeVideoAdAdapter.h"
#import "MPMoPubNativeAdAdapter.h"
#import "MPStaticNativeAdRendererSettings.h"
#import "MPStaticNativeAdRenderer.h"
#import "MOPUBNativeVideoAdRenderer.h"
#import "MOPUBNativeVideoAdRendererSettings.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPNativeAd () <MPNativeAdAdapterDelegate, MPNativeViewDelegate>

@property (nonatomic, readwrite, strong) id<MPNativeAdRenderer> renderer;

@property (nonatomic, strong) NSDate *creationDate;

@property (nonatomic, strong) NSMutableSet *clickTrackerURLs;
@property (nonatomic, strong) NSMutableSet *impressionTrackerURLs;

@property (nonatomic, readonly, strong) id<MPNativeAdAdapter> adAdapter;
@property (nonatomic, assign) BOOL hasTrackedImpression;
@property (nonatomic, assign) BOOL hasTrackedClick;

@property (nonatomic, copy) NSString *adIdentifier;
@property (nonatomic) MPNativeView *associatedView;

@property (nonatomic) BOOL hasAttachedToView;

@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, strong)UITapGestureRecognizer *containerViewRecognizer;
@property (nonatomic, assign)BOOL offline;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPNativeAd

- (instancetype)initWithAdAdapter:(id<MPNativeAdAdapter>)adAdapter offline:(BOOL)offline
{
    static int sequenceNumber = 0;

    self = [super init];
    if (self) {
        _adAdapter = adAdapter;
        if ([_adAdapter respondsToSelector:@selector(setDelegate:)]) {
            [_adAdapter setDelegate:self];
        }
        _adIdentifier = [[NSString stringWithFormat:@"%d", sequenceNumber++] copy];
        _impressionTrackerURLs = [[NSMutableSet alloc] init];
        _clickTrackerURLs = [[NSMutableSet alloc] init];
        _creationDate = [NSDate date];
        _associatedView = [[MPNativeView alloc] init];
        _associatedView.clipsToBounds = YES;
        _associatedView.delegate = self;

        // Add a tap recognizer on top of the view if the ad network isn't handling clicks on its own.
        if (!([_adAdapter respondsToSelector:@selector(enableThirdPartyClickTracking)] && [_adAdapter enableThirdPartyClickTracking])) {
            UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(adViewTapped)];
            [_associatedView addGestureRecognizer:recognizer];
        }
        
        _offline = offline;
        if (offline) { /// Johnkui
            if ([adAdapter isKindOfClass:[MOPUBNativeVideoAdAdapter class]]) {
                MOPUBNativeVideoAdAdapter *videoAdapter = (MOPUBNativeVideoAdAdapter *)adAdapter;
                [_impressionTrackerURLs addObjectsFromArray:videoAdapter.impressionTrackerURLs];
                [_clickTrackerURLs addObjectsFromArray:videoAdapter.clickTrackerURLs];
                
                MOPUBNativeVideoAdRendererSettings *videoSettings = [[MOPUBNativeVideoAdRendererSettings alloc] init];
                _renderer =[[MOPUBNativeVideoAdRenderer alloc] initWithRendererSettings:videoSettings];

            } else if ([adAdapter isKindOfClass:[MPMoPubNativeAdAdapter class]]) {
                MPMoPubNativeAdAdapter *nativeAdapter = (MPMoPubNativeAdAdapter *)adAdapter;
                [_impressionTrackerURLs addObjectsFromArray:nativeAdapter.impressionTrackerURLs];
                [_clickTrackerURLs addObjectsFromArray:nativeAdapter.clickTrackerURLs];
                
                MPStaticNativeAdRendererSettings *staticSettings = [[MPStaticNativeAdRendererSettings alloc] init];
                _renderer =[[MPStaticNativeAdRenderer alloc] initWithRendererSettings:staticSettings];
            }
        }
    }
    return self;
}

/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
//- (instancetype)initWithAdAdapter:(id<MPNativeAdAdapter>)adAdapter addLinks:(BOOL)add {
//
//    static int sequenceNumber = 0;
//
//    self = [super init];
//    if (self) {
//        _adAdapter = adAdapter;
//        if ([_adAdapter respondsToSelector:@selector(setDelegate:)]) {
//            [_adAdapter setDelegate:self];
//        }
//        _adIdentifier = [[NSString stringWithFormat:@"%d", sequenceNumber++] copy];
//        _impressionTrackerURLs = [[NSMutableSet alloc] init];
//        _clickTrackerURLs = [[NSMutableSet alloc] init];
//        _creationDate = [NSDate date];
//        _associatedView = [[MPNativeView alloc] init];
//        _associatedView.clipsToBounds = YES;
//        _associatedView.delegate = self;
//        
//        // Add a tap recognizer on top of the view if the ad network isn't handling clicks on its own.
//        if (!([_adAdapter respondsToSelector:@selector(enableThirdPartyClickTracking)] && [_adAdapter enableThirdPartyClickTracking])) {
//            UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(adViewTapped)];
//            [_associatedView addGestureRecognizer:recognizer];
//        }
//        
//        if (add && ([adAdapter isKindOfClass:[MOPUBNativeVideoAdAdapter class]] ||
//                    [adAdapter isKindOfClass:[MPMoPubNativeAdAdapter class]])) {
//            if ([adAdapter isKindOfClass:[MOPUBNativeVideoAdAdapter class]]) {
//                MOPUBNativeVideoAdAdapter *videoAdapter = (MOPUBNativeVideoAdAdapter *)adAdapter;
//                [_impressionTrackerURLs addObjectsFromArray:videoAdapter.impressionTrackerURLs];
//                [_clickTrackerURLs addObjectsFromArray:videoAdapter.clickTrackerURLs];
//            } else if ([adAdapter isKindOfClass:[MPMoPubNativeAdAdapter class]]) {
//                MPMoPubNativeAdAdapter *nativeAdapter = (MPMoPubNativeAdAdapter *)adAdapter;
//                [_impressionTrackerURLs addObjectsFromArray:nativeAdapter.impressionTrackerURLs];
//                [_clickTrackerURLs addObjectsFromArray:nativeAdapter.clickTrackerURLs];
//            }
//        }
//    }
//    return self;
//}


#pragma mark - Public

- (UIView *)retrieveAdViewWithError:(NSError **)error
{
    // We always return the same MPNativeView (self.associatedView) so we need to remove its subviews
    // before attaching the new ad view to it.
    [[self.associatedView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UIView *adView = [self.renderer retrieveViewWithAdapter:self.adAdapter error:error];

    if (adView) {
        if (!self.hasAttachedToView) {
            [self willAttachToView:self.associatedView];
            self.hasAttachedToView = YES;
        }

        adView.frame = self.associatedView.bounds;
        [self.associatedView addSubview:adView];

        return self.associatedView;
    } else {
        return nil;
    }
}

/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
- (void)removeGestureRecognizerFromContainerView {
    [self.containerView removeGestureRecognizer:self.containerViewRecognizer];
}

/// From Johnkui: https://github.com/Johnkui/mopub-ios-sdk.git
- (void)setAdView:(UIView<MPNativeAdRendering> *) adView containerView:(UIView *)containerView error:(NSError **)error
{
    self.containerView = containerView;
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(adViewTapped)];
    [self.containerView addGestureRecognizer:recognizer];
    self.containerViewRecognizer = recognizer;
    
    [self.renderer setRenderingView:adView];
    
    UIView *renderedAdView = [self.renderer retrieveViewWithAdapter:self.adAdapter error:error];
    if (renderedAdView) {
        if (!self.hasAttachedToView) {
            [self willAttachToView:self.containerView];
            self.hasAttachedToView = YES;
        }
        
        [self nativeViewWillMoveToSuperview:self.containerView];
//        adView.frame = self.associatedView.bounds;
//        [self.associatedView addSubview:adView];
    }
}

- (NSDictionary *)properties
{
    return self.adAdapter.properties;
}

- (NSDictionary *)originalProperties {
    return self.adAdapter.originalProperties;
}

- (void)trackImpression
{
    if (self.hasTrackedImpression) {
        MPLogDebug(@"Impression already tracked.");
        return;
    }

    MPLogDebug(@"Tracking an impression for %@.", self.adIdentifier);
    self.hasTrackedImpression = YES;

    ///Johnkui:
    if ([self.delegate respondsToSelector:@selector(nativeMopubAdWillLogImpression:)]) {
        [self.delegate nativeMopubAdWillLogImpression:self];
    }
    
    [self trackMetricsForURLs:self.impressionTrackerURLs];
}

- (void)trackClick
{
    if (self.hasTrackedClick) {
        MPLogDebug(@"Click already tracked.");
        return;
    }

    MPLogDebug(@"Tracking a click for %@.", self.adIdentifier);
    self.hasTrackedClick = YES;
    [self trackMetricsForURLs:self.clickTrackerURLs];

    ///Johnkui:
    if ([self.delegate respondsToSelector:@selector(nativeMopubAdDidClick:)]) {
        [self.delegate nativeMopubAdDidClick:self];
    }
    
    if ([self.adAdapter respondsToSelector:@selector(trackClick)] && ![self isThirdPartyHandlingClicks]) {
        [self.adAdapter trackClick];
    }

}

- (void)trackMetricsForURLs:(NSSet *)URLs
{
    for (NSURL *URL in URLs) {
        [self trackMetricForURL:URL];
    }
}

- (void)trackMetricForURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [[MPCoreInstanceProvider sharedProvider] buildConfiguredURLRequestWithURL:URL];
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [NSURLConnection connectionWithRequest:request delegate:nil];
}

#pragma mark - Internal

- (void)willAttachToView:(UIView *)view
{
    if ([self.adAdapter respondsToSelector:@selector(willAttachToView:)]) {
        [self.adAdapter willAttachToView:view];
    }
}

- (BOOL)isThirdPartyHandlingClicks
{
    return [self.adAdapter respondsToSelector:@selector(enableThirdPartyClickTracking)] && [self.adAdapter enableThirdPartyClickTracking];
}

- (void)displayAdContent
{
    [self trackClick];

    if ([self.adAdapter respondsToSelector:@selector(displayContentForURL:rootViewController:)]) {
        if (!self.offline) { /// johnkui: offline ad click event should self deal
            [self.adAdapter displayContentForURL:self.adAdapter.defaultActionURL rootViewController:[self.delegate viewControllerForPresentingModalView]];
        }
    } else {
        // If this method is called, that means that the backing adapter should implement -displayContentForURL:rootViewController:completion:.
        // If it doesn't, we'll log a warning.
        MPLogWarn(@"Cannot display native ad content. -displayContentForURL:rootViewController:completion: not implemented by native ad adapter: %@", [self.adAdapter class]);
    }
}

#pragma mark - UITapGestureRecognizer

- (void)adViewTapped
{
    [self displayAdContent];

    if ([self.renderer respondsToSelector:@selector(nativeAdTapped)]) {
        [self.renderer nativeAdTapped];
    }
}

#pragma mark - MPNativeViewDelegate

- (void)nativeViewWillMoveToSuperview:(UIView *)superview
{
    if ([self.renderer respondsToSelector:@selector(adViewWillMoveToSuperview:)])
    {
        [self.renderer adViewWillMoveToSuperview:superview];
    }
}

#pragma mark - MPNativeAdAdapterDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)nativeAdWillLogImpression:(id<MPNativeAdAdapter>)adAdapter
{
    [self trackImpression];
}

- (void)nativeAdDidClick:(id<MPNativeAdAdapter>)adAdapter
{
    [self trackClick];
}

- (void)nativeAdWillPresentModalForAdapter:(id<MPNativeAdAdapter>)adapter
{
    if ([self.delegate respondsToSelector:@selector(willPresentModalForNativeAd:)]) {
        [self.delegate willPresentModalForNativeAd:self];
    }
}

- (void)nativeAdDidDismissModalForAdapter:(id<MPNativeAdAdapter>)adapter
{
    if ([self.delegate respondsToSelector:@selector(didDismissModalForNativeAd:)]) {
        [self.delegate didDismissModalForNativeAd:self];
    }
}

- (void)nativeAdWillLeaveApplicationFromAdapter:(id<MPNativeAdAdapter>)adapter
{
    if ([self.delegate respondsToSelector:@selector(willLeaveApplicationFromNativeAd:)]) {
        [self.delegate willLeaveApplicationFromNativeAd:self];
    }
}

@end
