//
//  UIView+WebVideoCache.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerManager.h"
#import "WJKVideoPlayerSupportUtils.h"
#import "WJKVideoPlayerProtocol.h"
#import "WJKVideoPlayerCompat.h"
#import "WJKVideoPlayerControlViews.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WJKVideoPlayerDelegate <NSObject>

@optional
/** 
 * Controls which video should be downloaded when the video is not found in the cache.
 *
 * @param   videoURL the url of the video to be download.
 *
 * @return Return NO to prevent the downloading of the video on cache misses. If not implemented, YES is implied.
 */
- (BOOL)shouldDownloadVideoForURL:(nonnull NSURL *)videoURL;

/**
 * Controls which video should automatic replay when the video is play completed.
 *
 * @param videoURL  the url of the video to be play.
 *
 * @return Return NO to prevent replay for the video. If not implemented, YES is implied.
 */
- (BOOL)shouldAutoReplayForURL:(nonnull NSURL *)videoURL;

/**
 * Controls the background color of the video layer before player really start play video.
 *  by default it is NO, means that the color of the layer is `clearColor`.
 *
 * @return Return YES to make the background color of the video layer be `blackColor`.
 */
- (BOOL)shouldShowBlackBackgroundBeforePlaybackStart;

/**
 * Controls the background color of the video layer when player start play video.
 *  by default it is YES, means that the color of the layer is `blackColor` when start playing.
 *
 * @return Return NO to make the background color of the video layer be `clearColor`.
 */
- (BOOL)shouldShowBlackBackgroundWhenPlaybackStart;

/**
 * Controls the auto hiding of WJKVideoPlayerView`s controlContainerView .
 *  by default it is YES, means that WJKVideoPlayerView`s auto hide controlContainerView after a few seconds and show it
 *  again when user tapping the video playing view.
 *
 * @return Return NO to make the WJKVideoPlayerView`s show controlContainerView all the time.
 *
 * @warning The `userInteractionEnabled` need be set YES;
 */
- (BOOL)shouldAutoHideControlContainerViewWhenUserTapping;

/**
 * Controls the Behavior of adding default ControlView / BufferingIndicator / ProgressView when give nil to params.
 * By default it is YES, which means default views will be added when params given nil.
 *
 * @return Return NO to don`t display any view when params are given nil.
 */
- (BOOL)shouldShowDefaultControlAndIndicatorViews;

/**
 * Notify the player status.
 *
 * @param playerStatus      The current playing status.
 */
- (void)playerStatusDidChanged:(WJKVideoPlayerStatus)playerStatus;

/**
 * Called when application will resign active.
 *
 * @param videoURL The url of the video to be play.
 */
- (BOOL)shouldPausePlaybackWhenApplicationWillResignActiveForURL:(NSURL *)videoURL;

/**
 * Called when application did enter background.
 *
 * @param videoURL The url of the video to be play.
 */
- (BOOL)shouldPausePlaybackWhenApplicationDidEnterBackgroundForURL:(NSURL *)videoURL;

/**
 * Called only when application become active from `Control Center`,
 *  `Notification Center`, `pop UIAlert`, `double click Home-Button`.
 *
 * @param videoURL The url of the video to be play.
 */
- (BOOL)shouldResumePlaybackWhenApplicationDidBecomeActiveFromResignActiveForURL:(NSURL *)videoURL;

/**
 * Called only when application become active from `Share to other application`,
 *  `Enter background`, `Lock screen`.
 *
 * @param videoURL The url of the video to be play.
 */
- (BOOL)shouldResumePlaybackWhenApplicationDidBecomeActiveFromBackgroundForURL:(NSURL *)videoURL;

/**
 * Called when call resume play but can not resume play.
 *
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)shouldTranslateIntoPlayVideoFromResumePlayForURL:(NSURL *)videoURL;

/**
 * Called when receive audio session interruption notification.
 *
 * @param videoURL           The url of the video to be play.
 */
