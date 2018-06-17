//
//  WJKVideoPlayer.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/4/28.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "WJKVideoPlayer.h"
#import "WJKVideoPlayerResourceLoader.h"
#import "UIView+WebVideoCache.h"
#import <pthread.h>

@interface WJKVideoPlayerModel()

/**
 * The playing URL.
 */
@property(nonatomic, strong, nullable)NSURL *url;

/**
 * The view of the video picture will show on.
 */
@property(nonatomic, weak, nullable)CALayer *unownedShowLayer;

/**
 * options,
 */
@property(nonatomic, assign)WJKVideoPlayerOptions playerOptions;

/**
 * The Player to play video.
 */
@property(nonatomic, strong, nullable)AVPlayer *player;

/**
 * The current player's layer.
 */
@property(nonatomic, strong, nullable)AVPlayerLayer *playerLayer;

/**
 * The current player's item.
 */
@property(nonatomic, strong, nullable)AVPlayerItem *playerItem;

/**
 * The current player's urlAsset.
 */
@property(nonatomic, strong, nullable)AVURLAsset *videoURLAsset;

/**
 * A flag to book is cancel play or not.
 */
@property(nonatomic, assign, getter=isCancelled)BOOL cancelled;

/**
 * The resourceLoader for the videoPlayer.
 */
@property(nonatomic, strong, nullable)WJKVideoPlayerResourceLoader *resourceLoader;

/**
 * The last play time for player.
 */
@property(nonatomic, assign)NSTimeInterval lastTime;

/**
 * The play progress observer.
 */
@property(nonatomic, strong)id timeObserver;

/*
 * videoPlayer.
 */
@property(nonatomic, weak) WJKVideoPlayer *videoPlayer;

@property(nonatomic, assign) NSTimeInterval elapsedSeconds;

@property(nonatomic, assign) NSTimeInterval totalSeconds;

@end

static NSString *WJKVideoPlayerURLScheme = @"systemCannotRecognitionScheme";
static NSString *WJKVideoPlayerURL = @"www.wujike.com.cn";
@implementation WJKVideoPlayerModel

#pragma mark - WJKVideoPlayerPlaybackProtocol

- (void)setRate:(float)rate {
    self.player.rate = rate;
}

- (float)rate {
    return self.player.rate;
}

- (void)setMuted:(BOOL)muted {
    self.player.muted = muted;
}

- (BOOL)muted {
    return self.player.muted;
}

- (void)setVolume:(float)volume {
    self.player.volume = volume;
}

- (float)volume {
    return self.player.volume;
}

- (void)seekToTime:(CMTime)time {
    NSAssert(NO, @"You cannot call this method.");
}

- (void)pause {
    [self.player pause];
}

- (void)resume {
    [self.player play];
}

- (CMTime)currentTime {
    return self.player.currentTime;
}

- (void)stopPlay {
    self.cancelled = YES;
    [self reset];
}

- (void)reset {
    // remove video layer from superlayer.
    if (self.playerLayer.superlayer) {
        [self.playerLayer removeFromSuperlayer];
    }

    // remove observer.
    [self.playerItem removeObserver:self.videoPlayer forKeyPath:@"status"];
    [self.playerItem removeObserver:self.videoPlayer forKeyPath:@"loadedTimeRanges"];
    [self.player removeTimeObserver:self.timeObserver];
    [self.player removeObserver:self.videoPlayer forKeyPath:@"rate"];

    // remove player
    [self.player pause];
    [self.player cancelPendingPrerolls];
    self.player = nil;
    [self.videoURLAsset.resourceLoader setDelegate:nil queue:dispatch_get_main_queue()];
    self.playerItem = nil;
    self.playerLayer = nil;
    self.videoURLAsset = nil;
    self.resourceLoader = nil;
    self.elapsedSeconds = 0;
    self.totalSeconds = 0;
}

@end


@interface WJKVideoPlayer()<WJKVideoPlayerResourceLoaderDelegate>

