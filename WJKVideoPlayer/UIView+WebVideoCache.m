//
//  UIView+WebVideoCache.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "UIView+WebVideoCache.h"
#import <objc/runtime.h>
#import "WJKVideoPlayer.h"
#import "WJKVideoPlayerSupportUtils.h"
#import "WJKVideoPlayerControlViews.h"

@interface WJKVideoPlayerHelper : NSObject

@property(nonatomic, strong) WJKVideoPlayerView *videoPlayerView;

@property(nonatomic, strong) UIView<WJKVideoPlayerProtocol> *progressView;

@property(nonatomic, strong) UIView<WJKVideoPlayerProtocol> *controlView;

@property(nonatomic, strong) UIView<WJKVideoPlayerBufferingProtocol> *bufferingIndicator;

@property(nonatomic, weak) id<WJKVideoPlayerDelegate> videoPlayerDelegate;

@property(nonatomic, assign) WJKVideoPlayViewInterfaceOrientation viewInterfaceOrientation;

@property(nonatomic, assign)WJKVideoPlayerStatus playerStatus;

@property (nonatomic, weak) UIView *playVideoView;

@property(nonatomic, copy) NSURL *videoURL;

@end

@implementation WJKVideoPlayerHelper

- (instancetype)initWithPlayVideoView:(UIView *)playVideoView {
    self = [super init];
    if(self){
       _playVideoView = playVideoView;
    }
    return self;
}

- (WJKVideoPlayViewInterfaceOrientation)viewInterfaceOrientation {
    if(_viewInterfaceOrientation == WJKVideoPlayViewInterfaceOrientationUnknown){
       CGSize referenceSize = self.playVideoView.window.bounds.size;
       _viewInterfaceOrientation = referenceSize.width < referenceSize.height ? WJKVideoPlayViewInterfaceOrientationPortrait :
               WJKVideoPlayViewInterfaceOrientationLandscape;
    }
    return _viewInterfaceOrientation;
}

- (WJKVideoPlayerView *)videoPlayerView {
    if(!_videoPlayerView){
        BOOL autoHide = YES;
        if (_playVideoView.wjk_videoPlayerDelegate && [_playVideoView.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldAutoHideControlContainerViewWhenUserTapping)]) {
            autoHide = [_playVideoView.wjk_videoPlayerDelegate shouldAutoHideControlContainerViewWhenUserTapping];
        }
        _videoPlayerView = [[WJKVideoPlayerView alloc] init];
    }
    return _videoPlayerView;
}

@end

@interface UIView()

@property(nonatomic, readonly)WJKVideoPlayerHelper *helper;

@end

@implementation UIView (WebVideoCache)

#pragma mark - Properties

- (WJKVideoPlayViewInterfaceOrientation)wjk_viewInterfaceOrientation {
    return self.helper.viewInterfaceOrientation;
}

- (WJKVideoPlayerStatus)wjk_playerStatus {
    return self.helper.playerStatus;
}

- (WJKVideoPlayerView *)wjk_videoPlayerView {
    return self.helper.videoPlayerView;
}

- (void)setWjk_progressView:(UIView <WJKVideoPlayerProtocol> *)wjk_progressView {
    self.helper.progressView = wjk_progressView;
}

- (UIView <WJKVideoPlayerProtocol> *)wjk_progressView {
    return self.helper.progressView;
}

- (void)setWjk_controlView:(UIView <WJKVideoPlayerProtocol> *)wjk_controlView {
    self.helper.controlView = wjk_controlView;
}

- (UIView <WJKVideoPlayerProtocol> *)wjk_controlView {
    return self.helper.controlView;
}

- (void)setWjk_bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *)wjk_bufferingIndicator {
    self.helper.bufferingIndicator = wjk_bufferingIndicator;
}

- (UIView <WJKVideoPlayerBufferingProtocol> *)wjk_bufferingIndicator {
    return self.helper.bufferingIndicator;
}

- (void)setWjk_videoPlayerDelegate:(id <WJKVideoPlayerDelegate>)wjk_videoPlayerDelegate {
    self.helper.videoPlayerDelegate = wjk_videoPlayerDelegate;
}