- (BOOL)shouldPausePlaybackWhenReceiveAudioSessionInterruptionNotificationForURL:(NSURL *)videoURL;

/**
 * Called when play video failed.
 *
 * @param error    The reason of why play video failed.
 * @param videoURL The url of the video to be play.
 */
- (void)playVideoFailWithError:(NSError *)error
                      videoURL:(NSURL *)videoURL;
/**
 * Provide custom audio session category to play video, `AVAudioSessionCategoryPlayback` by default.
 *
 * @return The prefer audio session category.
 */
- (NSString *)preferAudioSessionCategory;

/**
 * Called when play a already played video, `NO` by default, return `YES` to enable resume playback from a playback record.
 *
 * @param videoURL       The url of the video to be play.
 * @param elapsedSeconds The elapsed seconds last playback recorded.
 */
- (BOOL)shouldResumePlaybackFromPlaybackRecordForURL:(NSURL *)videoURL
                                      elapsedSeconds:(NSTimeInterval)elapsedSeconds;

@end

@interface UIView (WebVideoCache)<WJKVideoPlayerManagerDelegate>

#pragma mark - Property

@property (nonatomic, nullable) id<WJKVideoPlayerDelegate> wjk_videoPlayerDelegate;

@property (nonatomic, readonly) WJKVideoPlayViewInterfaceOrientation wjk_viewInterfaceOrientation;

@property (nonatomic, readonly) WJKVideoPlayerStatus wjk_playerStatus;

@property(nonatomic, strong, readonly, nullable) WJKVideoPlayerView *wjk_videoPlayerView;

@property (nonatomic, readonly, nullable) UIView<WJKVideoPlayerProtocol> *wjk_progressView;

@property (nonatomic, readonly, nullable) UIView<WJKVideoPlayerProtocol> *wjk_controlView;

@property (nonatomic, readonly, nullable) UIView<WJKVideoPlayerBufferingProtocol> *wjk_bufferingIndicator;

@property(nonatomic, copy, readonly, nullable) NSURL *wjk_videoURL;

#pragma mark - Play Video Methods

/**
 * Play a local or web video for given url with no progressView, no controlView, no bufferingIndicator, and play audio at the same time.
 *
 * The download is asynchronous and cached.
 *
 * @param url The url for the video.
 */
- (void)wjk_playVideoWithURL:(NSURL *)url;

/**
 * Play a local or web video for given url with bufferingIndicator and progressView, and the player is muted.
 *
 * The download is asynchronous and cached.
 *
 * @param url                     The url for the video.
 * @param bufferingIndicator      The view show buffering animation when player buffering, should compliance with the `WJKVideoPlayerBufferingProtocol`,
 *                                 it will display default bufferingIndicator if pass nil in. @see `WJKVideoPlayerBufferingIndicator`.
 * @param progressView            The view to display the download and play progress, should compliance with the `WJKVideoPlayerProgressProtocol`,
 *                                 it will display default progressView if pass nil, @see `WJKVideoPlayerProgressView`.
 * @param configuration           The block will be call when video player complete the configuration. because initialize player is not synchronize,
 *                                 so other category method is disabled before complete the configuration.
 */
- (void)wjk_playVideoMuteWithURL:(NSURL *)url
             bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                   progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
        configuration:(WJKPlayVideoConfiguration _Nullable)configuration;