/**
 * The current play video item.
 */
@property(nonatomic, strong, nullable)WJKVideoPlayerModel *playerModel;

/**
 * The playing status of video player before app enter background.
 */
@property(nonatomic, assign)WJKVideoPlayerStatus playerStatus_beforeEnterBackground;

/*
 * lock.
 */
@property(nonatomic) pthread_mutex_t lock;

@property (nonatomic, strong) NSTimer *checkBufferingTimer;

@property(nonatomic, assign) WJKVideoPlayerStatus playerStatus;

@end

@implementation WJKVideoPlayer

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
    [self stopPlay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &mutexattr);
        _playerStatus = WJKVideoPlayerStatusUnknown;
        [self addObserver];
    }
    return self;
}


#pragma mark - Public

- (WJKVideoPlayerModel *)playExistedVideoWithURL:(NSURL *)url
                             fullVideoCachePath:(NSString *)fullVideoCachePath
                                        options:(WJKVideoPlayerOptions)options
                                    showOnLayer:(CALayer *)showLayer
                        configurationCompletion:(WJKPlayVideoConfigurationCompletion)configurationCompletion {
    if (!url.absoluteString.length) {
        [self callDelegateMethodWithError:WJKErrorWithDescription(@"The url is disable")];
        return nil;
    }

    if (fullVideoCachePath.length==0) {
        [self callDelegateMethodWithError:WJKErrorWithDescription(@"The file path is disable")];
        return nil;
    }

    if (!showLayer) {
        [self callDelegateMethodWithError:WJKErrorWithDescription(@"The layer to display video layer is nil")];
        return nil;
    }
    if(self.playerModel){
        [self.playerModel reset];
        self.playerModel = nil;
    }

    NSURL *videoPathURL = [NSURL fileURLWithPath:fullVideoCachePath];
    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:videoPathURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:videoURLAsset];
    WJKVideoPlayerModel *model = [self playerModelWithURL:url
                                              playerItem:playerItem
                                                 options:options
                                             showOnLayer:showLayer];
    if (options & WJKVideoPlayerMutedPlay) {
        model.player.muted = YES;
    }
    self.playerModel = model;
    if(configurationCompletion){
        configurationCompletion([UIView new], model);
    }
    return model;
}

- (nullable WJKVideoPlayerModel *)playVideoWithURL:(NSURL *)url
                                          options:(WJKVideoPlayerOptions)options
                                        showLayer:(CALayer *)showLayer
                          configurationCompletion:(WJKPlayVideoConfigurationCompletion)configurationCompletion {
    if (!url.absoluteString.length) {
        [self callDelegateMethodWithError:WJKErrorWithDescription(@"The url is disable")];
        return nil;
    }

    if (!showLayer) {
        [self callDelegateMethodWithError:WJKErrorWithDescription(@"The layer to display video layer is nil")];
        return nil;
    }

    if(self.playerModel){
        [self.playerModel reset];
        self.playerModel = nil;
    }

    // Re-create all all configuration again.
    // Make the `resourceLoader` become the delegate of 'videoURLAsset', and provide data to the player.
//    WJKVideoPlayerResourceLoader *resourceLoader = [WJKVideoPlayerResourceLoader resourceLoaderWithCustomURL:url];
//    resourceLoader.delegate = self;
//    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:[self handleVideoURL] options:nil];
//    [videoURLAsset.resourceLoader setDelegate:resourceLoader queue:dispatch_get_main_queue()];

    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:videoURLAsset];
    WJKVideoPlayerModel *model = [self playerModelWithURL:url
                                              playerItem:playerItem
                                                 options:options
                                             showOnLayer:showLayer];
    self.playerModel = model;
    
//    model.resourceLoader = resourceLoader;
    
    if (options & WJKVideoPlayerMutedPlay) {
        model.player.muted = YES;
    }
    if(configurationCompletion){
        configurationCompletion([UIView new], model);
    }
    return model;
}

