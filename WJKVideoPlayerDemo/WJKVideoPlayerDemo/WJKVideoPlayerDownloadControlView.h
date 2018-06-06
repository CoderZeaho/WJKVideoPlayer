//
//  WJKVideoPlayerDownloadControlView.h
//  iOSwujike
//
//  Created by Zeaho on 2018/5/14.
//  Copyright © 2018年 xhb_iOS. All rights reserved.
//

#import "WJKVideoPlayerControlViews.h"

@protocol WJKVideoPlayerDownloadControlViewDelegate <NSObject>

- (void)downloadControlViewBackButton:(UIButton *)button;

@end

@interface WJKVideoPlayerDownloadControlView : WJKVideoPlayerControlView

@property (nonatomic, weak) id<WJKVideoPlayerDownloadControlViewDelegate> delegate;

@end
