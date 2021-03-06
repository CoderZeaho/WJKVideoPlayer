//
//  UITableViewCell+WebVideoCache.h
//  WJKPlayerDemo
//
//  Created by Zeaho on 2018/5/1.
//  Copyright © 2018年 Zeaho. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger , WJKVideoPlayerUnreachableCellType) {
    WJKVideoPlayerUnreachableCellTypeNone = 0,
    WJKVideoPlayerUnreachableCellTypeTop = 1,
    WJKVideoPlayerUnreachableCellTypeDown = 2
};

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewCell (WebVideoCache)

/**
 * The video path url.
 *
 * @note The url may a web url or local file url.
 */
@property (nonatomic, nullable) NSURL *wjk_videoURL;

/**
 * The view to display video layer.
 */
@property (nonatomic, nullable) UIView *wjk_videoPlayView;

/**
 * The style of cell cannot stop in screen center.
 */
@property(nonatomic) WJKVideoPlayerUnreachableCellType wjk_unreachableCellType;

/**
  * Returns a Boolean value that indicates whether a given cell is equal to
  * the receiver using `jp_videoURL` comparison.
  *
  * @param cell The cell with which to compare the receiver.
  *
  * @return YES if cell is equivalent to the receiver (if they have the same `jp_videoURL` comparison), otherwise NO.
  */
- (BOOL)wjk_isEqualToCell:(UITableViewCell *)cell;

@end

NS_ASSUME_NONNULL_END
