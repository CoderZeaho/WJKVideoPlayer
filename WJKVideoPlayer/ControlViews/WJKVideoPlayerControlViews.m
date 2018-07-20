//
//  WJKVideoPlayerControlViews.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/2.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayerControlViews.h"
#import "WJKVideoPlayerCompat.h"
#import "UIView+WebVideoCache.h"
#import <MediaPlayer/MediaPlayer.h>
#import "WJKVideoPlayerBrightnessView.h"

@interface WJKVideoPlayerControlProgressView()

@property (nonatomic, strong) NSArray<NSValue *> *rangesValue;

@property(nonatomic, assign) NSUInteger fileLength;

@property(nonatomic, assign) NSTimeInterval totalSeconds;

@property(nonatomic, assign) NSTimeInterval elapsedSeconds;

@property (nonatomic, strong) UISlider *dragSlider;

@property (nonatomic, strong) UIView *cachedProgressView;

@property (nonatomic, strong) UIProgressView *trackProgressView;

@property (nonatomic, weak) UIView *playerView;

@end

static const CGFloat kWJKVideoPlayerDragSliderLeftEdge = 2;
static const CGFloat kWJKVideoPlayerCachedProgressViewHeight = 2;
NSString *WJKVideoPlayerControlProgressViewUserDidStartDragNotification = @"com.wjkvideoplayer.progressview.user.drag.start.www";
NSString *WJKVideoPlayerControlProgressViewUserDidEndDragNotification = @"com.wjkvideoplayer.progressview.user.drag.end.www";;
@implementation WJKVideoPlayerControlProgressView {
    BOOL _userDragging;
    NSTimeInterval _userDragTimeInterval;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}


#pragma mark - WJKVideoPlayerLayoutProtocol

- (void)layoutThatFits:(CGRect)constrainedRect
nearestViewControllerInViewTree:(UIViewController *_Nullable)nearestViewController
        interfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    CGSize referenceSize = constrainedRect.size;
    self.trackProgressView.frame = CGRectMake(kWJKVideoPlayerDragSliderLeftEdge,
            (referenceSize.height - kWJKVideoPlayerCachedProgressViewHeight) * 0.5,
            referenceSize.width - 2 * kWJKVideoPlayerDragSliderLeftEdge, kWJKVideoPlayerCachedProgressViewHeight);
    self.dragSlider.frame = constrainedRect;
    [self updateCacheProgressViewIfNeed];
    [self playProgressDidChangeElapsedSeconds:self.elapsedSeconds
                                 totalSeconds:self.totalSeconds
                                     videoURL:[NSURL new]];
}


#pragma mark - WJKVideoPlayerProtocol

- (void)viewWillAddToSuperView:(UIView *)view {
    self.playerView = view;
}

- (void)viewWillPrepareToReuse {
    [self cacheRangeDidChange:@[] videoURL:[NSURL new]];
    [self playProgressDidChangeElapsedSeconds:0
                                 totalSeconds:1
                                     videoURL:[NSURL new]];
}

- (void)cacheRangeDidChange:(NSArray<NSValue *> *)cacheRanges
                   videoURL:(NSURL *)videoURL {
    _rangesValue = cacheRanges;
    [self updateCacheProgressViewIfNeed];
}

- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds
                               totalSeconds:(NSTimeInterval)totalSeconds
                                   videoURL:(NSURL *)videoURL {
    if(self.userDragging){
        return;
    }

    if(totalSeconds == 0){
        totalSeconds = 1;
    }

    float delta = elapsedSeconds / totalSeconds;
    NSParameterAssert(delta >= 0);
    NSParameterAssert(delta <= 1);
    delta = MIN(1, delta);
    delta = MAX(0, delta);
    [self.dragSlider setValue:delta animated:YES];
    self.totalSeconds = totalSeconds;
    self.elapsedSeconds = elapsedSeconds;
}

- (void)didFetchVideoFileLength:(NSUInteger)videoLength
                       videoURL:(NSURL *)videoURL {
    self.fileLength = videoLength;
}

- (void)setUserDragging:(BOOL)userDragging {
    [self willChangeValueForKey:@"userDragging"];
    _userDragging = userDragging;
    [self didChangeValueForKey:@"userDragging"];
}

- (BOOL)userDragging {
    return _userDragging;
}

- (void)setUserDragTimeInterval:(NSTimeInterval)userDragTimeInterval {
    [self willChangeValueForKey:@"userDragTimeInterval"];
    _userDragTimeInterval = userDragTimeInterval;
    [self didChangeValueForKey:@"userDragTimeInterval"];
}

- (NSTimeInterval)userDragTimeInterval {
    return _userDragTimeInterval;
}


#pragma mark - Private

