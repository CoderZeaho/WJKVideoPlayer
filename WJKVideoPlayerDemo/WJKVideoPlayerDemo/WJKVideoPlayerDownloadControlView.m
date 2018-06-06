//
//  WJKVideoPlayerDownloadControlView.m
//  iOSwujike
//
//  Created by Zeaho on 2018/5/14.
//  Copyright © 2018年 xhb_iOS. All rights reserved.
//

#import "WJKVideoPlayerDownloadControlView.h"

// category
#import "UIView+WebVideoCache.h"

@interface WJKVideoPlayerDownloadControlView ()

@property (nonatomic, strong) UIButton *backButton;

@end

@implementation WJKVideoPlayerDownloadControlView

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
    
    [[self brightnessView] removeFromSuperview];
    [self addSubview:[self brightnessView]];
}

- (void)_configurateSubviewsDefault {
    
    self.cancleGravitySensing = YES;
    
    [[self backButton] setImage:[UIImage imageNamed:@"video_player_back"] forState:UIControlStateNormal];
    [[self backButton] addTarget:self action:@selector(didClickedBackButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_installConstraints {
    
    // 返回按钮约束
    [[self backButton] makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(32.5);
        make.left.mas_equalTo(self.mas_left).mas_offset(5);
        make.width.height.mas_equalTo(44);
    }];
    
    [[self brightnessView] mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(155);
    }];
}


#pragma mark - action
- (void)didClickedBackButton:(UIButton *)sender {
    if ([[self delegate] respondsToSelector:@selector(downloadControlViewBackButton:)]) {
        [[self delegate] downloadControlViewBackButton:sender];
    }
}

- (void)controlBarLandspaceButton:(UIButton *)button {
    if (self.playerView.wjk_viewInterfaceOrientation  == WJKVideoPlayViewInterfaceOrientationLandscape) {
        [self.playerView wjk_stopPlay];
    }
}

@end
