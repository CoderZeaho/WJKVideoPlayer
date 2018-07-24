//
//  WJKVideoPlayerBrightnessView.m
//  iOSwujike
//
//  Created by Zeaho on 2018/5/6.
//  Copyright © 2018年 xhb_iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WJKVideoPlayerBrightnessView : UIView

@property (nonatomic, assign) BOOL isLockScreen;
@property (nonatomic, assign) BOOL isAllowLandscape;
@property (nonatomic, assign) BOOL isStatusBarHidden;
@property (nonatomic, assign) BOOL isLandscape;

+ (instancetype)sharedBrightnessView;

@end
