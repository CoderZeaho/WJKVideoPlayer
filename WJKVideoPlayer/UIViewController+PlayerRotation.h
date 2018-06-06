//
//  UIViewController+PlayerRotation.h
//  iOSwujike
//
//  Created by Zeaho on 2018/5/10.
//  Copyright © 2018年 xhb_iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (PlayerRotation)

@end

@interface UITabBarController (PlayerRotation)

@end

@interface UINavigationController (PlayerRotation)<UIGestureRecognizerDelegate>

@end

@interface UIAlertController (PlayerRotation)

@end

@interface UIViewController (CurrentViewController)

+ (UIViewController *)currentViewController;

@end