- (id <WJKVideoPlayerDelegate>)wjk_videoPlayerDelegate {
    return self.helper.videoPlayerDelegate;
}

- (NSURL *)wjk_videoURL {
    return self.helper.videoURL;
}

- (void)setWjk_videoURL:(NSURL *)wjk_videoURL {
    self.helper.videoURL = wjk_videoURL.copy;
}


#pragma mark - Play Video Methods

- (void)wjk_playVideoWithURL:(NSURL *)url {
    [self wjk_playVideoWithURL:url
                      options:WJKVideoPlayerContinueInBackground |
                              WJKVideoPlayerLayerVideoGravityResizeAspect
                configuration:nil];
}

- (void)wjk_playVideoMuteWithURL:(NSURL *)url
             bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                   progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
                  configuration:(WJKPlayVideoConfiguration _Nullable)configuration {
    [self setBufferingIndicator:bufferingIndicator
                    controlView:nil
                   progressView:progressView
             needSetControlView:NO];
    [self wjk_stopPlay];
    [self wjk_playVideoWithURL:url
                      options:WJKVideoPlayerContinueInBackground |
                              WJKVideoPlayerLayerVideoGravityResizeAspect
                configuration:configuration];
}

- (void)wjk_resumeMutePlayWithURL:(NSURL *)url
              bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                    progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
                   configuration:(WJKPlayVideoConfiguration _Nullable)configuration {
    [self setBufferingIndicator:bufferingIndicator
                    controlView:nil
                   progressView:progressView
             needSetControlView:NO];
    [self wjk_resumePlayWithURL:url
                       options:WJKVideoPlayerContinueInBackground |
                               WJKVideoPlayerLayerVideoGravityResizeAspect |
                               WJKVideoPlayerMutedPlay
                 configuration:configuration];
}

- (void)wjk_playVideoWithURL:(NSURL *)url
         bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                controlView:(UIView <WJKVideoPlayerProtocol> *_Nullable)controlView
               progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
              configuration:(WJKPlayVideoConfiguration _Nullable)configuration
          needSetControlView:(BOOL)needSetControlView {
    [self setBufferingIndicator:bufferingIndicator
                    controlView:controlView
                   progressView:progressView
             needSetControlView:needSetControlView];
    [self wjk_stopPlay];
    [self wjk_playVideoWithURL:url
                      options:WJKVideoPlayerContinueInBackground |
                              WJKVideoPlayerLayerVideoGravityResizeAspect
                configuration:configuration];
}

- (void)wjk_resumePlayWithURL:(NSURL *)url
          bufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                 controlView:(UIView <WJKVideoPlayerProtocol> *_Nullable)controlView
                progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
               configuration:(WJKPlayVideoConfiguration _Nullable)configuration
           needSetControlView:(BOOL)needSetControlView {
    [self setBufferingIndicator:bufferingIndicator
                    controlView:controlView
                   progressView:progressView
             needSetControlView:needSetControlView];
    [self wjk_resumePlayWithURL:url
                       options:WJKVideoPlayerContinueInBackground |
                               WJKVideoPlayerLayerVideoGravityResizeAspect
                 configuration:configuration];
}

- (void)setBufferingIndicator:(UIView <WJKVideoPlayerBufferingProtocol> *_Nullable)bufferingIndicator
                  controlView:(UIView <WJKVideoPlayerProtocol> *_Nullable)controlView
                 progressView:(UIView <WJKVideoPlayerProtocol> *_Nullable)progressView
              needSetControlView:(BOOL)needSetControlView {
    // should show default.
    BOOL showDefaultView = YES;
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldShowDefaultControlAndIndicatorViews)]) {
        showDefaultView = [self.wjk_videoPlayerDelegate shouldShowDefaultControlAndIndicatorViews];
    }
    // user update progressView.
    if(progressView && self.wjk_progressView){
        [self.wjk_progressView removeFromSuperview];
    }
    if(showDefaultView && !progressView && !self.wjk_progressView){
        // Use default `WJKVideoPlayerProgressView` if no progressView.
        progressView = [WJKVideoPlayerProgressView new];
    }
    if(progressView){
        self.wjk_progressView = progressView;
    }

    // user update bufferingIndicator.
    if(bufferingIndicator && self.wjk_bufferingIndicator){
        [self.wjk_bufferingIndicator removeFromSuperview];
    }
    if(showDefaultView && !bufferingIndicator && !self.wjk_bufferingIndicator){
        // Use default `WJKVideoPlayerBufferingIndicator` if no bufferingIndicator.
        bufferingIndicator = [WJKVideoPlayerBufferingIndicator new];
    }
    if(bufferingIndicator){
        self.wjk_bufferingIndicator = bufferingIndicator;
    }

    if(needSetControlView){
        //before setting controllerView userInteractionEnabled should be enabled.
        self.userInteractionEnabled = YES;
        // user update controlView.
        if(controlView && self.wjk_controlView){
            [self.wjk_controlView removeFromSuperview];
        }
        if(showDefaultView && !controlView && !self.wjk_controlView){
            // Use default `WJKVideoPlayerControlView` if no controlView.
            controlView = [[WJKVideoPlayerControlView alloc] initWithControlBar:nil blurImage:nil needAutoHideControlView:YES];
        }
        if(controlView){
            self.wjk_controlView = controlView;
        }
    }
}