- (void)_setup {
    self.trackProgressView = ({
        UIProgressView *view = [UIProgressView new];
        view.trackTintColor = [UIColor colorWithWhite:1 alpha:0.15];
        [self addSubview:view];

        view;
    });

    self.cachedProgressView = ({
        UIView *view = [UIView new];
        [self.trackProgressView addSubview:view];
        view.clipsToBounds = YES;
        view.layer.cornerRadius = 1;
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];

        view;
    });

    self.dragSlider = ({
        UISlider *view = [UISlider new];
        [view setThumbImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_progress_handler_normal"] forState:UIControlStateNormal];
        [view setThumbImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_progress_handler_normal"] forState:UIControlStateHighlighted];
        view.minimumTrackTintColor = [UIColor colorWithRed:220.0 / 255.0 green:105.0 / 255.0 blue:27.0 / 255.0 alpha:1];
        view.maximumTrackTintColor = [UIColor clearColor];
        [view addTarget:self action:@selector(dragSliderDidDrag:) forControlEvents:UIControlEventValueChanged];
        [view addTarget:self action:@selector(dragSliderDidStart:) forControlEvents:UIControlEventTouchDown];
        [view addTarget:self action:@selector(dragSliderDidEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [self addSubview:view];

        view;
    });
}

- (void)dragSliderDidStart:(UISlider *)slider {
    self.userDragging = YES;
    [NSNotificationCenter.defaultCenter postNotificationName:WJKVideoPlayerControlProgressViewUserDidStartDragNotification object:self];
}

- (void)dragSliderDidDrag:(UISlider *)slider {
    self.userDragTimeInterval = slider.value * self.totalSeconds;
}

- (void)dragSliderDidEnd:(UISlider *)slider {
    self.userDragging = NO;
    [self userDidFinishDrag];
    [NSNotificationCenter.defaultCenter postNotificationName:WJKVideoPlayerControlProgressViewUserDidEndDragNotification object:self];
}

- (void)userDidFinishDrag {
    NSParameterAssert(!self.userDragging);
    if(!self.totalSeconds){
        return;
    }
    [self updateCacheProgressViewIfNeed];
    [self.playerView wjk_seekToTime:CMTimeMakeWithSeconds([self fetchElapsedTimeInterval], 1000)];
    [self.playerView wjk_resume];
}

- (void)updateCacheProgressViewIfNeed {
    //Zaihu : 不支持边播边缓存时调用
    [self displayCacheProgressViewIfNeedWhenAutomaticCachingNotSupported];
    //Zaihu : 支持边播边缓存时调用
//    [self displayCacheProgressViewIfNeed];
}

- (void)removeCacheProgressViewIfNeed {
    if(self.cachedProgressView.superview){
        [self.cachedProgressView removeFromSuperview];
    }
}

- (void)displayCacheProgressViewIfNeed {
    if(self.userDragging || !self.rangesValue.count){
        return;
    }

    [self removeCacheProgressViewIfNeed];
    NSRange targetRange = WJKInvalidRange;
    NSUInteger dragStartLocation = [self fetchDragStartLocation];
    if(self.rangesValue.count == 1){
        if(WJKValidFileRange([self.rangesValue.firstObject rangeValue])){
            targetRange = [self.rangesValue.firstObject rangeValue];
        }
    }
    else {
        // find the range that the closest to dragStartLocation.
        for(NSValue *value in self.rangesValue){
            NSRange range = [value rangeValue];
            NSUInteger distance = NSUIntegerMax;
            if(WJKValidFileRange(range)){
                if(NSLocationInRange(dragStartLocation, range)){
                    targetRange = range;
                    break;
                }
                else {
                    int deltaDistance = abs((int)(range.location - dragStartLocation));
                    deltaDistance = abs((int)(NSMaxRange(range) - dragStartLocation)) < deltaDistance ?: deltaDistance;
                    if(deltaDistance < distance){
                        distance = deltaDistance;
                        targetRange = range;
                    }
                }
            }
        }
    }

    if(!WJKValidFileRange(targetRange)){
        return;
    }
    if(self.fileLength == 0){
        return;
    }
    CGFloat cacheProgressViewOriginX = targetRange.location * self.trackProgressView.bounds.size.width / self.fileLength;
    CGFloat cacheProgressViewWidth = targetRange.length * self.trackProgressView.bounds.size.width / self.fileLength;
    self.cachedProgressView.frame = CGRectMake(cacheProgressViewOriginX, 0, cacheProgressViewWidth, self.trackProgressView.bounds.size.height);
    [self.trackProgressView addSubview:self.cachedProgressView];
}

- (void)displayCacheProgressViewIfNeedWhenAutomaticCachingNotSupported {
    if(self.userDragging || !self.rangesValue.count){
        return;
    }
    
    [self removeCacheProgressViewIfNeed];
    
    if (self.totalSeconds == 1) {
        return;
    }
    
    CMTimeRange range = [self.rangesValue.firstObject CMTimeRangeValue];
    
    NSTimeInterval cacheSeconds = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
    
    CGFloat cacheProgress = cacheSeconds / self.totalSeconds;
    
    if(isnan(cacheProgress) || cacheProgress > 1) {
        cacheProgress = 0;
    }
    
    CGFloat cacheProgressViewWidth =  self.trackProgressView.bounds.size.width * cacheProgress;
    self.cachedProgressView.frame = CGRectMake(0, 0, cacheProgressViewWidth, self.trackProgressView.bounds.size.height);
    [self.trackProgressView addSubview:self.cachedProgressView];
}

- (NSUInteger)fetchDragStartLocation {
    return self.fileLength * self.dragSlider.value;
}

- (NSTimeInterval)fetchElapsedTimeInterval {
    return self.dragSlider.value * self.totalSeconds;
}

@end

@interface WJKVideoPlayerFastForwardView ()<WJKVideoPlayerProtocol>

@property (nonatomic, strong) UIImageView *fastForwardImageView;

@property (nonatomic, strong) UILabel *fastForwardTimeLabel;

@property (nonatomic, strong) UIProgressView *fastForwardProgressView;

@end

@implementation WJKVideoPlayerFastForwardView

- (void)dealloc {
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

#pragma mark - WJKVideoPlayerLayoutProtocol

- (void)layoutThatFits:(CGRect)constrainedRect nearestViewControllerInViewTree:(UIViewController * _Nullable)nearestViewController interfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    
    CGSize referenceSize = constrainedRect.size;
    self.fastForwardImageView.frame = CGRectMake((referenceSize.width - 32)/2, 5, 32, 32);
    self.fastForwardTimeLabel.frame = CGRectMake(0, self.fastForwardImageView.frame.origin.y + self.fastForwardImageView.frame.size.height + 2, referenceSize.width, 18);
    self.fastForwardProgressView.frame = CGRectMake(12, self.fastForwardTimeLabel.frame.origin.y + self.fastForwardTimeLabel.frame.size.height + 8, referenceSize.width - 24, 5);
}

- (void)_setup {
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    self.layer.cornerRadius = 4;
    self.layer.masksToBounds = YES;
    
    self.fastForwardImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        [self addSubview:imageView];
        
        imageView;
    });
    
    self.fastForwardTimeLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label = [[UILabel alloc] init];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:label];
        
        label;
    });
    
    self.fastForwardProgressView = ({
        UIProgressView *progressView = [[UIProgressView alloc] init];
        progressView = [[UIProgressView alloc] init];
        progressView.progressTintColor = [UIColor whiteColor];
        progressView.trackTintColor    = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
        [self addSubview:progressView];
        
        progressView;
    });
}

- (void)draggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isFastForward:(BOOL)isFastForward {
    
    NSInteger proMin = draggedTime / 60;
    NSInteger proSec = draggedTime % 60;
    
    NSInteger durMin = totalTime / 60;
    NSInteger durSec = totalTime % 60;
    
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totalTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    CGFloat  draggedValue = (CGFloat)draggedTime/(CGFloat)totalTime;
    NSString *timeStr = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totalTimeStr];
    
    if (isFastForward) {
        self.fastForwardImageView.image = [UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_fast_forward"];
    } else {
        self.fastForwardImageView.image = [UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_fast_backward"];
    }
    self.fastForwardTimeLabel.text = timeStr;
    self.fastForwardProgressView.progress = draggedValue;
}

@end

@interface WJKVideoPlayerControlBar()<WJKVideoPlayerProtocol>

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, strong) UIView<WJKVideoPlayerControlProgressProtocol> *progressView;

