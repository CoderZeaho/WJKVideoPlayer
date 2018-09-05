//
//  WJKVideoPlayerControlViews.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/2.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerProtocol.h"

@class WJKVideoPlayerControlProgressView,
       WJKVideoPlayerControlView;

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString *WJKVideoPlayerControlProgressViewUserDidStartDragNotification;
UIKIT_EXTERN NSString *WJKVideoPlayerControlProgressViewUserDidEndDragNotification;
@interface WJKVideoPlayerControlProgressView : UIView<WJKVideoPlayerControlProgressProtocol>

@property (nonatomic, strong, readonly) NSArray<NSValue *> *rangesValue;

@property (nonatomic, assign, readonly) NSUInteger fileLength;

@property (nonatomic, assign, readonly) NSTimeInterval cachedProgress;

@property (nonatomic, assign, readonly) NSTimeInterval totalSeconds;

@property (nonatomic, assign, readonly) NSTimeInterval elapsedSeconds;

@property (nonatomic, weak, readonly, nullable) UIView *playerView;

@property (nonatomic, strong, readonly) UISlider *dragSlider;

@property (nonatomic, strong, readonly) UIView *cachedProgressView;

@property (nonatomic, strong, readonly) UIProgressView *trackProgressView;

@end

@interface WJKVideoPlayerFastForwardView : UIView

@property (nonatomic, strong, readonly) UIImageView *fastForwardImageView;

@property (nonatomic, strong, readonly) UILabel *fastForwardTimeLabel;

@property (nonatomic, strong, readonly) UIProgressView *fastForwardProgressView;

/**
 Pan the screen to control video fast forward

 @param draggedTime draggedTime.
 @param totalTime totalTime.
 @param isFastForward isFastForward.
 */
- (void)draggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isFastForward:(BOOL)isFastForward;

@end

@protocol WJKVideoPlayerControlBarDelegate <NSObject>
@optional

- (void)controlBarPlayButton:(UIButton *)button;
- (void)controlBarLandspaceButton:(UIButton *)button;

@end

@interface WJKVideoPlayerControlBar : UIView<WJKVideoPlayerProtocol>

@property (nonatomic, weak, nullable) id<WJKVideoPlayerControlBarDelegate> delegate;

@property (nonatomic, strong, readonly) UIButton *playButton;

@property (nonatomic, strong, readonly) UIView<WJKVideoPlayerControlProgressProtocol> *progressView;

@property (nonatomic, strong, readonly) UILabel *elapsedSecondsLabel;

@property (nonatomic, strong, readonly) UILabel *totalSecondsLabel;

@property (nonatomic, strong, readonly) UIButton *landscapeButton;

- (instancetype)initWithProgressView:(UIView<WJKVideoPlayerControlProgressProtocol> *_Nullable)progressView NS_DESIGNATED_INITIALIZER;

@end

@interface WJKVideoPlayerControlView : UIView<WJKVideoPlayerProtocol>

@property (nonatomic, weak, readonly, nullable) UIView *playerView;

@property (nonatomic, strong, readonly) UIView<WJKVideoPlayerProtocol> *controlBar;

@property (nonatomic, strong, readonly) WJKVideoPlayerFastForwardView *fastForwardView;

@property (nonatomic, strong, readonly) UIImage *blurImage;

@property (nonatomic, strong, readonly) UIView *userInteractionView;

@property (nonatomic, strong, readonly) UIView *brightnessView;

@property (nonatomic, assign, readonly) NSTimeInterval totalSeconds;

@property (nonatomic, assign, readonly) NSTimeInterval elapsedSeconds;

@property (nonatomic, assign, readonly, getter=isEndPlaying) BOOL endPlaying;

@property (nonatomic, assign, readonly) BOOL needAutoHideControlView;

@property (nonatomic, assign) BOOL cancleTapGesture;

@property (nonatomic, assign) BOOL canclePanGesture;

@property (nonatomic, assign) BOOL cancleGravitySensing;

/**
 * A designated initializer.
 *
 * @param controlBar The view abide by the `WJKVideoPlayerProgressProtocol`.
 * @param blurImage  A image on back of controlBar.
 *
 * @return The current instance.
 */
- (instancetype)initWithControlBar:(UIView<WJKVideoPlayerProtocol> *_Nullable)controlBar
                         blurImage:(UIImage *_Nullable)blurImage
           needAutoHideControlView:(BOOL)needAutoHideControlView NS_DESIGNATED_INITIALIZER;

/**
 Real-time observe playback time.

 @param elapsedSeconds elapsedSeconds,
 @param totalSeconds totalSeconds.
 */
- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds
                               totalSeconds:(NSTimeInterval)totalSeconds;
/**
 Real-time observe player status.

 @param playerStatus playerStatus.
 */
- (void)videoPlayerStatusDidChange:(WJKVideoPlayerStatus)playerStatus;


/**
 Screen rotation through device gravity sensing.

 @param interfaceOrientation interfaceOrientation.
 */
- (void)deviceInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (void)tapGestureDidTap;

- (void)hideControlView;
- (void)showControlView;

@end

UIKIT_EXTERN const CGFloat WJKVideoPlayerProgressViewElementHeight;
@interface WJKVideoPlayerProgressView : UIView<WJKVideoPlayerProtocol>

@property (nonatomic, strong, readonly) NSArray<NSValue *> *rangesValue;

@property (nonatomic, assign, readonly) NSUInteger fileLength;

@property (nonatomic, assign, readonly) NSTimeInterval cachedProgress;

@property (nonatomic, assign, readonly) NSTimeInterval totalSeconds;

@property (nonatomic, assign, readonly) NSTimeInterval elapsedSeconds;

@property (nonatomic, strong, readonly) UIProgressView *trackProgressView;

@property (nonatomic, strong, readonly) UIView *cachedProgressView;

@property (nonatomic, strong, readonly) UIProgressView *elapsedProgressView;

@end

@interface WJKVideoPlayerBufferingIndicator : UIView<WJKVideoPlayerBufferingProtocol>

@property (nonatomic, strong, readonly)UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong, readonly)UIVisualEffectView *blurView;

@property (nonatomic, assign, readonly, getter=isAnimating)BOOL animating;

@end

@interface WJKVideoPlayerView : UIView

/**
 * A placeholderView to custom your own business.
 */
@property (nonatomic, strong, readonly) UIView *placeholderView;

/**
 * A layer to display video layer.
 */
@property (nonatomic, strong, readonly) CALayer *videoContainerLayer;

/**
 * A placeholder view to display controlView.
 */
@property (nonatomic, strong, readonly) UIView *controlContainerView;

/**
 * A placeholder view to display progress view.
 */
@property (nonatomic, strong, readonly) UIView *progressContainerView;

/**
 * A placeholder view to display buffering indicator view.
 */
@property (nonatomic, strong, readonly) UIView *bufferingIndicatorContainerView;

@end

NS_ASSUME_NONNULL_END