- (void)wjk_playVideoWithURL:(NSURL *)url
                    options:(WJKVideoPlayerOptions)options
              configuration:(WJKPlayVideoConfiguration)configuration {
    [self playVideoWithURL:url
                   options:options
             configuration:configuration
                  isResume:NO];
}

- (void)wjk_resumePlayWithURL:(NSURL *)url
                     options:(WJKVideoPlayerOptions)options
               configuration:(WJKPlayVideoConfiguration _Nullable)configuration {
    [self playVideoWithURL:url
                   options:options
             configuration:configuration
                  isResume:YES];
}

- (void)playVideoWithURL:(NSURL *)url
                     options:(WJKVideoPlayerOptions)options
               configuration:(WJKPlayVideoConfiguration _Nullable)configuration
                isResume:(BOOL)isResume {
    WJKMainThreadAssert;
    self.wjk_videoURL = url;
    if (url) {
        [WJKVideoPlayerManager sharedManager].delegate = self;
        self.helper.viewInterfaceOrientation = WJKVideoPlayViewInterfaceOrientationPortrait;

        // handler the reuse of progressView in `UITableView`.
        if(self.wjk_progressView && [self.wjk_progressView respondsToSelector:@selector(viewWillPrepareToReuse)]){
            [self.wjk_progressView viewWillPrepareToReuse];
        }
        if(self.wjk_controlView && [self.wjk_controlView respondsToSelector:@selector(viewWillPrepareToReuse)]){
            [self.wjk_controlView viewWillPrepareToReuse];
        }
        [self callFinishBufferingDelegate];
        // Add progressView and controlView if need.
        self.helper.videoPlayerView.hidden = NO;
        if(self.wjk_bufferingIndicator && !self.wjk_bufferingIndicator.superview){
            self.wjk_bufferingIndicator.frame = self.bounds;
            [self.helper.videoPlayerView.bufferingIndicatorContainerView addSubview:self.wjk_bufferingIndicator];
        }
        if(self.wjk_bufferingIndicator){
            [self callStartBufferingDelegate];
        }

        if(self.wjk_progressView && !self.wjk_progressView.superview){
            self.wjk_progressView.frame = self.bounds;
            if(self.wjk_progressView && [self.wjk_progressView respondsToSelector:@selector(viewWillAddToSuperView:)]){
                [self.wjk_progressView viewWillAddToSuperView:self];
            }
            [self.helper.videoPlayerView.progressContainerView addSubview:self.wjk_progressView];
        }
        if(self.wjk_controlView && !self.wjk_controlView.superview){
            self.wjk_controlView.frame = self.bounds;
            if(self.wjk_controlView && [self.wjk_controlView respondsToSelector:@selector(viewWillAddToSuperView:)]){
                [self.wjk_controlView viewWillAddToSuperView:self];
            }
            [self.helper.videoPlayerView.controlContainerView addSubview:self.wjk_controlView];
            self.helper.videoPlayerView.progressContainerView.alpha = 0;
        }
        if(!self.helper.videoPlayerView.superview){
            [self addSubview:self.helper.videoPlayerView];
        }
        self.helper.videoPlayerView.frame = self.bounds;
        self.helper.videoPlayerView.backgroundColor = [UIColor clearColor];
        if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldShowBlackBackgroundBeforePlaybackStart)]) {
            BOOL shouldShow = [self.wjk_videoPlayerDelegate shouldShowBlackBackgroundBeforePlaybackStart];
            if(shouldShow){
                self.helper.videoPlayerView.backgroundColor = [UIColor blackColor];
            }
        }

        // nobody retain this block.
        WJKPlayVideoConfiguration internalConfigFinishedBlock = ^(UIView *view, WJKVideoPlayerModel *model){
            NSParameterAssert(model);
            if(configuration){
                configuration(self, model);
            }
        };
        
        if(!isResume){
            [[WJKVideoPlayerManager sharedManager] playVideoWithURL:url
                                                       showOnLayer:self.helper.videoPlayerView.videoContainerLayer
                                                            options:options
                                        configurationCompletion:internalConfigFinishedBlock];
            [self callOrientationDelegateWithInterfaceOrientation:self.wjk_viewInterfaceOrientation];
        }
        else {
            [[WJKVideoPlayerManager sharedManager] resumePlayWithURL:url
                                                        showOnLayer:self.helper.videoPlayerView.videoContainerLayer
                                                             options:options
                                        configurationCompletion:internalConfigFinishedBlock];
        }
    }
    else {
        WJKDispatchSyncOnMainQueue(^{
            if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(playVideoFailWithError:videoURL:)]) {
                [self.wjk_videoPlayerDelegate playVideoFailWithError:WJKErrorWithDescription(@"Try to play video with a invalid url")
                                                           videoURL:url];
            }
        });
    }
}