@property (nonatomic, strong) UILabel *elapsedSecondsLabel;

@property (nonatomic, strong) UILabel *totalSecondsLabel;

@property (nonatomic, strong) UIButton *landscapeButton;

@property (nonatomic, weak) UIView *playerView;

@property (nonatomic, assign) NSTimeInterval totalSeconds;

@end

static const CGFloat kWJKVideoPlayerControlBarButtonWidthHeight = 22;
static const CGFloat kWJKVideoPlayerControlBarElementGap = 12;
static const CGFloat kWJKVideoPlayerControlBarTimeLabelWidth = 32;
@implementation WJKVideoPlayerControlBar

- (void)dealloc {
    [self.progressView removeObserver:self forKeyPath:@"userDragTimeInterval"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    NSAssert(NO, @"Please use given method to initialize this class.");
    return [self initWithProgressView:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSAssert(NO, @"Please use given method to initialize this class.");
    return [self initWithProgressView:nil];
}

- (instancetype)initWithProgressView:(UIView <WJKVideoPlayerControlProgressProtocol> *_Nullable)progressView {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _progressView = progressView;
        [self _setup];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Please use given method to initialize this class.");
    return [self initWithProgressView:nil];
}


#pragma mark - WJKVideoPlayerLayoutProtocol

- (void)layoutThatFits:(CGRect)constrainedRect
nearestViewControllerInViewTree:(UIViewController *_Nullable)nearestViewController
        interfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    CGSize referenceSize = constrainedRect.size;
    CGFloat elementOriginY = (referenceSize.height - kWJKVideoPlayerControlBarButtonWidthHeight) * 0.5;
    self.playButton.frame = CGRectMake(kWJKVideoPlayerControlBarElementGap,
            elementOriginY,
            kWJKVideoPlayerControlBarButtonWidthHeight,
            kWJKVideoPlayerControlBarButtonWidthHeight);
    self.elapsedSecondsLabel.frame = CGRectMake(self.playButton.frame.origin.x + self.playButton.frame.size.width + 7.5,
                                              elementOriginY,
                                              kWJKVideoPlayerControlBarTimeLabelWidth,
                                              kWJKVideoPlayerControlBarButtonWidthHeight);
    self.landscapeButton.frame = CGRectMake(referenceSize.width - kWJKVideoPlayerControlBarElementGap - kWJKVideoPlayerControlBarButtonWidthHeight,
            elementOriginY,
            kWJKVideoPlayerControlBarButtonWidthHeight,
            kWJKVideoPlayerControlBarButtonWidthHeight);
    self.totalSecondsLabel.frame = CGRectMake(self.landscapeButton.frame.origin.x - kWJKVideoPlayerControlBarTimeLabelWidth - 7.5,
            elementOriginY,
            kWJKVideoPlayerControlBarTimeLabelWidth,
            kWJKVideoPlayerControlBarButtonWidthHeight);
    CGFloat progressViewOriginX = self.elapsedSecondsLabel.frame.origin.x + self.elapsedSecondsLabel.frame.size.width + 11;
    CGFloat progressViewWidth = self.totalSecondsLabel.frame.origin.x - progressViewOriginX - 11;
    self.progressView.frame = CGRectMake(progressViewOriginX,
            elementOriginY,
            progressViewWidth,
            kWJKVideoPlayerControlBarButtonWidthHeight);
    if([self.progressView respondsToSelector:@selector(layoutThatFits:nearestViewControllerInViewTree:interfaceOrientation:)]){
        [self.progressView layoutThatFits:self.progressView.bounds
        nearestViewControllerInViewTree:nearestViewController
                   interfaceOrientation:interfaceOrientation];
    }
}


#pragma mark - WJKVideoPlayerProtocol

- (void)viewWillAddToSuperView:(UIView *)view {
    self.playerView = view;
    [self updateTimeLabelWithElapsedSeconds:0 totalSeconds:0];
    [self.progressView viewWillAddToSuperView:view];
}

- (void)viewWillPrepareToReuse {
    [self updateTimeLabelWithElapsedSeconds:0 totalSeconds:0];
    [self.progressView viewWillPrepareToReuse];
}

- (void)cacheRangeDidChange:(NSArray<NSValue *> *)cacheRanges
                   videoURL:(NSURL *)videoURL {
    [self.progressView cacheRangeDidChange:cacheRanges
                                  videoURL:videoURL];
}

- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds
                               totalSeconds:(NSTimeInterval)totalSeconds
                                   videoURL:(NSURL *)videoURL {
    self.totalSeconds = totalSeconds;
    if(!self.progressView.userDragging){
        [self updateTimeLabelWithElapsedSeconds:elapsedSeconds totalSeconds:totalSeconds];
    }
    [self.progressView playProgressDidChangeElapsedSeconds:elapsedSeconds
                                              totalSeconds:totalSeconds
                                                  videoURL:videoURL];
}

- (void)didFetchVideoFileLength:(NSUInteger)videoLength
                       videoURL:(NSURL *)videoURL {
    [self.progressView didFetchVideoFileLength:videoLength
                                      videoURL:videoURL];
}

- (void)videoPlayerStatusDidChange:(WJKVideoPlayerStatus)playerStatus
                          videoURL:(NSURL *)videoURL {
    BOOL isPlaying = playerStatus == WJKVideoPlayerStatusBuffering || playerStatus == WJKVideoPlayerStatusPlaying;
    self.playButton.selected = !isPlaying;
    
}

- (void)videoPlayerInterfaceOrientationDidChange:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation
                                        videoURL:(NSURL *)videoURL {
    self.landscapeButton.selected = interfaceOrientation == WJKVideoPlayViewInterfaceOrientationLandscape;
}


#pragma mark - Private

- (void)updateTimeLabelWithElapsedSeconds:(NSTimeInterval)elapsedSeconds
                             totalSeconds:(NSTimeInterval)totalSeconds {
    NSString *elapsedString = [self convertSecondsToTimeString:elapsedSeconds];
    NSString *totalString = [self convertSecondsToTimeString:totalSeconds];
    self.elapsedSecondsLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", elapsedString]
                                                                            attributes:@{
                                                                                         NSFontAttributeName : [UIFont systemFontOfSize:10],
                                                                                         NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                                         }];
    self.totalSecondsLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", totalString]
                                                                    attributes:@{
                                                                            NSFontAttributeName : [UIFont systemFontOfSize:10],
                                                                            NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                    }];
}

