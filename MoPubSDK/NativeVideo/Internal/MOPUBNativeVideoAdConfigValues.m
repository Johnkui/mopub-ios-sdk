//
//  MOPUBNativeVideoAdConfigValues.m
//  MoPubSDK
//
//  Copyright (c) 2015 MoPub. All rights reserved.
//

#import "MOPUBNativeVideoAdConfigValues.h"

//@interface MOPUBNativeVideoAdConfigValues ()
//@property (nonatomic, readwrite) NSInteger playVisiblePercent;
//@property (nonatomic, readwrite) NSInteger pauseVisiblePercent;
//@property (nonatomic, readwrite) NSInteger impressionMinVisiblePercent;
//@property (nonatomic, readwrite) NSTimeInterval impressionVisible;
//@property (nonatomic, readwrite) NSTimeInterval maxBufferingTime;
//@end

@implementation MOPUBNativeVideoAdConfigValues

- (instancetype)initWithPlayVisiblePercent:(NSInteger)playVisiblePercent
                       pauseVisiblePercent:(NSInteger)pauseVisiblePercent
               impressionMinVisiblePercent:(NSInteger)impressionMinVisiblePercent
                         impressionVisible:(NSTimeInterval)impressionVisible
                                 maxBufferingTime:(NSTimeInterval)maxBufferingTime
{
    self = [super init];
    if (self) {
        _playVisiblePercent = playVisiblePercent;
        _pauseVisiblePercent = pauseVisiblePercent;
        _impressionMinVisiblePercent = impressionMinVisiblePercent;
        _impressionVisible = impressionVisible;
        _maxBufferingTime = maxBufferingTime;
    }
    return self;
}

/// johnkui:
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _playVisiblePercent = [[aDecoder decodeObjectForKey:@"playVisiblePercent"] integerValue];
        _pauseVisiblePercent = [[aDecoder decodeObjectForKey:@"pauseVisiblePercent"] integerValue];
        _impressionMinVisiblePercent = [[aDecoder decodeObjectForKey:@"impressionMinVisiblePercent"] integerValue];
        _impressionVisible = [[aDecoder decodeObjectForKey:@"impressionVisible"] doubleValue];
        _maxBufferingTime = [[aDecoder decodeObjectForKey:@"maxBufferingTime"] doubleValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInteger:_playVisiblePercent] forKey:@"playVisiblePercent"];
    [aCoder encodeObject:[NSNumber numberWithInteger:_pauseVisiblePercent] forKey:@"pauseVisiblePercent"];
    [aCoder encodeObject:[NSNumber numberWithInteger:_impressionMinVisiblePercent] forKey:@"impressionMinVisiblePercent"];
    [aCoder encodeObject:[NSNumber numberWithDouble:_impressionVisible] forKey:@"impressionVisible"];
    [aCoder encodeObject:[NSNumber numberWithDouble:_maxBufferingTime] forKey:@"maxBufferingTime"];
}

- (BOOL)isValid
{
    return ([self isValidPercentage:self.playVisiblePercent] &&
            [self isValidPercentage:self.pauseVisiblePercent] &&
            [self isValidPercentage:self.impressionMinVisiblePercent] &&
            [self isValidTimeInterval:self.impressionVisible] &&
            [self isValidTimeInterval:self.maxBufferingTime]);
}

- (BOOL)isValidPercentage:(NSInteger)percentage
{
    return (percentage >= 0 && percentage <= 100);
}

- (BOOL)isValidTimeInterval:(NSTimeInterval)timeInterval
{
    return timeInterval > 0;
}

@end