#pragma mark - Playback Control

- (void)setWjk_rate:(float)wjk_rate {
    WJKVideoPlayerManager.sharedManager.rate = wjk_rate;
}

- (float)wjk_rate {
    return WJKVideoPlayerManager.sharedManager.rate;
}

- (void)setWjk_muted:(BOOL)wjk_muted {
    WJKVideoPlayerManager.sharedManager.muted = wjk_muted;
}

- (BOOL)wjk_muted {
    return WJKVideoPlayerManager.sharedManager.muted;
}

- (void)setWjk_volume:(float)wjk_volume {
    WJKVideoPlayerManager.sharedManager.volume = wjk_volume;
}

- (float)wjk_volume {
    return WJKVideoPlayerManager.sharedManager.volume;
}

- (void)wjk_seekToTime:(CMTime)time {
    [[WJKVideoPlayerManager sharedManager] seekToTime:time];
}

- (NSTimeInterval)wjk_elapsedSeconds {
    return [WJKVideoPlayerManager.sharedManager elapsedSeconds];
}

- (NSTimeInterval)wjk_totalSeconds {
    return [WJKVideoPlayerManager.sharedManager totalSeconds];
}

- (void)wjk_pause {
    [[WJKVideoPlayerManager sharedManager] pause];
}

- (void)wjk_resume {
    [[WJKVideoPlayerManager sharedManager] resume];
}

- (CMTime)wjk_currentTime {
    return WJKVideoPlayerManager.sharedManager.currentTime;
}

- (void)wjk_stopPlay {
    [[WJKVideoPlayerManager sharedManager] stopPlay];
    self.helper.videoPlayerView.hidden = YES;
    self.helper.videoPlayerView.backgroundColor = [UIColor clearColor];
    [self callFinishBufferingDelegate];
}


#pragma mark - Landscape & Portrait Control

- (void)wjk_gotoLandscape {
    [self wjk_gotoLandscapeAnimated:YES
                        completion:nil];
}

