//
//  WJKVideoPlayerManager.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WJKVideoPlayerDownloader.h"
#import "WJKVideoPlayerCache.h"
#import "WJKVideoPlayer.h"
#import "WJKVideoPlayerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class WJKVideoPlayerManager;

@protocol WJKVideoPlayerManagerDelegate <NSObject>

@optional

/**
 * Controls which video should be downloaded when the video is not found in the cache.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be downloaded.
 *
 * @return Return NO to prevent the downloading of the video on cache misses. If not implemented, YES is implied.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
 shouldDownloadVideoForURL:(NSURL *)videoURL;

/**
 * Controls which video should automatic replay when the video is play completed.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 *
 * @return Return NO to prevent replay for the video. If not implemented, YES is implied.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
    shouldAutoReplayForURL:(NSURL *)videoURL;

/**
 * Notify the playing status.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param playerStatus       The current playing status.
 */
- (void)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
    playerStatusDidChanged:(WJKVideoPlayerStatus)playerStatus;

/**
 * Notify the video file length.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoLength        The file length of video data.
 */
- (void)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
   didFetchVideoFileLength:(NSUInteger)videoLength;

/**
 Notify the playing cache ranges.
 
 @param videoPlayerManager videoPlayerManager.
 @param cacheRanges playerStatus.
 */
- (void)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
       cacheRangeDidChange:(NSArray<NSValue *> *)cacheRanges;

/**
 * Notify the download progress value. this method will be called on main thread.
 * If the video is local or cached file, this method will be called once and the receive size equal to expected size,
 * If video is existed on web, this method will be called when the download progress value changed,
 * If some error happened, the error is no nil.
 *
 * @param videoPlayerManager  The current `WJKVideoPlayerManager`.
 * @param cacheType           The video data cache type.
 * @param fragmentRanges      The fragment of video data that cached in disk.
 * @param expectedSize        The expected data size.
 * @param error               The error when download video data.
 */
- (void)videoPlayerManagerDownloadProgressDidChange:(WJKVideoPlayerManager *)videoPlayerManager
                                          cacheType:(WJKVideoPlayerCacheType)cacheType
                                     fragmentRanges:(NSArray<NSValue *> * _Nullable)fragmentRanges
                                       expectedSize:(NSUInteger)expectedSize
                                              error:(NSError *_Nullable)error;

/**
 * Notify the playing progress value. this method will be called on main thread.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param elapsedSeconds     The current played seconds.
 * @param totalSeconds       The total seconds of this video for given url.
 * @param error              The error when playing video.
 */
- (void)videoPlayerManagerPlayProgressDidChange:(WJKVideoPlayerManager *)videoPlayerManager
                                 elapsedSeconds:(double)elapsedSeconds
                                   totalSeconds:(double)totalSeconds
                                          error:(NSError *_Nullable)error;

/**
 * Called when application will resign active.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldPausePlaybackWhenApplicationWillResignActiveForURL:(NSURL *)videoURL;

/**
 * Called when application did enter background.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldPausePlaybackWhenApplicationDidEnterBackgroundForURL:(NSURL *)videoURL;

/**
 * Called only when application become active from `Control Center`,
 *  `Notification Center`, `pop UIAlert`, `double click Home-Button`.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldResumePlaybackWhenApplicationDidBecomeActiveFromResignActiveForURL:(NSURL *)videoURL;

/**
 * Called only when application become active from `Share to other application`,
 *  `Enter background`, `Lock screen`.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldResumePlaybackWhenApplicationDidBecomeActiveFromBackgroundForURL:(NSURL *)videoURL;

/**
 * Called when call resume play but can not resume play.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldTranslateIntoPlayVideoFromResumePlayForURL:(NSURL *)videoURL;

/**
 * Called when receive audio session interruption notification.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldPausePlaybackWhenReceiveAudioSessionInterruptionNotificationForURL:(NSURL *)videoURL;

/**
 * Provide custom audio session category to play video.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 *
 * @return The prefer audio session category.
 */
