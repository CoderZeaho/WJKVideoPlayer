//
//  UITableView+WebVideoCache.m
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import "UITableView+WebVideoCache.h"
#import "WJKVideoPlayerCompat.h"
#import "WJKVideoPlayerSupportUtils.h"

@interface UITableView()

@property (nonatomic) WJKVideoPlayerTableViewHelper *helper;

@end

static const NSString *kWJKVideoPlayerScrollViewHelperKey = @"com.wjkvideoplayer.scrollview.helper.www";
@implementation UITableView (WebVideoCache)

- (void)setWjk_delegate:(id <WJKTableViewPlayVideoDelegate>)wjk_delegate {
    self.helper.delegate = wjk_delegate;
}

- (id <WJKTableViewPlayVideoDelegate>)wjk_delegate {
    return self.helper.delegate;
}

- (UITableViewCell *)wjk_playingVideoCell {
    return [self.helper playingVideoCell];
}

- (CMTime)wjk_lastTime {
    return [self.helper lastTime];
}

- (void)setWjk_tableViewVisibleFrame:(CGRect)wjk_tableViewVisibleFrame {
    self.helper.tableViewVisibleFrame = wjk_tableViewVisibleFrame;
}

- (CGRect)wjk_tableViewVisibleFrame {
    return self.helper.tableViewVisibleFrame;
}

- (void)setWjk_scrollPlayStrategyType:(WJKScrollPlayStrategyType)wjk_scrollPlayStrategyType {
    self.helper.scrollPlayStrategyType = wjk_scrollPlayStrategyType;
}

- (WJKScrollPlayStrategyType)wjk_scrollPlayStrategyType {
    return self.helper.scrollPlayStrategyType;
}

- (void)setWjk_unreachableCellDictionary:(NSDictionary<NSString *, NSString *> *)wjk_unreachableCellDictionary {
    self.helper.unreachableCellDictionary = wjk_unreachableCellDictionary;
}

- (NSDictionary<NSString *, NSString *> *)wjk_unreachableCellDictionary {
    return self.helper.unreachableCellDictionary;
}

- (void)setWjk_playVideoInVisibleCellsBlock:(WJKPlayVideoInVisibleCellsBlock)wjk_playVideoInVisibleCellsBlock {
    self.helper.playVideoInVisibleCellsBlock = wjk_playVideoInVisibleCellsBlock;
}

- (WJKPlayVideoInVisibleCellsBlock)wjk_playVideoInVisibleCellsBlock {
    return self.helper.playVideoInVisibleCellsBlock;
}

- (void)setWjk_findBestCellInVisibleCellsBlock:(WJKPlayVideoInVisibleCellsBlock)wjk_findBestCellInVisibleCellsBlock {
    self.helper.findBestCellInVisibleCellsBlock = wjk_findBestCellInVisibleCellsBlock;
}

- (WJKPlayVideoInVisibleCellsBlock)wjk_findBestCellInVisibleCellsBlock {
    return self.helper.findBestCellInVisibleCellsBlock;
}

- (void)wjk_playVideoInVisibleCellsIfNeed {
    [self.helper playVideoInVisibleCellsIfNeed];
}

- (void)wjk_stopPlayIfNeed {
    [self.helper stopPlayIfNeed];
}

- (void)wjk_handleCellUnreachableTypeInVisibleCellsAfterReloadData {
    [self.helper handleCellUnreachableTypeInVisibleCellsAfterReloadData];
}

- (void)wjk_handleCellUnreachableTypeForCell:(UITableViewCell *)cell
                                atIndexPath:(NSIndexPath *)indexPath {
    [self.helper handleCellUnreachableTypeForCell:cell
                                      atIndexPath:indexPath];
}

- (void)wjk_scrollViewDidEndDraggingWillDecelerate:(BOOL)decelerate {
    [self.helper scrollViewDidEndDraggingWillDecelerate:decelerate];
}

- (void)wjk_scrollViewDidEndDecelerating {
    [self.helper scrollViewDidEndDecelerating];
}

- (void)wjk_scrollViewDidScroll {
    [self.helper scrollViewDidScroll];
}

- (BOOL)wjk_viewIsVisibleInVisibleFrameAtScrollViewDidScroll:(UIView *)view {
    return [self.helper viewIsVisibleInVisibleFrameAtScrollViewDidScroll:view];
}

- (void)wjk_updatePlayingVideoCell:(UITableViewCell *)cell {
    [self.helper updatePlayingVideoCell:cell];
}

#pragma mark - Private

- (WJKVideoPlayerTableViewHelper *)helper {
    WJKVideoPlayerTableViewHelper *_helper = objc_getAssociatedObject(self, &kWJKVideoPlayerScrollViewHelperKey);
    if(!_helper){
        _helper = [[WJKVideoPlayerTableViewHelper alloc] initWithTableView:self];
        objc_setAssociatedObject(self, &kWJKVideoPlayerScrollViewHelperKey, _helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return _helper;
}

@end