- (void)wjk_gotoLandscapeAnimated:(BOOL)flag
                      completion:(dispatch_block_t)completion {
    if (self.wjk_viewInterfaceOrientation != WJKVideoPlayViewInterfaceOrientationPortrait) {
        return;
    }

    self.helper.viewInterfaceOrientation = WJKVideoPlayViewInterfaceOrientationLandscape;
    WJKVideoPlayerView *videoPlayerView = self.helper.videoPlayerView;
    videoPlayerView.backgroundColor = [UIColor blackColor];
    
    CGRect videoPlayerViewFrameInWindow = [self convertRect:videoPlayerView.frame toView:nil];
    [videoPlayerView removeFromSuperview];
    
    [[UIApplication sharedApplication].keyWindow addSubview:videoPlayerView];
    videoPlayerView.frame = videoPlayerViewFrameInWindow;
    videoPlayerView.controlContainerView.alpha = 0;

    if (flag) {
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self executeLandscape];
                         }
                         completion:^(BOOL finished) {
                             if (completion) {
                                 completion();
                             }
                             [UIView animateWithDuration:0.5 animations:^{
                                 videoPlayerView.controlContainerView.alpha = 1;
                             }];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                             // hide status bar.
                             [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
                         }];
    }
    else{
        [self executeLandscape];
        if (completion) {
            completion();
        }
        [UIView animateWithDuration:0.5 animations:^{
            videoPlayerView.controlContainerView.alpha = 0;
        }];
    }
    [self refreshStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
    [self callOrientationDelegateWithInterfaceOrientation:WJKVideoPlayViewInterfaceOrientationLandscape];
}

- (void)wjk_gotoPortrait {
    [self wjk_gotoPortraitAnimated:YES
                       completion:nil];
}

- (void)wjk_gotoPortraitAnimated:(BOOL)flag
                     completion:(dispatch_block_t)completion{
    if (self.wjk_viewInterfaceOrientation != WJKVideoPlayViewInterfaceOrientationLandscape) {
        return;
    }

    self.helper.viewInterfaceOrientation = WJKVideoPlayViewInterfaceOrientationPortrait;
    WJKVideoPlayerView *videoPlayerView = self.helper.videoPlayerView;
    videoPlayerView.backgroundColor = [UIColor blackColor];
    
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldShowBlackBackgroundWhenPlaybackStart)]) {
        BOOL shouldShow = [self.wjk_videoPlayerDelegate shouldShowBlackBackgroundWhenPlaybackStart];
        videoPlayerView.backgroundColor = shouldShow ? [UIColor blackColor] : [UIColor clearColor];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // display status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    videoPlayerView.controlContainerView.alpha = 0;
    if (flag) {
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self executePortrait];
                         }
                         completion:^(BOOL finished) {
                             [self finishPortrait];
                             if (completion) {
                                 completion();
                             }
                         }];
    }
    else{
        [self executePortrait];
        [self finishPortrait];
        if (completion) {
            completion();
        }
    }
    [self refreshStatusBarOrientation:UIInterfaceOrientationPortrait];
    [self callOrientationDelegateWithInterfaceOrientation:WJKVideoPlayViewInterfaceOrientationPortrait];
}

- (void)wjk_gotoScale {
    [self wjk_gotoScaleAnimated:YES
                         completion:nil];
}

- (void)wjk_gotoScaleAnimated:(BOOL)flag
                   completion:(dispatch_block_t _Nullable)completion {
    
    if (flag) {
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self executeScale];
                         }
                         completion:^(BOOL finished) {
                             if (completion) {
                                 completion();
                             }
                         }];
    }
    else{
        [self executeScale];
        if (completion) {
            completion();
        }
    }
}

- (void)wjk_gooutScale {
    [self wjk_gooutScaleAnimated:YES
                     completion:nil];
}

- (void)wjk_gooutScaleAnimated:(BOOL)flag
                    completion:(dispatch_block_t _Nullable)completion {
    if (flag) {
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self finishScale];
                         }
                         completion:^(BOOL finished) {
                             if (completion) {
                                 completion();
                             }
                         }];
    }
    else{
        [self finishScale];
        if (completion) {
            completion();
        }
    }
}

#pragma mark - Private

- (void)callOrientationDelegateWithInterfaceOrientation:(WJKVideoPlayViewInterfaceOrientation)interfaceOrientation {
    if(self.wjk_controlView && [self.wjk_controlView respondsToSelector:@selector(videoPlayerInterfaceOrientationDidChange:videoURL:)]){
        [self.wjk_controlView videoPlayerInterfaceOrientationDidChange:interfaceOrientation videoURL:self.wjk_videoURL];
    }
    if(self.wjk_progressView && [self.wjk_progressView respondsToSelector:@selector(videoPlayerInterfaceOrientationDidChange:videoURL:)]){
        [self.wjk_progressView videoPlayerInterfaceOrientationDidChange:interfaceOrientation videoURL:self.wjk_videoURL];
    }
}

