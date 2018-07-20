//
//  WJKVideoPlayer.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/4/28.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WJKVideoPlayerCompat.h"
#import "WJKVideoPlayerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class WJKVideoPlayer,
       WJKResourceLoadingRequestWebTask,
       WJKVideoPlayerResourceLoader;

@protocol WJKVideoPlayerInternalDelegate <NSObject>

@required
/**
 * This method will be called when the current instance receive new loading request.
 *
 * @param videoPlayer The current `WJKVideoPlayer`.
 * @prama requestTask A abstract instance packageing the loading request.
 */
- (void)videoPlayer:(WJKVideoPlayer *)videoPlayer
didReceiveLoadingRequestTask:(WJKResourceLoadingRequestWebTask *)requestTask;

@optional
/**
 * Controls which video should automatic replay when the video is playing completed.
 *
 * @param videoPlayer   The current `WJKVideoPlayer`.
 * @param videoURL      The url of the video to be play.
 *
 * @return Return NO to prevent replay for the video. If not implemented, YES is implied.
 */
- (BOOL)videoPlayer:(nonnull WJKVideoPlayer *)videoPlayer
shouldAutoReplayVideoForURL:(nonnull NSURL *)videoURL;

/**
 * Notify the player status.
 *
 * @param videoPlayer   The current `WJKVideoPlayer`.
 * @param playerStatus  The current player status.
 */
- (void)videoPlayer:(nonnull WJKVideoPlayer *)videoPlayer
playerStatusDidChange:(WJKVideoPlayerStatus)playerStatus;

/**
 * Notify the playing progress value. this method will be called on main thread.
 *
 * @param videoPlayer        The current `videoPlayer`.
 * @param elapsedSeconds     The current played seconds.
 * @param totalSeconds       The total seconds of this video for given url.
 */
- (void)videoPlayerPlayProgressDidChange:(nonnull WJKVideoPlayer *)videoPlayer
                          elapsedSeconds:(double)elapsedSeconds
                            totalSeconds:(double)totalSeconds;

/**
 * Called on some error raise in player.
 *
 * @param videoPlayer The current instance.
 * @param error       The error.
 */
- (void)videoPlayer:(nonnull WJKVideoPlayer *)videoPlayer
playFailedWithError:(NSError *)error;


/**
 Update cache range when automatic caching is not supported

 @param videoPlayer videoPlayer.
 @param cacheRanges cacheRanges.
 */
- (void)videoPlayer:(nonnull WJKVideoPlayer *)videoPlayer cacheRangeDidChange:(NSArray<NSValue *> *)cacheRanges;

@end

@interface WJKVideoPlayerModel : NSObject<WJKVideoPlayerPlaybackProtocol>

/**
 * The current player's layer.
 */
@property (nonatomic, strong, readonly, nullable) AVPlayerLayer *playerLayer;

/**
 * The player to play video.
 */
@property (nonatomic, strong, readonly, nullable) AVPlayer *player;

/**
 * The resourceLoader for the videoPlayer.
 */
@property (nonatomic, strong, readonly, nullable) WJKVideoPlayerResourceLoader *resourceLoader;

/**
 * options
 */
@property (nonatomic, assign, readonly) WJKVideoPlayerOptions playerOptions;

@end

@interface WJKVideoPlayer : NSObject<WJKVideoPlayerPlaybackProtocol>

@property (nonatomic, weak, nullable) id<WJKVideoPlayerInternalDelegate> delegate;

@property (nonatomic, strong, readonly, nullable) WJKVideoPlayerModel *playerModel;

@property (nonatomic, assign, readonly) WJKVideoPlayerStatus playerStatus;

/**
 * Play the existed video file in disk.
 *
 * @param url                     The video url to play.
 * @param fullVideoCachePath      The full video file path in disk.
 * @param showLayer               The layer to show the video display layer.
 * @param configuration           The block will be call when video player config finished. because initialize player is not synchronize,
 *                                 so other category method is disabled before config finished.
 *
 * @return token (@see WJKPlayVideoManagerModel) that can be passed to -stopPlayVideo: to stop play.
 */
- (WJKVideoPlayerModel *_Nullable)playExistedVideoWithURL:(NSURL *)url
                                      fullVideoCachePath:(NSString *)fullVideoCachePath
                                                 options:(WJKVideoPlayerOptions)options
                                             showOnLayer:(CALayer *)showLayer
                                 configurationCompletion:(WJKPlayVideoConfiguration)configurationCompletion;

/**
 * Play the not existed video from web.
 *
 * @param url                     The video url to play.
 * @param options                 The options to use when downloading the video. @see WJKVideoPlayerOptions for the possible values.
 * @param showLayer               The view to show the video display layer.
 * @param configurationCompletion The block will be call when video player config finished. because initialize player is not synchronize,
 *                                 so other category method is disabled before config finished.
 *
 * @return token (@see WJKPlayVideoManagerModel) that can be passed to -stopPlayVideo: to stop play.
 */
- (WJKVideoPlayerModel *_Nullable)playVideoWithURL:(NSURL *)url
                                          options:(WJKVideoPlayerOptions)options
                                        showLayer:(CALayer *)showLayer
                          configurationCompletion:(WJKPlayVideoConfiguration)configurationCompletion;

/**
 * Call this method to resume play.
 *
 * @param showLayer               The view to show the video display layer.
 * @param options                 The options to use when downloading the video. @see WJKVideoPlayerOptions for the possible values.
 * @param configurationCompletion The block will be call when video player config finished. because initialize player is not synchronize,
 *                                 so other category method is disabled before config finished.
 */
- (void)resumePlayWithShowLayer:(CALayer *)showLayer
                        options:(WJKVideoPlayerOptions)options
        configurationCompletion:(WJKPlayVideoConfiguration)configurationCompletion;

/**
 * This method used to seek to record playback when hava record playback history.
 */
- (void)seekToTimeWhenRecordPlayback:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
