//
//  WJKBaseTableViewController.h
//  iOSwujike
//
//  Created by Zeaho on 2017/8/3.
//  Copyright © 2017年 xhb_iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WJKBaseTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithStyle:(UITableViewStyle)style;

@property (nonatomic, strong) NSArray<NSArray *> *dataSource;

@property (nonatomic, strong) NSArray *sectionIndexTitles;

// The table view for tableView controller.
@property (nonatomic, strong, readonly) UITableView *tableView;

// The default content-inset for tableView
@property (nonatomic, assign, readonly) UIEdgeInsets contentInset;

@property (nonatomic, assign, readonly) CGFloat topBarHeight;
@property (nonatomic, assign, readonly) CGFloat bottomBarHeight;

#pragma mark protected

- (void)initialize;

#pragma mark public

- (void)reloadData;

@end