- (void)resumePlayWithShowLayer:(CALayer *)showLayer
                        options:(WJKVideoPlayerOptions)options
        configurationCompletion:(WJKPlayVideoConfigurationCompletion)configurationCompletion {
    if (!showLayer) {
        [self callDelegateMethodWithError:WJKErrorWithDescription(@"The layer to display video layer is nil")];
        return;
    }
    [self.playerModel.playerLayer removeFromSuperlayer];
    self.playerModel.unownedShowLayer = showLayer;

    if (options & WJKVideoPlayerMutedPlay) {
        self.playerModel.player.muted = YES;
    }
    else {
        self.playerModel.player.muted = NO;
    }
    [self setVideoGravityWithOptions:options playerModel:self.playerModel];
    [self displayVideoPicturesOnShowLayer];

    if(configurationCompletion){
        configurationCompletion([UIView new], self.playerModel);
    }
    [self callPlayerStatusDidChangeDelegateMethod];
}

- (void)seekToTimeWhenRecordPlayback:(CMTime)time {
    if(!self.playerModel){
        return;
    }
    if(!CMTIME_IS_VALID(time)){
        return;
    }
    __weak typeof(self) wself = self;
    [self.playerModel.player seekToTime:time completionHandler:^(BOOL finished) {
        
        __strong typeof(wself) sself = wself;
        if(finished){
            [sself internalResumeWithNeedCallDelegate:YES];
        }
    }];
}

#pragma mark - WJKVideoPlayerPlaybackProtocol

- (void)setRate:(float)rate {
    if(!self.playerModel){
        return;
    }
    [self.playerModel setRate:rate];
}

- (float)rate {
    if(!self.playerModel){
        return 0;
    }
    return self.playerModel.rate;
}

- (void)setMuted:(BOOL)muted {
    if(!self.playerModel){
        return;
    }
    [self.playerModel setMuted:muted];
}

- (BOOL)muted {
    if(!self.playerModel){
        return NO;
    }
    return self.playerModel.muted;
}

- (void)setVolume:(float)volume {
    if(!self.playerModel){
        return;
    }
    [self.playerModel setVolume:volume];
}

- (float)volume {
    if(!self.playerModel){
        return 0;
    }
    return self.playerModel.volume;
}

- (void)seekToTime:(CMTime)time {
    if(!self.playerModel){
        return;
    }
    if(!CMTIME_IS_VALID(time)){
        return;
    }
    BOOL needResume = self.playerModel.player.rate != 0;
    self.playerModel.lastTime = 0;
    [self internalPauseWithNeedCallDelegate:NO];
    __weak typeof(self) wself = self;
    [self.playerModel.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(wself) sself = wself;
        if(finished && needResume){
            [sself internalResumeWithNeedCallDelegate:NO];
        }
    }];
}

- (NSTimeInterval)elapsedSeconds {
    return [self.playerModel elapsedSeconds];
}

- (NSTimeInterval)totalSeconds {
    return [self.playerModel totalSeconds];
}

- (void)pause {
    if(!self.playerModel){
        return;
    }
    [self internalPauseWithNeedCallDelegate:YES];
}

- (void)resume {
    if(!self.playerModel){
        return;
    }
    if(self.playerStatus == WJKVideoPlayerStatusStop){
       self.playerStatus = WJKVideoPlayerStatusUnknown;
       [self seekToHeaderThenStartPlayback];
        return;
    }
    [self internalResumeWithNeedCallDelegate:YES];
}

- (CMTime)currentTime {
    if(!self.playerModel){
        return kCMTimeZero;
    }
    return self.playerModel.currentTime;
}

- (void)stopPlay{
    if(!self.playerModel){
        return;
    }
    [self.playerModel stopPlay];
    [self stopCheckBufferingTimerIfNeed];
    [self resetAwakeWaitingTimeInterval];
    self.playerModel = nil;
    self.playerStatus = WJKVideoPlayerStatusStop;
    [self callPlayerStatusDidChangeDelegateMethod];
}


