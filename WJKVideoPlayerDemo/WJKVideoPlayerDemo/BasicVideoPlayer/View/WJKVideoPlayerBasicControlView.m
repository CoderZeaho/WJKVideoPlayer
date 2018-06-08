//
//  WJKVideoPlayerBasicControlView.m
//  WJKVideoPlayerDemo
//
//  Created by Zeaho on 2018/5/14.
//  Copyright © 2018年 xhb_iOS. All rights reserved.
//

#import "WJKVideoPlayerBasicControlView.h"

@interface WJKVideoPlayerBasicControlView () <WJKVideoPlayerProtocol>

@property (nonatomic, strong) UIButton *backButton;

@end

@implementation WJKVideoPlayerBasicControlView

- (instancetype)initWithControlBar:(UIView <WJKVideoPlayerProtocol> *_Nullable)controlBar
                         blurImage:(UIImage *_Nullable)blurImage
           needAutoHideControlView:(BOOL)needAutoHideControlView {
    self = [super initWithControlBar:controlBar
                           blurImage:blurImage
             needAutoHideControlView:YES];
    
    if(self){
        [self _createSubviews];
        [self _configurateSubviewsDefault];
        [self _installConstraints];
    }
    return self;
}

- (void)_createSubviews {
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:[self backButton]];
}

- (void)_configurateSubviewsDefault {
    
    [[self backButton] setImage:[UIImage imageNamed:@"WJKVideoPlayer.bundle/wjk_videoplayer_back"] forState:UIControlStateNormal];
    [[self backButton] addTarget:self action:@selector(didClickedBackButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_installConstraints {
    
    [[self backButton] makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(32.5);
        make.left.mas_equalTo(self.mas_left).mas_offset(5);
        make.width.height.mas_equalTo(44);
    }];
}

#pragma mark - WJKVideoPlayerControlView
- (void)playProgressDidChangeElapsedSeconds:(NSTimeInterval)elapsedSeconds totalSeconds:(NSTimeInterval)totalSeconds {
    [super playProgressDidChangeElapsedSeconds:elapsedSeconds totalSeconds:totalSeconds];
}

- (void)videoPlayerStatusDidChange:(WJKVideoPlayerStatus)playerStatus {
    [super videoPlayerStatusDidChange:playerStatus];
}

- (void)hideControlView {
    [super hideControlView];
}

- (void)showControlView {
    [super showControlView];
}

- (void)controlBarLandspaceButton:(UIButton *)button {
    if (self.playerView.wjk_viewInterfaceOrientation == WJKVideoPlayViewInterfaceOrientationPortrait) {
        
        [[self brightnessView] removeFromSuperview];
        [self addSubview:[self brightnessView]];
        [[self brightnessView] mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self);
            make.width.height.mas_equalTo(155);
        }];
        
    } else if (self.playerView.wjk_viewInterfaceOrientation  == WJKVideoPlayViewInterfaceOrientationLandscape) {
        
        // 手动全屏(非重力感应)后退出全屏状态需要重新添加亮度调节视图,防止位置出错
        [[self brightnessView] removeFromSuperview];
        [[UIApplication sharedApplication].keyWindow addSubview:[self brightnessView]];
        [[self brightnessView] mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(155);
            make.leading.mas_equalTo((SCREENHEIGHT-155)/2);
            make.top.mas_equalTo((SCREENWIDTH-155)/2);
        }];
    } else {}
}

- (void)deviceInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown: {
        }
            break;
        case UIInterfaceOrientationPortrait: {
        
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
        case UIInterfaceOrientationLandscapeRight: {
    
        }
            break;
        default:
            break;
        }
    }
}


#pragma mark - action
- (void)didClickedBackButton:(UIButton *)sender {
    if ([[self delegate] respondsToSelector:@selector(videoPlayerControlView:clickBackButton:completion:)]) {
        [[self delegate] videoPlayerControlView:self clickBackButton:sender completion:^(BOOL isFullScreen) {
            if (!isFullScreen) {
                // 手动全屏(非重力感应)后退出全屏状态需要重新添加亮度调节视图,防止位置出错
                [[self brightnessView] removeFromSuperview];
                [[UIApplication sharedApplication].keyWindow addSubview:[self brightnessView]];
                [[self brightnessView] mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.width.height.mas_equalTo(155);
                    make.leading.mas_equalTo((SCREENWIDTH-155)/2);
                    make.top.mas_equalTo((SCREENHEIGHT-155)/2);
                }];
            }
        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if (
        [[touch view] isDescendantOfView:[self controlBar]]) {
        return NO;
    }
    return YES;
}

@end