- (NSString *)convertSecondsToTimeString:(NSTimeInterval)seconds {
    NSUInteger minute = (NSUInteger)(seconds / 60);
    NSUInteger second = (NSUInteger)((NSUInteger)seconds % 60);
    return [NSString stringWithFormat:@"%02d:%02d", (int)minute, (int)second];
}

- (void)playButtonDidClick:(UIButton *)button {
    button.selected = !button.selected;
    BOOL isPlay = self.playerView.wjk_playerStatus == WJKVideoPlayerStatusBuffering ||
            self.playerView.wjk_playerStatus == WJKVideoPlayerStatusPlaying;
    isPlay ? [self.playerView wjk_pause] : [self.playerView wjk_resume];
}

//Zaihu 全屏按钮导致全屏会调用这里
- (void)landscapeButtonDidClick:(UIButton *)button {
    button.selected = !button.selected;
    if ([[self delegate] respondsToSelector:@selector(controlBarLandspaceButton:)]) {
        [[self delegate] controlBarLandspaceButton:button];
    }
    if (self.playerView.wjk_viewInterfaceOrientation == WJKVideoPlayViewInterfaceOrientationPortrait) {
        [self.playerView wjk_gotoLandscape];
    } else {
        [self.playerView wjk_gotoPortrait];
    }
}

- (void)_setup {
    self.backgroundColor = [UIColor clearColor];

    self.playButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_pause"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_play"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(playButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        button;
    });

    if(!self.progressView){
        self.progressView = ({
            WJKVideoPlayerControlProgressView *view = [WJKVideoPlayerControlProgressView new];
            [view addObserver:self forKeyPath:@"userDragTimeInterval" options:NSKeyValueObservingOptionNew context:nil];
            [self addSubview:view];

            view;
        });
    }

    self.elapsedSecondsLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        label;
    });
    
    self.totalSecondsLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];

        label;
    });

    self.landscapeButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_landscape"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_portrait"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(landscapeButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        button;
    });
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(nullable void *)context {
    if([keyPath isEqualToString:@"userDragTimeInterval"]) {
        NSNumber *timeIntervalNumber = change[NSKeyValueChangeNewKey];
        NSTimeInterval timeInterval = timeIntervalNumber.floatValue;
        [self updateTimeLabelWithElapsedSeconds:timeInterval totalSeconds:self.totalSeconds];
    }
}

@end

@interface WJKVideoPlayerControlView()<WJKVideoPlayerProtocol, WJKVideoPlayerControlBarDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *playerView;

@property (nonatomic, strong) UIView<WJKVideoPlayerProtocol> *controlBar;

@property (nonatomic, strong) UIImageView *blurImageView;

//Zaihu
@property (nonatomic, strong) UIView *userInteractionView;

@property (nonatomic, strong) UIView *brightnessView;

@property (nonatomic, assign) NSTimeInterval totalSeconds;

@property (nonatomic, assign) NSTimeInterval elapsedSeconds;

@property (nonatomic, assign, getter=isEndPlaying) BOOL endPlaying;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) BOOL isInterruptTimer;

/* 平移手势 : 控制音量/亮度/快进/快退 **/
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
/* 轻拍手势 : 控制控制层显示隐藏 **/
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

/* 平移方向 : 水平/垂直 **/
@property (nonatomic, assign) WJKControlViewPanDirection panDirection;

/* 音量 */
@property (nonatomic, strong) UISlider *volumeViewSlider;

/* 是否在调节音量 */
@property (nonatomic, assign) BOOL isVolume;

/* 快进退 **/
@property (nonatomic, strong) WJKVideoPlayerFastForwardView *fastForwardView;

/* 快进退时间 */
@property (nonatomic, assign) CGFloat seekTime;

@end

static const NSTimeInterval kWJKControlViewAutoHiddenTimeInterval = 5;
static const CGFloat kWJKVideoPlayerControlBarHeight = 38;
static const CGFloat kWJKVideoPlayerControlBarLandscapeUpOffset = 18;
static const CGFloat kWJKVideoPlayerFastForwardHeight = 80;
static const CGFloat kWJKVideoPlayerFastForwardWidth = 125;
@implementation WJKVideoPlayerControlView

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (instancetype)initWithFrame:(CGRect)frame {
    NSAssert(NO, @"Please use given method to initialize this class.");
    return [self initWithControlBar:nil blurImage:nil needAutoHideControlView:YES];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSAssert(NO, @"Please use given method to initialize this class.");
    return [self initWithControlBar:nil blurImage:nil needAutoHideControlView:YES];
}

- (instancetype)initWithControlBar:(UIView <WJKVideoPlayerProtocol> *)controlBar
                         blurImage:(UIImage *)blurImage
           needAutoHideControlView:(BOOL)needAutoHideControlView {
    self = [super initWithFrame:CGRectZero];
    if(self){
        _needAutoHideControlView = needAutoHideControlView;
        _controlBar = controlBar;
        _blurImage = blurImage;
        [self _setup];
        [self _addNotifications];
        [self _configureVolume];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Please use given method to initialize this class.");
    return [self initWithControlBar:nil blurImage:nil needAutoHideControlView:YES];
}

- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds totalSeconds:(NSTimeInterval)totalSeconds {
}

- (void)videoPlayerStatusDidChange:(WJKVideoPlayerStatus)playerStatus {
}

- (void)deviceInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
}

- (void)hideControlView {
    self.controlBar.alpha =
    self.blurImageView.alpha = 0;

    [self endTimer];
}

- (void)showControlView {
    self.controlBar.alpha =
    self.blurImageView.alpha = 1;
    
    [self startTimer];
}

