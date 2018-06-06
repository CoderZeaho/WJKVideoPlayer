//
//  WJKVideoPlayerCompat.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/4/28.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAssetResourceLoader.h>
#import <objc/runtime.h>

@class WJKVideoPlayerModel;

#ifndef WJKVideoPlayerCompat
#define WJKVideoPlayerCompat

NS_ASSUME_NONNULL_BEGIN

#define WJKMainThreadAssert NSParameterAssert([[NSThread currentThread] isMainThread])

typedef NS_ENUM(NSInteger, WJKVideoPlayViewInterfaceOrientation) {
    WJKVideoPlayViewInterfaceOrientationUnknown          = 0,
    WJKVideoPlayViewInterfaceOrientationPortrait         = 1 << 0,
    WJKVideoPlayViewInterfaceOrientationLandscape        = 1 << 1,
    WJKVideoPlayViewInterfaceOrientationStrentchVertical = 1 << 2,
};

typedef NS_ENUM(NSUInteger, WJKVideoPlayerStatus)  {
    WJKVideoPlayerStatusUnknown = 0,
    WJKVideoPlayerStatusBuffering,
    WJKVideoPlayerStatusReadyToPlay,
    WJKVideoPlayerStatusPlaying,
    WJKVideoPlayerStatusPause,
    WJKVideoPlayerStatusFailed,
    WJKVideoPlayerStatusStop,
};

typedef NS_ENUM(NSInteger, WJKControlViewPanDirection){
    WJKControlViewPanDirectionHorizontalMoved, // 横向移动
    WJKControlViewPanDirectionVerticalMoved    // 纵向移动
};

typedef NS_ENUM(NSUInteger, WJKLogLevel) {
    // no log output.
    WJKLogLevelNone = 0,

    // output debug, warning and error log.
    WJKLogLevelError = 1,

    // output debug and warning log.
    WJKLogLevelWarning = 2,

    // output debug log.
    WJKLogLevelDebug = 3,
};

typedef NS_OPTIONS(NSUInteger, WJKVideoPlayerOptions) {
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    WJKVideoPlayerRetryFailed = 1 << 0,

    /**
     * In iOS 4+, continue the download of the video if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    WJKVideoPlayerContinueInBackground = 1 << 1,

    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    WJKVideoPlayerHandleCookies = 1 << 2,

    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    WJKVideoPlayerAllowInvalidSSLCertificates = 1 << 3,

    /**
     * Playing video muted.
     */
    WJKVideoPlayerMutedPlay = 1 << 4,

    /**
     * Stretch to fill layer bounds.
     */
    WJKVideoPlayerLayerVideoGravityResize = 1 << 5,

    /**
     * Preserve aspect ratio; fit within layer bounds.
     * Default value.
     */
    WJKVideoPlayerLayerVideoGravityResizeAspect = 1 << 6,

    /**
     * Preserve aspect ratio; fill layer bounds.
     */
    WJKVideoPlayerLayerVideoGravityResizeAspectFill = 1 << 7,

    // TODO: Disable cache if need.
};

typedef NS_OPTIONS(NSUInteger, WJKVideoPlayerDownloaderOptions) {
    /**
     * Call completion block with nil video/videoData if the image was read from NSURLCache
     * (to be combined with `WJKVideoPlayerDownloaderUseNSURLCache`).
     */
    WJKVideoPlayerDownloaderIgnoreCachedResponse = 1 << 0,

    /**
     * In iOS 4+, continue the download of the video if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    WJKVideoPlayerDownloaderContinueInBackground = 1 << 1,

    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    WJKVideoPlayerDownloaderHandleCookies = 1 << 2,

    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    WJKVideoPlayerDownloaderAllowInvalidSSLCertificates = 1 << 3,
};

typedef void(^WJKPlayVideoConfigurationCompletion)(UIView *_Nonnull view, WJKVideoPlayerModel *_Nonnull playerModel);

UIKIT_EXTERN NSString * _Nonnull const WJKVideoPlayerDownloadStartNotification;
UIKIT_EXTERN NSString * _Nonnull const WJKVideoPlayerDownloadReceiveResponseNotification;
UIKIT_EXTERN NSString * _Nonnull const WJKVideoPlayerDownloadStopNotification;
UIKIT_EXTERN NSString * _Nonnull const WJKVideoPlayerDownloadFinishNotification;
UIKIT_EXTERN NSString *const WJKVideoPlayerErrorDomain;
FOUNDATION_EXTERN const NSRange WJKInvalidRange;
static WJKLogLevel _logLevel;

#define WJKDEPRECATED_ATTRIBUTE(msg) __attribute__((deprecated(msg)));

/**
 * Dispatch block excute on main queue.
 */
void WJKDispatchSyncOnMainQueue(dispatch_block_t block);

/**
 * Call this method to check range valid or not.
 *
 * @param range The range wanna check valid.
 *
 * @return Yes means valid, otherwise NO.
 */
BOOL WJKValidByteRange(NSRange range);

/**
 * Call this method to check range is valid file range or not.
 *
 * @param range The range wanna check valid.
 *
 * @return Yes means valid, otherwise NO.
 */
BOOL WJKValidFileRange(NSRange range);

/**
 * Call this method to check the end point of range1 is equal to the start point of range2,
 * or the end point of range2 is equal to the start point of range2,
 * or this two range have intersection and the intersection greater than 0.
 *
 * @param range1 A file range.
 * @param range2 A file range.
 *
 * @return YES means those two range can be merge, otherwise NO.
 */
BOOL WJKRangeCanMerge(NSRange range1, NSRange range2);

/**
 * Convert a range to HTTP range header string.
 *
 * @param range A range.
 *
 * @return HTTP range header string
 */
NSString* WJKRangeToHTTPRangeHeader(NSRange range);

/**
 * Generate error object with error message.
 *
 * @param description The error message.
 *
 * @return A `NSError` object.
 */
NSError *WJKErrorWithDescription(NSString *description);

#endif

NS_ASSUME_NONNULL_END