- (NSString *)videoPlayerManagerPreferAudioSessionCategory:(WJKVideoPlayerManager *)videoPlayerManager;

/**
 * Called when play a already played video.
 *
 * @param videoPlayerManager The current `WJKVideoPlayerManager`.
 * @param videoURL           The url of the video to be play.
 * @param elapsedSeconds     The elapsed seconds last playback recorded.
 */
- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldResumePlaybackFromPlaybackRecordForURL:(NSURL *)videoURL
            elapsedSeconds:(NSTimeInterval)elapsedSeconds;

@end

@interface WJKVideoPlayerManagerModel : NSObject

@property (nonatomic, strong, readonly) NSURL *videoURL;

@property (nonatomic, assign) WJKVideoPlayerCacheType cacheType;

@property (nonatomic, assign) NSUInteger fileLength;

/**
 * The fragment of video data that cached in disk.
 */
@property (nonatomic, strong, readonly, nullable) NSArray<NSValue *> *fragmentRanges;

@end

@interface WJKVideoPlayerManager : NSObject<WJKVideoPlayerPlaybackProtocol>

@property (weak, nonatomic, nullable) id <WJKVideoPlayerManagerDelegate> delegate;

@property (strong, nonatomic, readonly, nullable) WJKVideoPlayerCache *videoCache;

@property (strong, nonatomic, readonly, nullable) WJKVideoPlayerDownloader *videoDownloader;

@property (nonatomic, strong, readonly) WJKVideoPlayerManagerModel *managerModel;

@property (nonatomic, strong, readonly) WJKVideoPlayer *videoPlayer;

#pragma mark - Singleton and Initialization

/**
 * Returns global `WJKVideoPlayerManager` instance.
 *
 * @return `WJKVideoPlayerManager` shared instance
 */
+ (nonnull instancetype)sharedManager;

/**
 * Set the log level. `WJKLogLevelDebug` by default.
 *
 * @see `WJKLogLevel`.
 *
 * @param logLevel The log level to control log type.
 */
+ (void)preferLogLevel:(WJKLogLevel)logLevel;

/**
 * Allows to specify instance of cache and video downloader used with video manager.
 * @return new instance of `WJKVideoPlayerManager` with specified cache and downloader.
 */
- (nonnull instancetype)initWithCache:(nonnull WJKVideoPlayerCache *)cache
                           downloader:(nonnull WJKVideoPlayerDownloader *)downloader NS_DESIGNATED_INITIALIZER;


# pragma mark - Play Video

/**
 * Play the video for the given URL.
 
 * @param url                     The URL of video.
 * @param showLayer               The layer of video layer display on.
 * @param options                 A flag to specify options to use for this request.
 * @param configurationCompletion The block will be call when video player config finished. because initialize player is not synchronize,
 *                                 so other category method is disabled before config finished.
 */
- (void)playVideoWithURL:(NSURL *)url
             showOnLayer:(CALayer *)showLayer
                 options:(WJKVideoPlayerOptions)options
 configurationCompletion:(WJKPlayVideoConfigurationCompletion)configurationCompletion;

/**
 * Resume video play for the given URL.

 * @param url                     The URL of video.
 * @param showLayer               The layer of video layer display on.
 * @param options                 A flag to specify options to use for this request.
 * @param configurationCompletion The block will be call when video player config finished. because initialize player is not synchronize,
 *                                 so other category method is disabled before config finished.
 */
- (void)resumePlayWithURL:(NSURL *)url
              showOnLayer:(CALayer *)showLayer
                  options:(WJKVideoPlayerOptions)options
  configurationCompletion:(WJKPlayVideoConfigurationCompletion)configurationCompletion;

/**
 * Return the cache key for a given URL.
 */
- (NSString *_Nullable)cacheKeyForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