- (void)tapGestureDidTap {
    [UIView animateWithDuration:0.35
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                             if(self.controlBar.alpha == 0){
                                 
                                 [self showControlView];
                             } else {
                                 
                                 [self hideControlView];
                             }
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)panGestureDidPan:(UIPanGestureRecognizer *)gesture {
    CGPoint locationPoint = [gesture locationInView:self];
    CGPoint veloctyPoint = [gesture velocityInView:self];

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) {
                self.panDirection = WJKControlViewPanDirectionHorizontalMoved;
                self.seekTime = self.elapsedSeconds;
                NSLog(@"快进/快退到:%.2f", self.seekTime);
            } else if (x < y) {
                self.panDirection = WJKControlViewPanDirectionVerticalMoved;
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else {
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            switch (self.panDirection) {
                case WJKControlViewPanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x];
                    break;
                }
                case WJKControlViewPanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            switch (self.panDirection) {
                case WJKControlViewPanDirectionHorizontalMoved:{
                    [self.playerView wjk_resume];
                    self.fastForwardView.hidden = YES;
                    self.seekTime = 0;
                    break;
                }
                case WJKControlViewPanDirectionVerticalMoved:{
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void)verticalMoved:(CGFloat)value {
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

- (void)horizontalMoved:(CGFloat)value {
    
    self.seekTime += value / 200;
    
    CGFloat totalTime = self.totalSeconds;
    if (self.seekTime > totalTime) { self.seekTime = totalTime;}
    if (self.seekTime < 0) { self.seekTime = 0; }
    
    BOOL style = false;
    if (value > 0) { style = YES; }
    if (value < 0) { style = NO; }
    if (value == 0) { return; }
    
    [self.playerView wjk_seekToTime:CMTimeMakeWithSeconds(self.seekTime, 1000)];
    self.fastForwardView.hidden = NO;
    [[self fastForwardView] draggedTime:self.seekTime totalTime:totalTime isFastForward:style];
}

#pragma mark - WJKVideoPlayerLayoutProtocol

- (void)layoutThatFits:(CGRect)constrainedRect
nearestViewControllerInViewTree:(UIViewController *_Nullable)nearestViewController
        interfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    self.userInteractionView.frame = constrainedRect;
    self.blurImageView.frame = constrainedRect;
    CGRect controlBarFrame = CGRectMake(0,
            constrainedRect.size.height - kWJKVideoPlayerControlBarHeight,
            constrainedRect.size.width,
            kWJKVideoPlayerControlBarHeight);
    if(interfaceOrientation == WJKVideoPlayViewInterfaceOrientationLandscape){ // landscape.
        CGFloat controlBarOriginX = 0;
        if (@available(iOS 11.0, *)) {
            UIEdgeInsets insets = self.window.safeAreaInsets;
            controlBarOriginX = insets.bottom;
        }
        controlBarFrame = CGRectMake(controlBarOriginX,
                                     constrainedRect.size.height - kWJKVideoPlayerControlBarHeight - kWJKVideoPlayerControlBarLandscapeUpOffset,
                constrainedRect.size.width - 2 * controlBarOriginX,
                kWJKVideoPlayerControlBarHeight);
    }
    CGRect fastFordViewFrame = CGRectMake((constrainedRect.size.width - kWJKVideoPlayerFastForwardWidth) * 0.5, (constrainedRect.size.height - kWJKVideoPlayerFastForwardHeight) * 0.5, kWJKVideoPlayerFastForwardWidth, kWJKVideoPlayerFastForwardHeight);
    self.controlBar.frame = controlBarFrame;
    self.fastForwardView.frame = fastFordViewFrame;
    if([self.controlBar respondsToSelector:@selector(layoutThatFits:nearestViewControllerInViewTree:interfaceOrientation:)]){
       [self.controlBar layoutThatFits:self.controlBar.bounds
       nearestViewControllerInViewTree:nearestViewController
                  interfaceOrientation:interfaceOrientation];
    }
    if([self.fastForwardView respondsToSelector:@selector(layoutThatFits:nearestViewControllerInViewTree:interfaceOrientation:)]){
        [self.fastForwardView layoutThatFits:self.fastForwardView.bounds
        nearestViewControllerInViewTree:nearestViewController
                   interfaceOrientation:interfaceOrientation];
    }
}

#pragma mark - WJKVideoPlayerProtocol

- (void)viewWillAddToSuperView:(UIView *)view {
    self.playerView = view;
    [self.controlBar viewWillAddToSuperView:view];
}

- (void)viewWillPrepareToReuse {
    [self.controlBar viewWillPrepareToReuse];
}

- (void)cacheRangeDidChange:(NSArray<NSValue *> *)cacheRanges
                   videoURL:(NSURL *)videoURL {
    [self.controlBar cacheRangeDidChange:cacheRanges
                                videoURL:videoURL];
}

- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds
                               totalSeconds:(NSTimeInterval)totalSeconds
                                   videoURL:(NSURL *)videoURL {
    [self.controlBar playProgressDidChangeElapsedSeconds:elapsedSeconds
                                            totalSeconds:totalSeconds
                                                videoURL:videoURL];
    
    self.totalSeconds = totalSeconds;
    self.elapsedSeconds = elapsedSeconds;
    
    [self playProgressDidChangeElapsedSeconds:elapsedSeconds totalSeconds:totalSeconds];
    
    self.endPlaying = self.elapsedSeconds == self.totalSeconds ? YES : NO;
}

- (void)didFetchVideoFileLength:(NSUInteger)videoLength
                       videoURL:(NSURL *)videoURL {
    [self.controlBar didFetchVideoFileLength:videoLength
                                    videoURL:videoURL];
}

- (void)videoPlayerStatusDidChange:(WJKVideoPlayerStatus)playerStatus
                          videoURL:(NSURL *)videoURL {
    [self.controlBar videoPlayerStatusDidChange:playerStatus
                                       videoURL:videoURL];
    [self videoPlayerStatusDidChange:playerStatus];
}

- (void)videoPlayerInterfaceOrientationDidChange:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation
                                        videoURL:(NSURL *)videoURL {
    [self.controlBar videoPlayerInterfaceOrientationDidChange:interfaceOrientation
                                                     videoURL:videoURL];
}

#pragma mark - Private

- (void)_setup {
    
    //Zaihu
    self.userInteractionView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];

        view;
    });
    
    self.blurImageView = ({
        UIImageView *view = [UIImageView new];
        UIImage *blurImage = self.blurImage;
        if(!blurImage){
            blurImage = [UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_blur"];
        }
        view.image = blurImage;
        view.userInteractionEnabled = NO;
        [self addSubview:view];

        view;
    });

    if(!self.controlBar){
        self.controlBar = ({
            WJKVideoPlayerControlBar *bar = [[WJKVideoPlayerControlBar alloc] initWithProgressView:nil];
            bar.delegate = self;
            [self addSubview:bar];

            bar;
        });
    }
    
    if (!self.fastForwardView) {
        self.fastForwardView = ({
            WJKVideoPlayerFastForwardView *forward = [[WJKVideoPlayerFastForwardView alloc] init];
            forward.hidden = YES;
            [self addSubview:forward];
            
            forward;
        });
    }
    
    if(!self.brightnessView){
        self.brightnessView = ({
            WJKVideoPlayerBrightnessView *brightness = [WJKVideoPlayerBrightnessView sharedBrightnessView];
            
            brightness;
        });
    }
    
    if (self.needAutoHideControlView) {
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDidTap)];
        self.tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:[self tapGestureRecognizer]];
        [self startTimer];
    }
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureDidPan:)];
    self.panGestureRecognizer.delegate = self;
    [self.panGestureRecognizer setMaximumNumberOfTouches:1];
    [self.panGestureRecognizer setDelaysTouchesBegan:YES];
    [self.panGestureRecognizer setDelaysTouchesEnded:YES];
    [self.panGestureRecognizer setCancelsTouchesInView:YES];
    [self addGestureRecognizer:self.panGestureRecognizer];
}

