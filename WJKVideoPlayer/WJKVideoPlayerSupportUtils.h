//
//  WJKVideoPlayerSupportUtils.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/4/28.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WJKResourceLoadingRequestTask.h"
#import "UITableView+WebVideoCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (StripQuery)

/*
 * Returns absolute string of URL with the query stripped out.
 * If there is no query, returns a copy of absolute string.
 */

- (NSString *)absoluteStringByStrippingQuery;

@end

@interface NSHTTPURLResponse (WJKVideoPlayer)

/**
 * Fetch the file length of response.
 *
 * @return The file length of response.
 */
- (long long)wjk_fileLength;

/**
 * Check the response support streaming or not.
 *
 * @return The response support streaming or not.
 */
- (BOOL)wjk_supportRange;

@end

@interface AVAssetResourceLoadingRequest (WJKVideoPlayer)

/**
 * Fill content information for current request use response conent.
 *
 * @param response A response.
 */
- (void)wjk_fillContentInformationWithResponse:(NSHTTPURLResponse *)response;

@end

@interface NSFileHandle (WJKVideoPlayer)

- (BOOL)wjk_safeWriteData:(NSData *)data;

@end

@interface NSURLSessionTask(WJKVideoPlayer)

@property(nonatomic) WJKResourceLoadingRequestWebTask * webTask;

@end

@interface NSObject (WJKSwizzle)

+ (BOOL)wjk_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel error:(NSError**)error;

@end

@interface WJKLog : NSObject

/**
 * Output message to console.
 *
 *  @param logLevel         The log type.
 *  @param file         The current file name.
 *  @param function     The current function name.
 *  @param line         The current line number.
 *  @param format       The log format.
 */
+ (void)logWithFlag:(WJKLogLevel)logLevel
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format, ...;

@end

#ifdef __OBJC__

#define WJK_LOG_MACRO(logFlag, frmt, ...) \
                                        [WJKLog logWithFlag:logFlag\
                                                      file:__FILE__ \
                                                  function:__FUNCTION__ \
                                                      line:__LINE__ \
                                                    format:(frmt), ##__VA_ARGS__]


#define WJK_LOG_MAYBE(logFlag, frmt, ...) WJK_LOG_MACRO(logFlag, frmt, ##__VA_ARGS__)

#if DEBUG

/**
 * Log debug log.
 */
#define WJKDebugLog(frmt, ...) WJK_LOG_MAYBE(WJKLogLevelDebug, frmt, ##__VA_ARGS__)

/**
 * Log debug and warning log.
 */
#define WJKWarningLog(frmt, ...) WJK_LOG_MAYBE(WJKLogLevelWarning, frmt, ##__VA_ARGS__)

/**
 * Log debug, warning and error log.
 */
#define WJKErrorLog(frmt, ...) WJK_LOG_MAYBE(WJKLogLevelError, frmt, ##__VA_ARGS__)

#else

#define WJKDebugLog(frmt, ...)
#define WJKWarningLog(frmt, ...)
#define WJKErrorLog(frmt, ...)
#endif

#endif

typedef NS_ENUM(NSInteger, WJKApplicationState) {
    WJKApplicationStateUnknown = 0,
    WJKApplicationStateWillResignActive,
    WJKApplicationStateDidEnterBackground,
    WJKApplicationStateWillEnterForeground,
    WJKApplicationStateDidBecomeActive
};

@class WJKApplicationStateMonitor;

@protocol WJKApplicationStateMonitorDelegate <NSObject>

@optional

/**
 * This method will be called when application state changed.
 *
 * @param monitor          The current object.
 * @param applicationState The application state.
 */
- (void)applicationStateMonitor:(WJKApplicationStateMonitor *)monitor
         applicationStateDidChange:(WJKApplicationState)applicationState;

/**
 * This method will be called only when application become active from `Control Center`,
 *  `Notification Center`, `pop UIAlert`, `double click Home-Button`.
 *
 * @param monitor The current object.
 */
- (void)applicationDidBecomeActiveFromResignActive:(WJKApplicationStateMonitor *)monitor;

/**
 * This method will be called only when application become active from `Share to other application`,
 *  `Enter background`, `Lock screen`.
 *
 * @param monitor The current object.
 */
- (void)applicationDidBecomeActiveFromBackground:(WJKApplicationStateMonitor *)monitor;

@end

@interface WJKApplicationStateMonitor : NSObject

@property(nonatomic, weak) id<WJKApplicationStateMonitorDelegate> delegate;

@property (nonatomic, assign, readonly) WJKApplicationState applicationState;

@end

@protocol WJKTableViewPlayVideoDelegate;

@interface WJKVideoPlayerTableViewHelper : NSObject

@property (nonatomic, weak, readonly, nullable) UITableView *tableView;

@property (nonatomic, weak, readonly) UITableViewCell *playingVideoCell;

@property (nonatomic, assign) CGRect tableViewVisibleFrame;

@property (nonatomic, assign) WJKScrollPlayStrategyType scrollPlayStrategyType;

@property(nonatomic) WJKPlayVideoInVisibleCellsBlock playVideoInVisibleCellsBlock;

@property(nonatomic) WJKPlayVideoInVisibleCellsBlock findBestCellInVisibleCellsBlock;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *unreachableCellDictionary;

@property (nonatomic, weak) id<WJKTableViewPlayVideoDelegate> delegate;

@property (nonatomic, assign) NSUInteger playVideoSection;

- (instancetype)initWithTableView:(UITableView *)tableView NS_DESIGNATED_INITIALIZER;

- (void)handleCellUnreachableTypeForCell:(UITableViewCell *)cell
                             atIndexPath:(NSIndexPath *)indexPath;

- (void)handleCellUnreachableTypeInVisibleCellsAfterReloadData;

- (void)playVideoInVisibleCellsIfNeed;

- (void)stopPlayIfNeed;

- (void)scrollViewDidScroll;

- (void)scrollViewDidEndDraggingWillDecelerate:(BOOL)decelerate;

- (void)scrollViewDidEndDecelerating;

- (BOOL)viewIsVisibleInVisibleFrameAtScrollViewDidScroll:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