/**
 * Resume play for given url with bufferingIndicator and progressView, and the player is muted.
 * `Resume` mean that user is playing video in tableView, when user tap the cell of playing video,
 * user open a detail video viewController that play the same video, but we do not wanna user play the same video from the beginning,
 * so we use `resume` method to get this goal.
 *
 * The download is asynchronous and cached.
 *
 * @param url                     The url for the video.
 * @param bufferingIndicator      The view show buffering animation when player buffering, should compliance with the `WJKVideoPlayerBufferingProtocol`,
 *                                 it will display default bufferingIndicator if pass nil in. @see `WJKVideoPlayerBufferingIndicator`.
 * @param progressView            The view to display the download and play progress, should compliance with the `WJKVideoPlayerProgressProtocol`,
 *                                 it will display default progressView if pass nil, @see `WJKVideoPlayerProgressView`.
 * @param configuration           The block will be call when video player complete the configuration. because initialize player is not synchronize,
 *                                 so other category method is disabled before complete the configuration.
 */
- (void)wjk_resumeMutePlayWithURL:(NSURL *)url
              bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                    progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
         configuration:(WJKPlayVideoConfiguration _Nullable)configuration;

/**
 * Play a local or web video for given url with bufferingIndicator, controlView, progressView, and play audio at the same time.
 *
 * The download is asynchronous and cached.
 *
 * The control view will display, and display indicator view when buffer empty.
 *
 * @param url                     The url for the video.
 * @param bufferingIndicator      The view show buffering animation when player buffering, should compliance with the `WJKVideoPlayerBufferingProtocol`,
 *                                 it will display default bufferingIndicator if pass nil in. @see `WJKVideoPlayerBufferingIndicator`.
 * @param controlView             The view to display the download and play progress, should compliance with the `WJKVideoPlayerProgressProtocol`,
 *                                 it will display default controlView if pass nil, @see `WJKVideoPlayerControlView`.
 * @param progressView            The view to display the download and play progress, should compliance with the `WJKVideoPlayerProgressProtocol`,
 *                                 it will display default progressView if pass nil, @see `WJKVideoPlayerProgressView`.
 * @param configuration           The block will be call when video player complete the configuration. because initialize player is not synchronize,
 *                                 so other category method is disabled before complete the configuration.
 */
- (void)wjk_playVideoWithURL:(NSURL *)url
         bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                controlView:(UIView <WJKVideoPlayerProtocol> *_Nullable)controlView
               progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
    configuration:(WJKPlayVideoConfiguration _Nullable)configuration
          needSetControlView:(BOOL)needSetControlView;

/**
 * Resume play for given url with bufferingIndicator, controlView, progressView, and play audio at the same time.
 * `Resume` mean that user is playing video in tableView, when user tap the cell of playing video,
 * user open a detail video viewController that play the same video, but we do not wanna user play the same video from the beginning,
 * so we use `resume` method to get this goal.
 *
 * The download is asynchronous and cached.
 *
 * The control view will display, and display indicator view when buffering empty.
 *
 * @param url                     The url for the video.
 * @param bufferingIndicator      The view show buffering animation when player buffering, should compliance with the `WJKVideoPlayerBufferingProtocol`,
 *                                 it will display default bufferingIndicator if pass nil in. @see `WJKVideoPlayerBufferingIndicator`.
 * @param controlView             The view to display the download and play progress, should compliance with the `WJKVideoPlayerProgressProtocol`,
 *                                 it will display default controlView if pass nil, @see `WJKVideoPlayerControlView`.
 * @param progressView            The view to display the download and play progress, should compliance with the `WJKVideoPlayerProgressProtocol`,
 *                                 it will display default progressView if pass nil, @see `WJKVideoPlayerProgressView`.
 * @param configuration           The block will be call when video player complete the configuration. because initialize player is not synchronize,
 *                                 so other category method is disabled before complete the configuration.
 */
- (void)wjk_resumePlayWithURL:(NSURL *)url
           bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                  controlView:(UIView <WJKVideoPlayerProtocol> *_Nullable)controlView
                 progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
                configuration:(WJKPlayVideoConfiguration _Nullable)configuration
           needSetControlView:(BOOL)needSetControlView;