//Zaihu 添加观察者、通知
- (void)_addNotifications {
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveUserStartDragNotification)
                                               name:WJKVideoPlayerControlProgressViewUserDidStartDragNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveUserEndDragNotification)
                                               name:WJKVideoPlayerControlProgressViewUserDidEndDragNotification
                                             object:nil];
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
}

- (void)_configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
}

- (void)didReceiveUserStartDragNotification {
    if(self.timer){
        self.isInterruptTimer = YES;
        [self endTimer];
    }
}

- (void)didReceiveUserEndDragNotification {
    if(self.isInterruptTimer){
        [self startTimer];
    }
}

//Zaihu 重力感应导致全屏会调用这里
- (void)onDeviceOrientationChange {
    if (self.cancleGravitySensing == YES) {
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    [self deviceInterfaceOrientation:interfaceOrientation];
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown: {
            WJKVideoPlayerControlBar *controlBar = (WJKVideoPlayerControlBar *)self.controlBar;
            controlBar.landscapeButton.selected = YES;
        }
            break;
        case UIInterfaceOrientationPortrait: {
            WJKVideoPlayerControlBar *controlBar = (WJKVideoPlayerControlBar *)self.controlBar;
            controlBar.landscapeButton.selected = NO;
            [[self playerView] wjk_gotoPortrait];
            
            [[self brightnessView] removeFromSuperview];
            [[UIApplication sharedApplication].keyWindow addSubview:[self brightnessView]];
            [[self brightnessView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(155);
                make.leading.mas_equalTo((SCREENWIDTH-155)/2);
                make.top.mas_equalTo((SCREENHEIGHT-155)/2);
            }];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
        case UIInterfaceOrientationLandscapeRight: {
            WJKVideoPlayerControlBar *controlBar = (WJKVideoPlayerControlBar *)self.controlBar;
            controlBar.landscapeButton.selected = YES;
            [[self playerView] wjk_gotoLandscape];
            [[self brightnessView] removeFromSuperview];
            [self addSubview:[self brightnessView]];
            [[self brightnessView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.mas_equalTo(self);
                make.width.height.mas_equalTo(155);
            }];
        }
            break;
        default:
            break;
        }
    }
}

- (void)startTimer {
    if(!self.timer){
        self.timer = [NSTimer timerWithTimeInterval:kWJKControlViewAutoHiddenTimeInterval
                                             target:self
                                           selector:@selector(timeDidChange:)
                                           userInfo:nil
                                            repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    
}

- (void)endTimer {
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)timeDidChange:(NSTimer *)timer {
    [self tapGestureDidTap];
    [self endTimer];
}

#pragma mark - accessor

- (void)setCancleTapGesture:(BOOL)cancleTapGesture {
    _cancleTapGesture = cancleTapGesture;
    
    if (cancleTapGesture == YES) {
        [self endTimer];
        [self removeGestureRecognizer:self.tapGestureRecognizer];
    } else {
        [self startTimer];
        [self addGestureRecognizer:self.tapGestureRecognizer];
    }
}

- (void)setCanclePanGesture:(BOOL)canclePanGesture {
    _canclePanGesture = canclePanGesture;
    
    if (canclePanGesture == YES) {
        [self removeGestureRecognizer:self.panGestureRecognizer];
    } else {
        [self addGestureRecognizer:self.panGestureRecognizer];
    }
}

- (void)setCancleGravitySensing:(BOOL)cancleGravitySensing {
    _cancleGravitySensing = cancleGravitySensing;
    
    if (_cancleGravitySensing == YES) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    } else {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isDescendantOfView:[self controlBar]]) {
        return NO;
    }
    return YES;
}


@end

@interface WJKVideoPlayerProgressView()

@property (nonatomic, strong) UIProgressView *trackProgressView;

@property (nonatomic, strong) UIView *cachedProgressView;

@property (nonatomic, strong) UIProgressView *elapsedProgressView;

@property (nonatomic, strong) NSArray<NSValue *> *rangesValue;

@property(nonatomic, assign) NSUInteger fileLength;

@property(nonatomic, assign) NSTimeInterval totalSeconds;

@property(nonatomic, assign) NSTimeInterval elapsedSeconds;

@end

const CGFloat WJKVideoPlayerProgressViewElementHeight = 2;
@implementation WJKVideoPlayerProgressView

- (instancetype)init {
    self = [super init];
    if(self){
        [self _setup];
    }
    return self;
}


#pragma mark - Setup

- (void)_setup {
    self.trackProgressView = ({
        UIProgressView *view = [UIProgressView new];
        view.trackTintColor = [UIColor colorWithWhite:1 alpha:0.15];
        [self addSubview:view];

        view;
    });

    self.cachedProgressView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
        [self.trackProgressView addSubview:view];

        view;
    });

    self.elapsedProgressView = ({
        UIProgressView *view = [UIProgressView new];
        view.progressTintColor = [UIColor colorWithRed:220.0 / 255.0 green:105.0 / 255.0 blue:27.0 / 255.0 alpha:1];
        view.trackTintColor = [UIColor clearColor];
        [self addSubview:view];

        view;
    });
}


#pragma mark - WJKVideoPlayerLayoutProtocol

- (void)layoutThatFits:(CGRect)constrainedRect
nearestViewControllerInViewTree:(UIViewController *_Nullable)nearestViewController
        interfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    self.trackProgressView.frame = CGRectMake(0,
            constrainedRect.size.height - WJKVideoPlayerProgressViewElementHeight,
            constrainedRect.size.width,
            WJKVideoPlayerProgressViewElementHeight);
    self.cachedProgressView.frame = self.trackProgressView.bounds;
    self.elapsedProgressView.frame = self.trackProgressView.frame;
}

#pragma mark - WJKVideoPlayerProtocol