- (void)callStartBufferingDelegate {
    if(self.wjk_bufferingIndicator && [self.wjk_bufferingIndicator respondsToSelector:@selector(didStartBufferingVideoURL:)]){
        [self.wjk_bufferingIndicator didStartBufferingVideoURL:self.wjk_videoURL];
    }
}

- (void)callFinishBufferingDelegate {
    if(self.wjk_bufferingIndicator && [self.wjk_bufferingIndicator respondsToSelector:@selector(didFinishBufferingVideoURL:)]){
        [self.wjk_bufferingIndicator didFinishBufferingVideoURL:self.wjk_videoURL];
    }
}

- (void)finishPortrait {
    WJKVideoPlayerView *videoPlayerView = self.helper.videoPlayerView;
    [videoPlayerView removeFromSuperview];
    [self addSubview:videoPlayerView];
    videoPlayerView.frame = self.bounds;
    [[WJKVideoPlayerManager sharedManager] videoPlayer].playerModel.playerLayer.frame = self.bounds;
    [UIView animateWithDuration:0.5 animations:^{
        videoPlayerView.controlContainerView.alpha = 1;
    }];
}

- (void)executePortrait {
    UIView *videoPlayerView = self.helper.videoPlayerView;
    CGRect frame = [self.superview convertRect:self.frame toView:nil];
    videoPlayerView.transform = CGAffineTransformIdentity;
    videoPlayerView.frame = frame;
    [[WJKVideoPlayerManager sharedManager] videoPlayer].playerModel.playerLayer.frame = self.bounds;
}

- (void)executeLandscape {
    UIView *videoPlayerView = self.helper.videoPlayerView;
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect bounds = CGRectMake(0, 0, CGRectGetHeight(screenBounds), CGRectGetWidth(screenBounds));
    CGPoint center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds));
    videoPlayerView.bounds = bounds;
    videoPlayerView.center = center;
    videoPlayerView.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    [[WJKVideoPlayerManager sharedManager] videoPlayer].playerModel.playerLayer.frame = bounds;
}

- (void)executeScale {
    UIView *videoPlayerView = self.helper.videoPlayerView;
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect bounds = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
    CGPoint center = CGPointMake(CGRectGetMidY(screenBounds), CGRectGetMidX(screenBounds));
    videoPlayerView.bounds = bounds;
    videoPlayerView.center = center;
    videoPlayerView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), 0.8, 0.8);
    [[WJKVideoPlayerManager sharedManager] videoPlayer].playerModel.playerLayer.frame = bounds;
}

- (void)finishScale {
    UIView *videoPlayerView = self.helper.videoPlayerView;
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect bounds = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
    CGPoint center = CGPointMake(CGRectGetMidY(screenBounds), CGRectGetMidX(screenBounds));
    videoPlayerView.bounds = bounds;
    videoPlayerView.center = center;
    videoPlayerView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), 1, 1);
    [[WJKVideoPlayerManager sharedManager] videoPlayer].playerModel.playerLayer.frame = bounds;
}

- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:YES];
#pragma clang diagnostic pop
}

- (WJKVideoPlayerHelper *)helper {
    WJKVideoPlayerHelper *helper = objc_getAssociatedObject(self, _cmd);
    if(!helper){
        helper = [[WJKVideoPlayerHelper alloc] initWithPlayVideoView:self];
        objc_setAssociatedObject(self, _cmd, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}


#pragma mark - WJKVideoPlayerManager

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
 shouldDownloadVideoForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldDownloadVideoForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldDownloadVideoForURL:videoURL];
    }
    return YES;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
    shouldAutoReplayForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldAutoReplayForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldAutoReplayForURL:videoURL];
    }
    return YES;
}