#pragma mark - WJKVideoPlayerResourceLoaderDelegate

- (void)resourceLoader:(WJKVideoPlayerResourceLoader *)resourceLoader
didReceiveLoadingRequestTask:(WJKResourceLoadingRequestWebTask *)requestTask {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:didReceiveLoadingRequestTask:)]) {
        [self.delegate videoPlayer:self didReceiveLoadingRequestTask:requestTask];
    }
}


#pragma mark - App Observer

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appReceivedMemoryWarning)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
}

- (void)appReceivedMemoryWarning {
    [self.playerModel stopPlay];
}


#pragma mark - AVPlayer Observer

- (void)playerItemDidPlayToEnd:(NSNotification *)notification {
    AVPlayerItem *playerItem = notification.object;
    if(playerItem != self.playerModel.playerItem){
        return;
    }

    self.playerStatus = WJKVideoPlayerStatusStop;
    [self callPlayerStatusDidChangeDelegateMethod];
    [self stopCheckBufferingTimerIfNeed];

    // ask need automatic replay or not.
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:shouldAutoReplayVideoForURL:)]) {
        if (![self.delegate videoPlayer:self shouldAutoReplayVideoForURL:self.playerModel.url]) {
            return;
        }
    }
    [self seekToHeaderThenStartPlayback];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        AVPlayerItemStatus status = playerItem.status;
        switch (status) {
            case AVPlayerItemStatusUnknown:{
                self.playerStatus = AVPlayerItemStatusUnknown;
                [self callPlayerStatusDidChangeDelegateMethod];
            }
                break;

            case AVPlayerItemStatusReadyToPlay:{
                WJKDebugLog(@"AVPlayerItemStatusReadyToPlay");
                self.playerStatus = WJKVideoPlayerStatusReadyToPlay;
                // When get ready to play note, we can go to play, and can add the video picture on show view.
                if (!self.playerModel) return;
                [self displayVideoPicturesOnShowLayer];
            }
                break;

            case AVPlayerItemStatusFailed:{
                [self stopCheckBufferingTimerIfNeed];
                self.playerStatus = WJKVideoPlayerStatusFailed;
                [self callDelegateMethodWithError:WJKErrorWithDescription(@"AVPlayerItemStatusFailed")];
                [self callPlayerStatusDidChangeDelegateMethod];
            }
                break;

            default:
                break;
        }
    }
    else if([keyPath isEqualToString:@"rate"]) {
        float rate = [change[NSKeyValueChangeNewKey] floatValue];
        if((rate != 0) && (self.playerStatus == WJKVideoPlayerStatusReadyToPlay)){
            self.playerStatus = WJKVideoPlayerStatusPlaying;
            [self callPlayerStatusDidChangeDelegateMethod];
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        NSArray *cacheRanges = playerItem.loadedTimeRanges;
        [self callDelegateMethodWithCacheRanges:cacheRanges];
    }
}


#pragma mark - Timer

- (void)startCheckBufferingTimer {
    if(self.checkBufferingTimer){
        [self stopCheckBufferingTimerIfNeed];
    }
    self.checkBufferingTimer = ({
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(checkBufferingTimeDidChange)
                                               userInfo:nil
                                                repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

        timer;
    });
}

- (void)stopCheckBufferingTimerIfNeed {
    if(self.checkBufferingTimer){
        [self.checkBufferingTimer invalidate];
        self.checkBufferingTimer = nil;
    }
}