- (void)viewWillAddToSuperView:(UIView *)view {
}

- (void)viewWillPrepareToReuse {
    [self cacheRangeDidChange:@[] videoURL:[NSURL new]];
    [self playProgressDidChangeElapsedSeconds:0
                                 totalSeconds:0
                                     videoURL:[NSURL new]];
}

- (void)cacheRangeDidChange:(NSArray<NSValue *> *)cacheRanges
                   videoURL:(NSURL *)videoURL {
    _rangesValue = cacheRanges;
    //Zaihu : 不支持边播边缓存时调用
    [self displayCacheProgressViewIfNeedWhenAutomaticCachingNotSupported];
    //Zaihu : 支持边播边缓存时调用
//    [self displayCacheProgressViewIfNeed];
}

- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds
                               totalSeconds:(NSTimeInterval)totalSeconds
                                   videoURL:(NSURL *)videoURL {
    if(totalSeconds == 0){
        totalSeconds = 1;
    }

    float delta = elapsedSeconds / totalSeconds;
    NSParameterAssert(delta >= 0);
    NSParameterAssert(delta <= 1);
    delta = MIN(1, delta);
    delta = MAX(0, delta);
    [self.elapsedProgressView setProgress:delta animated:YES];
    self.totalSeconds = totalSeconds;
    self.elapsedSeconds = elapsedSeconds;
}

- (void)didFetchVideoFileLength:(NSUInteger)videoLength
                       videoURL:(NSURL *)videoURL {
    self.fileLength = videoLength;
}

- (void)displayCacheProgressViewIfNeed {
    if(!self.rangesValue.count){
        return;
    }

    [self removeCacheProgressViewIfNeed];
    NSRange targetRange = WJKInvalidRange;
    NSUInteger dragStartLocation = [self fetchDragStartLocation];
    if(self.rangesValue.count == 1){
        if(WJKValidFileRange([self.rangesValue.firstObject rangeValue])){
            targetRange = [self.rangesValue.firstObject rangeValue];
        }
    }
    else {
        // find the range that the closest to dragStartLocation.
        for(NSValue *value in self.rangesValue){
            NSRange range = [value rangeValue];
            NSUInteger distance = NSUIntegerMax;
            if(WJKValidFileRange(range)){
                if(NSLocationInRange(dragStartLocation, range)){
                    targetRange = range;
                    break;
                }
                else {
                    int deltaDistance = abs((int)(range.location - dragStartLocation));
                    deltaDistance = abs((int)(NSMaxRange(range) - dragStartLocation)) < deltaDistance ?: deltaDistance;
                    if(deltaDistance < distance){
                        distance = deltaDistance;
                        targetRange = range;
                    }
                }
            }
        }
    }

    if(!WJKValidFileRange(targetRange)){
        return;
    }
    if(self.fileLength == 0){
        return;
    }
    CGFloat cacheProgressViewOriginX = targetRange.location * self.trackProgressView.bounds.size.width / self.fileLength;
    CGFloat cacheProgressViewWidth = targetRange.length * self.trackProgressView.bounds.size.width / self.fileLength;
    self.cachedProgressView.frame = CGRectMake(cacheProgressViewOriginX, 0, cacheProgressViewWidth, self.trackProgressView.bounds.size.height);
    [self.trackProgressView addSubview:self.cachedProgressView];
}

- (void)displayCacheProgressViewIfNeedWhenAutomaticCachingNotSupported {
    if(!self.rangesValue.count){
        return;
    }
    
    [self removeCacheProgressViewIfNeed];
    
    CMTimeRange range = [self.rangesValue.firstObject CMTimeRangeValue];
    
    NSTimeInterval cacheSeconds = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
    
    CGFloat cacheProgress = cacheSeconds / self.totalSeconds;
    
    if(isnan(cacheProgress) || cacheProgress > 1) {
        cacheProgress = 0;
    }
    
    CGFloat cacheProgressViewWidth =  self.trackProgressView.bounds.size.width * cacheProgress;
    self.cachedProgressView.frame = CGRectMake(0, 0, cacheProgressViewWidth, self.trackProgressView.bounds.size.height);
    [self.trackProgressView addSubview:self.cachedProgressView];
}

- (void)removeCacheProgressViewIfNeed {
    if(self.cachedProgressView.superview){
        [self.cachedProgressView removeFromSuperview];
    }
}

- (NSUInteger)fetchDragStartLocation {
    return self.fileLength * self.elapsedProgressView.progress;
}

@end

@interface WJKVideoPlayerBufferingIndicator()

@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;

@property(nonatomic, strong)UIVisualEffectView *blurView;

@property(nonatomic, assign, getter=isAnimating)BOOL animating;

@property (nonatomic, strong) UIView *blurBackgroundView;

@end

CGFloat const WJKVideoPlayerBufferingIndicatorWidthHeight = 46;
@implementation WJKVideoPlayerBufferingIndicator

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}


#pragma mark - WJKVideoPlayerLayoutProtocol

- (void)layoutThatFits:(CGRect)constrainedRect
nearestViewControllerInViewTree:(UIViewController *_Nullable)nearestViewController
  interfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    CGSize referenceSize = constrainedRect.size;
    self.blurBackgroundView.frame = CGRectMake((referenceSize.width - WJKVideoPlayerBufferingIndicatorWidthHeight) * 0.5,
            (referenceSize.height - WJKVideoPlayerBufferingIndicatorWidthHeight) * 0.5,
            WJKVideoPlayerBufferingIndicatorWidthHeight,
            WJKVideoPlayerBufferingIndicatorWidthHeight);
    self.activityIndicator.frame = self.blurBackgroundView.bounds;
    self.blurView.frame = self.blurBackgroundView.bounds;
}


- (void)startAnimating{
    if (!self.isAnimating) {
        self.hidden = NO;
        [self.activityIndicator startAnimating];
        self.animating = YES;
    }
}

- (void)stopAnimating{
    if (self.isAnimating) {
        self.hidden = YES;
        [self.activityIndicator stopAnimating];
        self.animating = NO;
    }
}


#pragma mark - WJKVideoPlayerBufferingProtocol

- (void)didStartBufferingVideoURL:(NSURL *)videoURL {
    [self startAnimating];
}

- (void)didFinishBufferingVideoURL:(NSURL *)videoURL {
    [self stopAnimating];
}


#pragma mark - Private

- (void)_setup{
    self.backgroundColor = [UIColor clearColor];

    self.blurBackgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.layer.cornerRadius = 10;
        view.clipsToBounds = YES;
        [self addSubview:view];

        view;
    });

