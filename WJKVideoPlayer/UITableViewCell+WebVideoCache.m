//
//  UITableViewCell+WebVideoCache.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "UITableViewCell+WebVideoCache.h"
#import <objc/runtime.h>

@implementation UITableViewCell (WebVideoCache)

- (void)setWjk_videoURL:(NSURL *)wjk_videoURL {
    objc_setAssociatedObject(self, @selector(wjk_videoURL), wjk_videoURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)wjk_videoURL {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWjk_videoPlayView:(UIView *)wjk_videoPlayView {
    objc_setAssociatedObject(self, @selector(wjk_videoPlayView), wjk_videoPlayView, OBJC_ASSOCIATION_ASSIGN);
}

- (UIView *)wjk_videoPlayView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWjk_unreachableCellType:(WJKVideoPlayerUnreachableCellType)wjk_unreachableCellType {
    objc_setAssociatedObject(self, @selector(wjk_unreachableCellType), @(wjk_unreachableCellType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WJKVideoPlayerUnreachableCellType)wjk_unreachableCellType {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

@end
