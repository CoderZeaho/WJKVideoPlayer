//
//  UITableView+WebVideoCache.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+WebVideoCache.h"

typedef NS_ENUM(NSUInteger, WJKScrollPlayStrategyType) {
    /**
     * `WJKScrollFindBestCell` strategy mean find which cell need play video by the space from the center of cell
     *  to the center of `wjk_tableViewVisibleFrame`, h1 on bottom picture.
     */
    WJKScrollPlayStrategyTypeBestCell = 0,

    /**
     * `WJKScrollFindBestCell` strategy mean find which cell need play video by the space from the center of videoView
     *  to the center of `wjk_tableViewVisibleFrame`, h2 on bottom picture.
     */
    WJKScrollPlayStrategyTypeBestVideoView,
};

typedef UITableViewCell *_Nullable (^WJKPlayVideoInVisibleCellsBlock)(NSArray<UITableViewCell *> *_Nullable visibleCells);

NS_ASSUME_NONNULL_BEGIN

@protocol WJKTableViewPlayVideoDelegate<NSObject>

@optional

/**
 * This method will be call when call `wjk_playVideoInVisibleCellsIfNeed` and the find the best cell to play video when
 * tableView scroll end.
 *
 * @param tableView The tableView.
 * @param cell      The cell ready to play video, you can call `[cell.wjk_videoPlayView wjk_playVideoMuteWithURL:cell.wjk_videoURL progressView:nil]`
 *                  or other method given to play video.
 */
- (void)tableView:(UITableView *)tableView willPlayVideoOnCell:(UITableViewCell *)cell;

@end

@interface UITableView (WebVideoCache)

@property (nonatomic) id<WJKTableViewPlayVideoDelegate> wjk_delegate;

/**
 * The cell is playing video.
 */
@property(nonatomic, readonly, nullable) UITableViewCell *wjk_playingVideoCell;

/**
 * The visible frame of tableView. `visible` mean when the tableView frame is {0, 0, screenWidth, screenHeight},
 * but tableView is wrapped by `UITabBarController` and `UINavigationController`, `UINavigationBar` and `UITabBar`
 * is visible, so the visible frame of tableView is {0, navigationBarHeight, screenWidth, screenHeight - navigationBarHeight - tabBarHeight}.
 * {0, navigationBarHeight, screenWidth, screenHeight - navigationBarHeight} if `UITabBar` is hidden.
 *
 * @warning This value must be not empty.
 */
@property (nonatomic) CGRect wjk_tableViewVisibleFrame;

/**
 * The play cell strategy when tableView stop scroll, `WJKScrollFindStrategyBestCell` by default.
 *
 * @see `WJKScrollFindStrategy`.
 *
 *
 *    ****************************** center of `wjk_tableViewVisibleFrame`
 *              |h2   |h1
 *    ----------|-----|-------------
 *    |         |     |            |
 *    |  cell   |     |            |
 *    |         |     |            |
 *    | --------|-----|---         |
 *    | |videoView    |  |         |
 *    | |       |     * <- cell center
 *    | |       * <- videoView center
 *    | |                |         |
 *    | |                |         |
 *    | ------------------         |
 *    |                            |
 *    ------------------------------
 */
@property (nonatomic) WJKScrollPlayStrategyType wjk_scrollPlayStrategyType;

/**
 * Because we play video on cell that stopped on screen center when the tableView was stopped scrolling,
 * so some cell may can not stop in screen center, this type cell always is on top or bottom in tableView, we call this type cell `unreachableCell`.
 * so we need handle this especially. but first we need do is to check the situation of this type cell appear.
 *
 * Here is the result of my measure on iPhone 6s(CH).
 * The number of visible cells in screen:              4  3  2
 * The number of cells cannot stop in screen center:   1  1  0
 *
 * The default dictionary content is: @{
 *                                      @"4" : @"1",
 *                                      @"3" : @"1",
 *                                      @"2" : @"0"
 *                                     };
 *
 * @warning you need to know that the mean of result, For example, when we got 4 cells in screen,
 * this time we find 1 cell that can not stop in screen center on top, and we got the same cell that cannot stop in screen center on bottom at the same time.
 * The cell of cannot stop in screen center only appear when the count of visible cells is greater than 3.
 *
 * @note You can custom this dictionary.
 */
@property (nonatomic) NSDictionary<NSString *, NSString *> *wjk_unreachableCellDictionary;

/**
 * Use this block to custom choosing cell process when call `wjk_playVideoInVisibleCellsIfNeed`.
 */
@property(nonatomic) WJKPlayVideoInVisibleCellsBlock wjk_playVideoInVisibleCellsBlock;

/**
 * Use this block to custom finding the best cell process when scrollView did stop scroll.
 */
@property(nonatomic) WJKPlayVideoInVisibleCellsBlock wjk_findBestCellInVisibleCellsBlock;

/**
 * This method be used to find the first cell need to play video in visible cells.
 * This method should be call after tableView is finished `-reloadData`.
 * Suggest call this method in `-viewDidAppear:` method.
 */
- (void)wjk_playVideoInVisibleCellsIfNeed;

/**
 * Call this method to stop video play.
 */
- (void)wjk_stopPlayIfNeed;

/**
 * This method must be call after called `reloadData` for tableView.
 */
- (void)wjk_handleCellUnreachableTypeInVisibleCellsAfterReloadData;

/**
 * This method must be called in `-tableView:cellForRowAtIndexPath:`, and pass cell and indexPath in.
 *
 * @param cell      A `UITableViewCell`.
 * @param indexPath The indexPath of cell.
 *
 * @warning This method must be call in given method.
 */
- (void)wjk_handleCellUnreachableTypeForCell:(UITableViewCell *)cell
                                atIndexPath:(NSIndexPath *)indexPath;

/**
 * This method must be call in `-scrollViewDidScroll:` method.
 *
 * * @warning This method must be call in given method.
 */
- (void)wjk_scrollViewDidScroll;

/**
 * This method must be call in `scrollViewDidEndDragging:willDecelerate:`.
 *
 * @param decelerate The tableView will decelerate or not.
 *
 * @warning This method must be call in given method.
 */
- (void)wjk_scrollViewDidEndDraggingWillDecelerate:(BOOL)decelerate;

/**
 * This method must be call in `scrollViewDidEndDecelerating:`.
 *
 * @warning This method must be call in given method.
 */
- (void)wjk_scrollViewDidEndDecelerating;

/**
 * You can use this method to judge a view is visible or not when scrollView did scroll.
 *
 * @param view The target view, the view must be a subview on this tableView.
 *
 * @return The result.
 */
- (BOOL)wjk_viewIsVisibleInVisibleFrameAtScrollViewDidScroll:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