//    self.blurView = ({
//        UIVisualEffectView *blurView = [[UIVisualEffectView alloc]initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
//        [self.blurBackgroundView addSubview:blurView];
//
//        blurView;
//    });

    self.activityIndicator = ({
        UIActivityIndicatorView *indicator = [UIActivityIndicatorView new];
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        indicator.color = [UIColor whiteColor];
        [self.blurBackgroundView addSubview:indicator];

        indicator;
    });

    self.animating = NO;
}

@end

@interface WJKVideoPlayerView()

@property (nonatomic, strong) UIView *placeholderView;

@property (nonatomic, strong) UIView *videoContainerView;

@property (nonatomic, strong) UIView *controlContainerView;

@property (nonatomic, strong) UIView *progressContainerView;

@property (nonatomic, strong) UIView *bufferingIndicatorContainerView;

@end

@implementation WJKVideoPlayerView

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if(self){
        [self _setup];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.placeholderView.frame = self.bounds;
    self.videoContainerView.frame = self.bounds;
    self.controlContainerView.frame = self.bounds;
    self.progressContainerView.frame = self.bounds;
    self.bufferingIndicatorContainerView.frame = self.bounds;
    [self layoutContainerSubviewsWithBounds:CGRectZero center:CGPointZero  frame:frame];
    [self callLayoutMethodForContainerSubviews];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.videoContainerView.frame = CGRectMake(0,
            0,
            bounds.size.width,
            bounds.size.height);
    self.placeholderView.frame = self.videoContainerView.frame;
    self.controlContainerView.frame = self.videoContainerView.frame;
    self.progressContainerView.frame = self.videoContainerView.frame;
    self.bufferingIndicatorContainerView.frame = self.videoContainerView.frame;
    [self layoutContainerSubviewsWithBounds:bounds center:CGPointZero frame:CGRectZero];
    [self callLayoutMethodForContainerSubviews];
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    self.videoContainerView.frame = CGRectMake(0,
            0,
            self.videoContainerView.bounds.size.width,
            self.videoContainerView.bounds.size.height);
    self.placeholderView.frame = self.videoContainerView.frame;
    self.controlContainerView.frame = self.videoContainerView.frame;
    self.progressContainerView.frame = self.videoContainerView.frame;
    self.bufferingIndicatorContainerView.frame = self.videoContainerView.frame;
    [self layoutContainerSubviewsWithBounds:CGRectZero center:center frame:CGRectZero];
    [self callLayoutMethodForContainerSubviews];
}

- (CALayer *)videoContainerLayer {
    return self.videoContainerView.layer;
}

- (void)layoutContainerSubviewsWithBounds:(CGRect)bounds center:(CGPoint)center frame:(CGRect)frame {
    for(UIView *view in self.controlContainerView.subviews){
        if(!CGRectIsEmpty(frame)){
           view.frame = frame;
        }
        else {
            if(CGRectIsEmpty(bounds)){
                bounds = view.bounds;
            }
            if(CGPointEqualToPoint(center, CGPointZero)){
                center = view.center;
            }
            view.frame = CGRectMake(0,
                    0,
                    bounds.size.width,
                    bounds.size.height);
        }
    }
    for(UIView *view in self.progressContainerView.subviews){
        if(!CGRectIsEmpty(frame)){
            view.frame = frame;
        }
        else {
            if(CGRectIsEmpty(bounds)){
                bounds = view.bounds;
            }
            if(CGPointEqualToPoint(center, CGPointZero)){
                center = view.center;
            }
            view.frame = CGRectMake(0,
                    0,
                    bounds.size.width,
                    bounds.size.height);
        }
    }
    for(UIView *view in self.bufferingIndicatorContainerView.subviews){
        if(!CGRectIsEmpty(frame)){
            view.frame = frame;
        }
        else {
            if(CGRectIsEmpty(bounds)){
                bounds = view.bounds;
            }
            if(CGPointEqualToPoint(center, CGPointZero)){
                center = view.center;
            }
            view.frame = CGRectMake(0,
                    0,
                    bounds.size.width,
                    bounds.size.height);
        }
    }
}

- (void)callLayoutMethodForContainerSubviews {
    UIViewController *nearestViewController = [self findNearestViewControllerForView:self.superview];
    for(UIView<WJKVideoPlayerProtocol> *view in self.controlContainerView.subviews){
        if([view respondsToSelector:@selector(layoutThatFits:nearestViewControllerInViewTree:interfaceOrientation:)]){
            [view layoutThatFits:self.bounds
 nearestViewControllerInViewTree:nearestViewController
            interfaceOrientation:[self fetchCurrentInterfaceOrientation]];
        }
    }
    for(UIView<WJKVideoPlayerProtocol> *view in self.progressContainerView.subviews){
        if([view respondsToSelector:@selector(layoutThatFits:nearestViewControllerInViewTree:interfaceOrientation:)]){
            [view layoutThatFits:self.bounds
 nearestViewControllerInViewTree:nearestViewController
            interfaceOrientation:[self fetchCurrentInterfaceOrientation]];
        }
    }
    for(UIView<WJKVideoPlayerProtocol> *view in self.bufferingIndicatorContainerView.subviews){
        if([view respondsToSelector:@selector(layoutThatFits:nearestViewControllerInViewTree:interfaceOrientation:)]){
            [view layoutThatFits:self.bounds
 nearestViewControllerInViewTree:nearestViewController
            interfaceOrientation:[self fetchCurrentInterfaceOrientation]];
        }
    }
}

- (WJKVideoPlayViewInterfaceOrientation)fetchCurrentInterfaceOrientation {
    return self.superview.wjk_viewInterfaceOrientation;
}

- (UIViewController *)findNearestViewControllerForView:(UIView *)view {
    if(!view){
        return nil;
    }

    BOOL isFind = [[view nextResponder] isKindOfClass:[UIViewController class]] && CGRectEqualToRect(view.bounds, [UIScreen mainScreen].bounds);
    if(isFind){
        return (UIViewController *)[view nextResponder];
    }
    return [self findNearestViewControllerForView:view.superview];
}

#pragma mark - Setup

- (void)_setup {
    self.placeholderView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];

        view;
    });

    self.videoContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];
        view.userInteractionEnabled = NO;

        view;
    });

    self.bufferingIndicatorContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];
        view.userInteractionEnabled = NO;

        view;
    });

    self.progressContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];

        view;
    });
    
    self.controlContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];
        
        view;
    });
}

@end