/**
 * Play a local or web video with given url.
 *
 * The download is asynchronous and cached.
 *
 * @param url                     The url for the video.
 * @param options                 The options to use when downloading the video. @see WJKVideoPlayerOptions for the possible values.
 * @param configuration           The block will be call when video player complete the configuration. because initialize player is not synchronize,
 *                                 so other category method is disabled before complete the configuration.
 */
- (void)wjk_playVideoWithURL:(NSURL *)url
                     options:(WJKVideoPlayerOptions)options
               configuration:(WJKPlayVideoConfiguration _Nullable)configuration;

/**
 * Resume play with given url.
 * `Resume` mean that user is playing video in tableView, when user tap the cell of playing video,
 * user open a detail video viewController that play the same video, but we do not wanna user play the same video from the beginning,
 * so we use `resume` method to get this goal.
 *
 * The download is asynchronous and cached.
 *
 * @param url                     The url for the video.
 * @param options                 The options to use when downloading the video. @see WJKVideoPlayerOptions for the possible values.
 * @param configuration           The block will be call when video player complete the configuration. because initialize player is not synchronize,
 *                                 so other category method is disabled before complete the configuration.
 */
- (void)wjk_resumePlayWithURL:(NSURL *)url
                      options:(WJKVideoPlayerOptions)options
                configuration:(WJKPlayVideoConfiguration _Nullable)configuration;

#pragma mark - Playback Control

/**
 * The current playback rate.
 */
@property (nonatomic) float wjk_rate;

/**
 * A Boolean value that indicates whether the audio output of the player is muted.
 */
@property (nonatomic) BOOL wjk_muted;

/**
 * The audio playback volume for the player, ranging from 0.0 through 1.0 on a linear scale.
 */
@property (nonatomic) float wjk_volume;

/**
* Moves the playback cursor.
*
* @param time The time where seek to.
*/
- (void)wjk_seekToTime:(CMTime)time;

/**
 * Fetch the elapsed seconds of player.
 */
- (NSTimeInterval)wjk_elapsedSeconds;

/**
 * Fetch the total seconds of player.
 */
- (NSTimeInterval)wjk_totalSeconds;

/**
 *  Call this method to pause playback.
 */
- (void)wjk_pause;

/**
 *  Call this method to resume playback.
 */
- (void)wjk_resume;

/**
 * @return Returns the current time of the current player item.
 */
- (CMTime)wjk_currentTime;

/**
 * Call this method to stop play video.
 */
- (void)wjk_stopPlay;

#pragma mark - Landscape Or Portrait Control

/**
 * Call this method to enter full screen.
 */
- (void)wjk_gotoLandscape;

/**
 * Call this method to enter full screen.
 *
 * @param flag       Need landscape animation or not.
 * @param completion Call back when landscape finished.
 */
- (void)wjk_gotoLandscapeAnimated:(BOOL)flag
                      completion:(dispatch_block_t _Nullable)completion;

/**
 * Call this method to exit full screen.
 */
- (void)wjk_gotoPortrait;

/**
 * Call this method to exit full screen.
 *
 * @param flag       Need portrait animation or not.
 * @param completion Call back when portrait finished.
 */
- (void)wjk_gotoPortraitAnimated:(BOOL)flag
                     completion:(dispatch_block_t _Nullable)completion;

//Zaihu 添加缩放方法
/**
 * Call this method to excute scale screen.
 */
- (void)wjk_gotoScale;

/**
 * Call this method to excute scale screen.
 *
 * @param flag       Need portrait animation or not.
 * @param completion Call back when portrait finished.
 */
- (void)wjk_gotoScaleAnimated:(BOOL)flag
                      completion:(dispatch_block_t _Nullable)completion;

/**
 * Call this method to exit scale screen.
 */
- (void)wjk_gooutScale;

/**
 * Call this method to exit scale screen.
 *
 * @param flag       Need portrait animation or not.
 * @param completion Call back when portrait finished.
 */
- (void)wjk_gooutScaleAnimated:(BOOL)flag
                   completion:(dispatch_block_t _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