- (void)checkBufferingTimeDidChange {
    NSTimeInterval currentTime = CMTimeGetSeconds(self.playerModel.player.currentTime);
    if (currentTime != 0 && currentTime > self.playerModel.lastTime) {
        self.playerModel.lastTime = currentTime;
        [self endAwakeFromBuffering];
        if(self.playerStatus == WJKVideoPlayerStatusPlaying){
            return;
        }
        self.playerStatus = WJKVideoPlayerStatusPlaying;
        [self callPlayerStatusDidChangeDelegateMethod];
    }
    else{
        if(self.playerStatus == WJKVideoPlayerStatusBuffering){
            [self startAwakeWhenBuffering];
            return;
        }
        self.playerStatus = WJKVideoPlayerStatusBuffering;
        [self callPlayerStatusDidChangeDelegateMethod];
    }
}


#pragma mark - Awake When Buffering

static NSTimeInterval _awakeWaitingTimeInterval = 3;
- (void)resetAwakeWaitingTimeInterval {
    _awakeWaitingTimeInterval = 3;
    WJKDebugLog(@"重置了播放唤醒等待时间");
}

- (void)updateAwakeWaitingTimerInterval {
    _awakeWaitingTimeInterval += 2;
    if(_awakeWaitingTimeInterval > 12){
        _awakeWaitingTimeInterval = 12;
    }
}

static BOOL _isOpenAwakeWhenBuffering = NO;
- (void)startAwakeWhenBuffering {
    if(!_isOpenAwakeWhenBuffering){
        _isOpenAwakeWhenBuffering = YES;
        WJKDebugLog(@"Start awake when buffering.");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_awakeWaitingTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            if(!_isOpenAwakeWhenBuffering){
                [self endAwakeFromBuffering];
                WJKDebugLog(@"Player is playing when call awake buffering block.");
                return;
            }
            WJKDebugLog(@"Call resume in awake buffering block.");
            _isOpenAwakeWhenBuffering = NO;
            [self.playerModel pause];
            [self updateAwakeWaitingTimerInterval];
            [self.playerModel resume];

        });
    }
}

- (void)endAwakeFromBuffering {
    if(_isOpenAwakeWhenBuffering){
        WJKDebugLog(@"End awake buffering.");
        _isOpenAwakeWhenBuffering = NO;
        [self resetAwakeWaitingTimeInterval];
    }
}


#pragma mark - Private

- (void)seekToHeaderThenStartPlayback {
    // Seek the start point of file data and repeat play, this handle have no memory surge.
    __weak typeof(self.playerModel) weak_Item = self.playerModel;
    [self.playerModel.player seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
        __strong typeof(weak_Item) strong_Item = weak_Item;
        if (!strong_Item) return;

        self.playerModel.lastTime = 0;
        [strong_Item.player play];
        [self callPlayerStatusDidChangeDelegateMethod];
        [self startCheckBufferingTimer];

    }];
}

- (void)callPlayerStatusDidChangeDelegateMethod {
    WJKDispatchSyncOnMainQueue(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:playerStatusDidChange:)]) {
            [self.delegate videoPlayer:self playerStatusDidChange:self.playerStatus];
        }
    });
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:playerStatusDidChange:)]) {
        [self.delegate videoPlayer:self playerStatusDidChange:self.playerStatus];
    }
}

- (void)internalPauseWithNeedCallDelegate:(BOOL)needCallDelegate {
    [self.playerModel pause];
    [self stopCheckBufferingTimerIfNeed];
    self.playerStatus = WJKVideoPlayerStatusPause;
    [self endAwakeFromBuffering];
    if(needCallDelegate){
        [self callPlayerStatusDidChangeDelegateMethod];
    }
}

- (void)internalResumeWithNeedCallDelegate:(BOOL)needCallDelegate {
    [self.playerModel resume];
    [self startCheckBufferingTimer];
    self.playerStatus = WJKVideoPlayerStatusPlaying;
    if(needCallDelegate){
        [self callPlayerStatusDidChangeDelegateMethod];
    }
}