- (void)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
    playerStatusDidChanged:(WJKVideoPlayerStatus)playerStatus {
    if(playerStatus == WJKVideoPlayerStatusPlaying){
        self.helper.videoPlayerView.backgroundColor = [UIColor blackColor];
        if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldShowBlackBackgroundWhenPlaybackStart)]) {
            BOOL shouldShow = [self.wjk_videoPlayerDelegate shouldShowBlackBackgroundWhenPlaybackStart];
            self.helper.videoPlayerView.backgroundColor = shouldShow ? [UIColor blackColor] : [UIColor clearColor];
        }
    }
    self.helper.playerStatus = playerStatus;
    // WJKDebugLog(@"playerStatus: %ld", playerStatus);
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(playerStatusDidChanged:)]) {
        [self.wjk_videoPlayerDelegate playerStatusDidChanged:playerStatus];
    }
    BOOL needDisplayBufferingIndicator =
            playerStatus == WJKVideoPlayerStatusBuffering ||
                    playerStatus == WJKVideoPlayerStatusUnknown ||
                    playerStatus == WJKVideoPlayerStatusFailed;
    needDisplayBufferingIndicator ? [self callStartBufferingDelegate] : [self callFinishBufferingDelegate];
    if(self.wjk_controlView && [self.wjk_controlView respondsToSelector:@selector(videoPlayerStatusDidChange:videoURL:)]){
        [self.wjk_controlView videoPlayerStatusDidChange:playerStatus videoURL:self.wjk_videoURL];
    }
    if(self.wjk_progressView && [self.wjk_progressView respondsToSelector:@selector(videoPlayerStatusDidChange:videoURL:)]){
        [self.wjk_progressView videoPlayerStatusDidChange:playerStatus videoURL:self.wjk_videoURL];
    }
}

- (void)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
   didFetchVideoFileLength:(NSUInteger)videoLength {
    if(self.helper.controlView && [self.helper.controlView respondsToSelector:@selector(didFetchVideoFileLength:videoURL:)]){
        [self.helper.controlView didFetchVideoFileLength:videoLength videoURL:self.wjk_videoURL];
    }
    if(self.helper.progressView && [self.helper.progressView respondsToSelector:@selector(didFetchVideoFileLength:videoURL:)]){
        [self.helper.progressView didFetchVideoFileLength:videoLength videoURL:self.wjk_videoURL];
    }
}

- (void)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager loadedTimeProgressDidChange:(CGFloat)loadedTimeProgress {
    if(self.helper.controlView && [self.helper.controlView respondsToSelector:@selector(loadedTimeProgressDidChange:videoURL:)]){
        [self.helper.controlView loadedTimeProgressDidChange:loadedTimeProgress videoURL:self.wjk_videoURL];
    }
    if(self.helper.progressView && [self.helper.progressView respondsToSelector:@selector(loadedTimeProgressDidChange:videoURL:)]){
        [self.helper.progressView loadedTimeProgressDidChange:loadedTimeProgress videoURL:self.wjk_videoURL];
    }
}

- (void)videoPlayerManagerDownloadProgressDidChange:(WJKVideoPlayerManager *)videoPlayerManager
                                          cacheType:(WJKVideoPlayerCacheType)cacheType
                                     fragmentRanges:(NSArray<NSValue *> *_Nullable)fragmentRanges
                                       expectedSize:(NSUInteger)expectedSize
                                              error:(NSError *_Nullable)error {
    if(error){
        if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(playVideoFailWithError:videoURL:)]) {
            [self.wjk_videoPlayerDelegate playVideoFailWithError:WJKErrorWithDescription(@"Try to play video with a invalid url")
                                                       videoURL:videoPlayerManager.managerModel.videoURL];
        }
        return;
    }
    switch(cacheType){
        case WJKVideoPlayerCacheTypeLocation:
            NSParameterAssert(fragmentRanges);
            NSRange range = [fragmentRanges.firstObject rangeValue];
            NSParameterAssert(range.length == expectedSize);
            break;

        default:
            break;
    }
    if(self.helper.controlView && [self.helper.controlView respondsToSelector:@selector(cacheRangeDidChange:videoURL:)]){
        [self.helper.controlView cacheRangeDidChange:fragmentRanges videoURL:self.wjk_videoURL];
    }
    if(self.helper.progressView && [self.helper.progressView respondsToSelector:@selector(cacheRangeDidChange:videoURL:)]){
        [self.helper.progressView cacheRangeDidChange:fragmentRanges videoURL:self.wjk_videoURL];
    }
}

