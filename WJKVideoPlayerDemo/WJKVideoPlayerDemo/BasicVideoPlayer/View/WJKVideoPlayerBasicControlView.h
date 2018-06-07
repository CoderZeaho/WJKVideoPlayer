//
//  WJKVideoPlayerBasicControlView.h
//  WJKVideoPlayerDemo
//
//  Created by Zeaho on 2018/5/14.
//  Copyright © 2018年 xhb_iOS. All rights reserved.
//

#import "WJKVideoPlayerControlViews.h"

#import "UIView+WebVideoCache.h"

@class WJKVideoPlayerBasicControlView;

@protocol WJKVideoPlayerBasicControlViewDelegate <NSObject>

- (void)videoPlayerControlView:(WJKVideoPlayerBasicControlView *)controlView clickBackButton:(UIButton *)button completion:(void (^)(BOOL isFullScreen))completion;

@end

@interface WJKVideoPlayerBasicControlView : WJKVideoPlayerControlView

@property (nonatomic, weak) id<WJKVideoPlayerBasicControlViewDelegate> delegate;

@end