- (WJKVideoPlayerModel *)playerModelWithURL:(NSURL *)url
                                playerItem:(AVPlayerItem *)playerItem
                                   options:(WJKVideoPlayerOptions)options
                               showOnLayer:(CALayer *)showLayer {
    [self resetAwakeWaitingTimeInterval];
    WJKVideoPlayerModel *model = [WJKVideoPlayerModel new];
    model.unownedShowLayer = showLayer;
    model.url = url;
    model.playerOptions = options;
    model.playerItem = playerItem;
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    //Zaihu : 添加缓存监听(可能在支持自动缓存状态下有问题,修改了库)
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];

    model.player = [AVPlayer playerWithPlayerItem:playerItem];
    [model.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    if ([model.player respondsToSelector:@selector(automaticallyWaitsToMinimizeStalling)]) {
        model.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    model.playerLayer = [AVPlayerLayer playerLayerWithPlayer:model.player];
    [self setVideoGravityWithOptions:options playerModel:model];
    model.videoPlayer = self;
    self.playerStatus = WJKVideoPlayerStatusUnknown;
    [self startCheckBufferingTimer];

    // add observer for video playing progress.
    __weak typeof(model) wItem = model;
    __weak typeof(self) wself = self;
    [model.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        __strong typeof(wItem) sItem = wItem;
        __strong typeof(wself) sself = wself;
        if (!sItem || !sself) return;

        double elapsedSeconds = CMTimeGetSeconds(time);
        double totalSeconds = CMTimeGetSeconds(sItem.playerItem.duration);
        sself.playerModel.elapsedSeconds = elapsedSeconds;
        sself.playerModel.totalSeconds = totalSeconds;
        if(totalSeconds == 0 || isnan(totalSeconds) || elapsedSeconds > totalSeconds){
            return;
        }
        WJKDispatchSyncOnMainQueue(^{
            if (sself.delegate && [sself.delegate respondsToSelector:@selector(videoPlayerPlayProgressDidChange:elapsedSeconds:totalSeconds:)]) {
                [sself.delegate videoPlayerPlayProgressDidChange:sself
                                                  elapsedSeconds:elapsedSeconds
                                                    totalSeconds:totalSeconds];
            }
        });

    }];

    return model;
}

- (void)setVideoGravityWithOptions:(WJKVideoPlayerOptions)options
                       playerModel:(WJKVideoPlayerModel *)playerModel {
    NSString *videoGravity = nil;
    if (options & WJKVideoPlayerLayerVideoGravityResizeAspect) {
        videoGravity = AVLayerVideoGravityResizeAspect;
    }
    else if (options & WJKVideoPlayerLayerVideoGravityResize){
        videoGravity = AVLayerVideoGravityResize;
    }
    else if (options & WJKVideoPlayerLayerVideoGravityResizeAspectFill){
        videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    playerModel.playerLayer.videoGravity = videoGravity;
}

- (NSURL *)handleVideoURL {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:WJKVideoPlayerURL] resolvingAgainstBaseURL:NO];
    components.scheme = WJKVideoPlayerURLScheme;
    return [components URL];
}

- (void)displayVideoPicturesOnShowLayer{
    if (!self.playerModel.isCancelled) {
        // fixed #26.
        self.playerModel.playerLayer.frame = self.playerModel.unownedShowLayer.bounds;
        // use dispatch_after to prevent layer layout animation.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.playerModel.unownedShowLayer addSublayer:self.playerModel.playerLayer];
        });
    }
}

- (void)callDelegateMethodWithError:(NSError *)error {
    WJKDebugLog(@"Player abort because of error: %@", error);
    WJKDispatchSyncOnMainQueue(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:playFailedWithError:)]) {
            [self.delegate videoPlayer:self playFailedWithError:error];
        }
    });
}

- (void)callDelegateMethodWithCacheRanges:(NSArray<NSValue *> *)cacheRanges {
    WJKDebugLog(@"Player cache video ranges: %@", cacheRanges);
    WJKDispatchSyncOnMainQueue(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:cacheRangeDidChange:)]) {
            [self.delegate videoPlayer:self cacheRangeDidChange:cacheRanges];
        }
    });
}

@end