- (void)videoPlayerManagerPlayProgressDidChange:(WJKVideoPlayerManager *)videoPlayerManager
                                 elapsedSeconds:(double)elapsedSeconds
                                   totalSeconds:(double)totalSeconds
                                          error:(NSError *_Nullable)error {
    if(error){
        if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(playVideoFailWithError:videoURL:)]) {
            [self.wjk_videoPlayerDelegate playVideoFailWithError:WJKErrorWithDescription(@"Try to play video with a invalid url")
                                                       videoURL:videoPlayerManager.managerModel.videoURL];
        }
        return;
    }
    if(self.helper.controlView && [self.helper.controlView respondsToSelector:@selector(playProgressDidChangeElapsedSeconds:totalSeconds:videoURL:)]){
        [self.helper.controlView playProgressDidChangeElapsedSeconds:elapsedSeconds
                                                        totalSeconds:totalSeconds
                                                            videoURL:self.wjk_videoURL];
    }
    if(self.helper.progressView && [self.helper.progressView respondsToSelector:@selector(playProgressDidChangeElapsedSeconds:totalSeconds:videoURL:)]){
        [self.helper.progressView playProgressDidChangeElapsedSeconds:elapsedSeconds
                                                         totalSeconds:totalSeconds
                                                             videoURL:self.wjk_videoURL];
    }
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldPausePlaybackWhenApplicationWillResignActiveForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldPausePlaybackWhenApplicationWillResignActiveForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldPausePlaybackWhenApplicationWillResignActiveForURL:videoURL];
    }
    return NO;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldPausePlaybackWhenApplicationDidEnterBackgroundForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldPausePlaybackWhenApplicationDidEnterBackgroundForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldPausePlaybackWhenApplicationDidEnterBackgroundForURL:videoURL];
    }
    return NO;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldResumePlaybackWhenApplicationDidBecomeActiveFromBackgroundForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldResumePlaybackWhenApplicationDidBecomeActiveFromBackgroundForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldResumePlaybackWhenApplicationDidBecomeActiveFromBackgroundForURL:videoURL];
    }
    return YES;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldResumePlaybackWhenApplicationDidBecomeActiveFromResignActiveForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldResumePlaybackWhenApplicationDidBecomeActiveFromResignActiveForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldResumePlaybackWhenApplicationDidBecomeActiveFromResignActiveForURL:videoURL];
    }
    return YES;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldTranslateIntoPlayVideoFromResumePlayForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldTranslateIntoPlayVideoFromResumePlayForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldTranslateIntoPlayVideoFromResumePlayForURL:videoURL];
    }
    return YES;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldPausePlaybackWhenReceiveAudioSessionInterruptionNotificationForURL:(NSURL *)videoURL {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldPausePlaybackWhenReceiveAudioSessionInterruptionNotificationForURL:)]) {
        return [self.wjk_videoPlayerDelegate shouldPausePlaybackWhenReceiveAudioSessionInterruptionNotificationForURL:videoURL];
    }
    return YES;
}

- (NSString *)videoPlayerManagerPreferAudioSessionCategory:(WJKVideoPlayerManager *)videoPlayerManager {
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(preferAudioSessionCategory)]) {
        return [self.wjk_videoPlayerDelegate preferAudioSessionCategory];
    }
    return AVAudioSessionCategoryPlayback;
}

- (BOOL)videoPlayerManager:(WJKVideoPlayerManager *)videoPlayerManager
shouldResumePlaybackFromPlaybackRecordForURL:(NSURL *)videoURL
            elapsedSeconds:(NSTimeInterval)elapsedSeconds {
    BOOL shouldResume = NO;
    if (self.wjk_videoPlayerDelegate && [self.wjk_videoPlayerDelegate respondsToSelector:@selector(shouldResumePlaybackFromPlaybackRecordForURL:elapsedSeconds:)]) {
        shouldResume = [self.wjk_videoPlayerDelegate shouldResumePlaybackFromPlaybackRecordForURL:videoURL
                                                                   elapsedSeconds:elapsedSeconds];
    }
    return shouldResume;
}

@end
